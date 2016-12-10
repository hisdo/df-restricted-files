require_dependency 'admin/admin_controller'
module ::Admin::Df::Files
	class DownloadsController < ::Admin::AdminController
		def index
			downloads = ::Df::RestrictedFiles::Download.all
			result = []
			downloads.each { |d|
				item = {
					id: d.id,
					time: d.created_at,
					userId: d.user.id,
					userName: d.user.name,
					fileId: d.upload.id,
					fileName: d.upload.original_filename,
					fileUrl: d.upload.url
				}
				if d.topic
					item[:topicId] = d.topic.id
					item[:topicTitle] = d.topic.title
				end
				result.push item
			}
			render json: {'admin/files/downloads' => result}
		end
	end
end

