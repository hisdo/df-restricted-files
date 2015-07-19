# name: df-restrict-files
# about: The plugin allows to restrict access to attached files so only users of permitted groups can download files from your forum.
# version: 1.2.1
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/33
Discourse::Application.config.autoload_paths += Dir["#{Rails.root}/plugins/df-restrict-files/app/models"]
module ::RestrictFiles
	def self.userGroups
		Group.order(:name).pluck(:name)
	end
end
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
				viewBase = "#{Rails.root}/plugins/df-restrict-files/app/views/"
				upload = Upload.find(params[:id])
				# http://stackoverflow.com/a/6937030/254475
				status = 403;
				if upload.nil?
					status = 404
				else
					pluginEnabled = SiteSetting.send '«Restrict_Files»_Enabled'
					if not pluginEnabled
						if current_user.nil? and !SiteSetting.prevent_anons_from_downloading_files
							status = 401
						else
							status = 200
						end
					else
						accessListType = SiteSetting.send '«Restrict_Files»_Access_List_Type'
						isWhiteList = 'blacklist' != accessListType
						accessList = SiteSetting.send '«Restrict_Files»_Access_List'
						accessList = accessList.split '|'
						allowed = false;
						if current_user.nil?
							if accessList.include? 'everyone'
								status = 200
							else
								status = 401
							end
						else
							if upload.user_id == current_user.id
								status = 200
							else
								userGroupNames = current_user.groups.pluck(:name)
								intersection = accessList & userGroupNames
								if intersection.empty?
									status = 403
								else
									status = 200
								end
							end
						end
					end
				end
				if 200 != status
					render :file => "#{viewBase}#{status}.html.erb", :status => status
				else
					send_file Discourse.store.path_for(upload), filename: upload.original_filename
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
	# 2015-07-19
	# Updated to be compatible with Discourse v1.4.0.beta5 and v1.4.0.beta6
	# @link https://github.com/discourse/discourse/commit/b0802abae2f58b7b982808844cdc50aee462fd2b
	Upload.class_eval do
		# list of image types that will be cropped
		CROPPED_IMAGE_TYPES ||= ["avatar", "profile_background", "card_background"]

		# options
		#   - content_type
		#   - origin
		def self.create_for(user_id, file, filename, filesize, options = {})
			DistributedMutex.synchronize("upload_#{user_id}_#{filename}") do
				# do some work on images
				if FileHelper.is_image?(filename)
					if filename =~ /\.svg$/i
						svg = Nokogiri::XML(file).at_css("svg")
						w = svg["width"].to_i
						h = svg["height"].to_i
					else
						# fix orientation first
						fix_image_orientation(file.path)
						# retrieve image info
						image_info = FastImage.new(file) rescue nil
						w, h = *(image_info.try(:size) || [0, 0])
					end

					# default size
					width, height = ImageSizer.resize(w, h)

					# make sure we're at the beginning of the file (both FastImage and Nokogiri move the pointer)
					file.rewind

					# crop images depending on their type
					if CROPPED_IMAGE_TYPES.include?(options[:image_type])
						allow_animation = false
						max_pixel_ratio = Discourse::PIXEL_RATIOS.max

						case options[:image_type]
							when "avatar"
								allow_animation = SiteSetting.allow_animated_avatars
								width = height = Discourse.avatar_sizes.max
							when "profile_background"
								max_width = 850 * max_pixel_ratio
								width, height = ImageSizer.resize(w, h, max_width: max_width, max_height: max_width)
							when "card_background"
								max_width = 590 * max_pixel_ratio
								width, height = ImageSizer.resize(w, h, max_width: max_width, max_height: max_width)
						end

						OptimizedImage.resize(file.path, file.path, width, height, allow_animation: allow_animation)
					end

				# optimize image
				ImageOptim.new.optimize_image!(file.path) rescue nil
			end

			# compute the sha of the file
			sha1 = Digest::SHA1.file(file).hexdigest

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
			upload.width             = width
			upload.height            = height
			upload.origin            = options[:origin][0...1000] if options[:origin]

			if FileHelper.is_image?(filename) && (upload.width == 0 || upload.height == 0)
				upload.errors.add(:base, I18n.t("upload.images.size_not_found"))
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
				upload
			end
		end
	end
end