# name: restrict-files
# about: The plugin allows to restrict access to attached files so only users of permitted groups can download files from your forum.
# version: 1.0.0
# authors: Dmitry Fedyuk
# url: http://discourse.pro/t/33
Discourse::Application.config.autoload_paths += Dir["#{Rails.root}/plugins/restrict-files/app/models"]
after_initialize do
	module ::RestrictFiles
		class Engine < ::Rails::Engine
			engine_name 'restrict_files'
			isolate_namespace RestrictFiles
		end
		require_dependency 'application_controller'
		class IndexController < ::ApplicationController
			layout false
			skip_before_filter :preload_json, :check_xhr
			def index
				viewBase = "#{Rails.root}/plugins/restrict-files/app/views/"
				upload = Upload.find(params[:id])
				if upload.nil?
					render :file => "#{viewBase}404.html.erb", :status => 404
				else
					accessListType = SiteSetting.send '«Restrict_Files»_Access_List_Type'
					isWhiteList = 'blacklist' != accessListType
					accessList = SiteSetting.send '«Restrict_Files»_Access_List'
					accessList = accessList.split '|'
					allowed = false;
					if current_user.nil?
						allowedInCore = !SiteSetting.prevent_anons_from_downloading_files
						allowed = allowedInCore or accessList.include?('everyone')
					else
						if upload.user_id == current_user.id
							allowed = true
						else
							userGroupNames = current_user.groups.pluck(:name)
							intersection = accessList & userGroupNames
							allowed = !(intersection.empty?)
						end
					end
					if not allowed
						render :file => "#{viewBase}401.html.erb", :status => 401
					else
						send_file Discourse.store.path_for(upload), filename: upload.original_filename
					end
				end
			end
		end
	end
	Discourse::Application.routes.prepend do
		mount ::RestrictFiles::Engine, at: 'file'
	end
	RestrictFiles::Engine.routes.draw do
		get '/:id' => 'index#index'
	end
	require 'file_store/local_store'
	FileStore::LocalStore.class_eval do
		alias_method :core__path_for, :path_for
		def path_for(upload)
			if upload and upload.url and upload.url.start_with?('/file/')
				"#{Rails.root}/public#{Discourse.store.get_path_for_upload(upload)}"
			else
				core__path_for upload
			end
		end
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
						pluginEnabled = SiteSetting.send '«Restrict_Files»_Enabled'
						if FileHelper.is_image?(filename) or not pluginEnabled
							upload.url = url
						else
							upload.url = "/file/#{upload.id}"
						end
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