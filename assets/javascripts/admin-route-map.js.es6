export default function() {
	this.route('admin', {resetNamespace: true}, function() {
		/**
		 * 2016-12-10
		 * Fix `this.resource` deprecation: https://github.com/discourse/discourse-tagging/commit/84a99df
		 */
		this.route('adminFiles', {path: '/files', resetNamespace: true}, function() {
			Discourse.reopen({
				LOG_TRANSITIONS: true
				,LOG_TRANSITIONS_INTERNAL: true
				,LOG_VIEW_LOOKUPS: true
			});
			this.route('downloads');
			this.route('download', {path: '/download/:id'});
		});
	});
};