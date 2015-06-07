# name: restricted-files
# about: The plugin allows to restrict access to attached files so only users of permitted groups can download files from your forum.
# version: 1.0.0
# authors: Dmitry Fedyuk
# url: http://discourse.pro/t/33
after_initialize do
	module ::RestrictedFiles
		class Engine < ::Rails::Engine
			engine_name 'restricted_files'
			isolate_namespace RestrictedFiles
		end
		require_dependency 'application_controller'
		class IndexController < ::ApplicationController
			layout false
			skip_before_filter :preload_json, :check_xhr
			def index
				if SiteSetting.prevent_anons_from_downloading_files && current_user.nil?
					return render_404
				end
				if upload = Upload.find(params[:id])
					send_file "#{Rails.root}/public#{Discourse.store.get_path_for_upload(upload)}",
						filename: upload.original_filename
				else
					render_404
				end
			end
		end
	end
	Discourse::Application.routes.prepend do
		mount ::RestrictedFiles::Engine, at: 'file'
	end
	RestrictedFiles::Engine.routes.draw do
		get '/:id' => 'index#index'
	end
	Upload.class_eval do
		# options
		#   - content_type
		#   - origin
		def self.create_for(user_id, file, filename, filesize, options = {})
			sha1 = Digest::SHA1.file(file).hexdigest

			DistributedMutex.synchronize("upload_#{sha1}") do
				# do we already have that upload?
				upload = find_by(sha1: sha1)

				# make sure the previous upload has not failed
				if upload && upload.url.blank?
					upload.destroy
					upload = nil
				end

				# return the previous upload if any
				return upload unless upload.nil?

				# create the upload otherwise
				upload = Upload.new
				upload.user_id           = user_id
				upload.original_filename = filename
				upload.filesize          = filesize
				upload.sha1              = sha1
				upload.url               = ""
				upload.origin            = options[:origin][0...1000] if options[:origin]

				if FileHelper.is_image?(filename)
					# deal with width & height for images
					upload = resize_image(filename, file, upload)
					# optimize image
					ImageOptim.new.optimize_image!(file.path) rescue nil
				end

				return upload unless upload.save

				# store the file and update its url
				File.open(file.path) do |f|
					url = Discourse.store.store_upload(f, upload, options[:content_type])
					if url.present?
						# BEGIN PATCH
						upload.url = "/file/#{upload.id}"
						# END PATCH
						upload.save
					else
						upload.errors.add(:url, I18n.t("upload.store_failure", { upload_id: upload.id, user_id: user_id }))
					end
				end

			# return the uploaded file
			upload
			end
		end
	end
end