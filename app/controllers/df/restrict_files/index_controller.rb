require_dependency 'application_controller'
module ::Df::RestrictFiles
	class IndexController < ::ApplicationController
		layout false
		skip_before_filter :preload_json, :check_xhr
		def index
			viewBase = "#{Rails.root}/plugins/df-restrict-files/app/views/"
			upload = Upload.find(params[:id])
			# http://stackoverflow.com/a/6937030
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
				# http://stackoverflow.com/a/8220761
				# 2015-08-17
				# К сожалению, Discourse в Vagrant почему-то теряет стандартный заголовок HTTP
				# X-Requested-With, поэтому мы не можем использовать здесь
				# простой метод request.xhr?, а вынуждены проверять асинхронность запроса вручную.
				if params['ajax']
					# 2015-08-16
					# По AJAX всё равно нельзя загрузить файл,
					# поэтому просто возвращаем статус успешности.
					# http://stackoverflow.com/a/3877133
					render json: {ok: true}, layout: true
				else
					download = Download.new
					download.user = current_user
					download.upload = upload
					download.save
					send_file Discourse.store.path_for(upload), filename: upload.original_filename
				end
			end
		end
	end
end

