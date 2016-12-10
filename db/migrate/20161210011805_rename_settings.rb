# 2016-12-10
# vagrant ssh -c "rails generate migration RenameSettings"
# Отладка: vagrant ssh -c "rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- bin/rake db:migrate:redo VERSION=20161210011805"
class RenameSettings < ActiveRecord::Migration
	def change
		# 2016-12-10
		# http://stackoverflow.com/a/19748768
		execute "update site_settings set name = replace(name, '«Restrict_', '«Restricted_')"
	end
end
