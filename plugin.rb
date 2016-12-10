# name: df-restricted-files
# about: The plugin allows to restrict access to attached files so only users of permitted groups can download files from your forum.
# version: 2.0.0
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/33
register_asset 'stylesheets/main.scss'
pluginAppPath = "#{Rails.root}/plugins/df-restricted-files/app/"
Discourse::Application.config.autoload_paths +=
	Dir["#{pluginAppPath}models", "#{pluginAppPath}controllers"]
module ::Df
	module RestrictedFiles
		def self.userGroups
			Group.order(:name).pluck(:name)
		end
	end
end
after_initialize do
	module ::Admin::Df::Files
		class Engine < ::Rails::Engine
			engine_name 'admin_df_files'
			isolate_namespace ::Admin::Df::Files
		end
	end
	require_dependency 'admin_constraint'
	require_dependency 'staff_constraint'
	::Admin::Df::Files::Engine.routes.draw do
		get '/' => 'downloads#index', constraints: AdminConstraint.new
		get '/downloads' => 'downloads#index', constraints: AdminConstraint.new
	end
	Discourse::Application.routes.append do
		namespace :admin, constraints: StaffConstraint.new do
			mount ::Admin::Df::Files::Engine, at: '/files'
		end
	end
	module ::Df
		module RestrictedFiles
			class Engine < ::Rails::Engine
				engine_name 'df_restricted_files'
				isolate_namespace ::Df::RestrictedFiles
			end
		end
	end
	Discourse::Application.routes.prepend do
		mount ::Df::RestrictedFiles::Engine, at: 'file'
	end
	::Df::RestrictedFiles::Engine.routes.draw do
		get '/:id' => 'index#index'
		get '/count/:id' => 'index#count'
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
						pluginEnabled = SiteSetting.send '«Restricted_Files»_Enabled'
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