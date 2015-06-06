# name: restricted-attachments
# about: The plugin allows to restrict access to attachments to concrete user groups.
# version: 1.0.0
# authors: Dmitry Fedyuk
# url: http://discourse.pro/t/33
after_initialize do
	module ::RestrictedAttachments
		class Engine < ::Rails::Engine
			engine_name 'restricted_attachments'
			isolate_namespace RestrictedAttachments
		end
	end
	require_dependency 'application_controller'
	class RestrictedAttachments::AttachmentController < ::ApplicationController
		requires_plugin 'restricted-attachments'
		skip_before_filter :check_xhr, only: [:tag_feed, :show]
		before_filter :ensure_logged_in, only: [:notifications, :update_notifications, :update]
		def index
			render json: {test: 'ok'}
		end
	end
	RestrictedAttachments::Engine.routes.draw do
		get '/' => 'attachment#index'
	end
	Discourse::Application.routes.append do
		mount ::RestrictedAttachments::Engine, at: "/attachment"
	end
	UploadsController.class_eval do
		def show
			return render_404
		end
	end
end