# 2016-12-10
# vagrant ssh -c "rails generate migration RenameTable"
# rake db:migrate:redo VERSION=20161210010733
class RenameTable < ActiveRecord::Migration
	def change
		# 2016-12-10
		# http://stackoverflow.com/a/471425
		rename_table :df_restrict_files_downloads, :df_restricted_files_downloads
	end
end
