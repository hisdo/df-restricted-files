# psql --port=15432 -c "TRUNCATE df_restrict_files_downloads"
# rake db:migrate:redo VERSION=20150816142934
class CreateDfRestrictFilesDownloads < ActiveRecord::Migration
	def change
		create_table :df_restrict_files_downloads do |t|
			t.belongs_to :user, index: true
			t.belongs_to :upload, index: true
			t.belongs_to :topic, index: true
			t.belongs_to :post, index: true
			t.timestamps
		end
	end
end