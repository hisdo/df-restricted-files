module ::Df::RestrictFiles
	class Download < ActiveRecord::Base
		self.table_name = 'df_restrict_files_downloads'
		belongs_to :user
		validates :user_id, presence: true
		belongs_to :upload
		validates :upload_id, presence: true
		# http://requiremind.com/differences-between-has-one-and-belongs-to-in-ruby-on-rails/
		belongs_to :topic
		belongs_to :post
	end
end
