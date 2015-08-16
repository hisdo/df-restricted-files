export default {
	resource: 'admin', map() {
		this.resource('adminFiles', {path: '/files'}, function() {
			Discourse.reopen({
				LOG_TRANSITIONS: true
				,LOG_TRANSITIONS_INTERNAL: true
				,LOG_VIEW_LOOKUPS: true
			});
			this.route('downloads');
			this.route('download', {path: '/download/:id'});
		});
	}
};