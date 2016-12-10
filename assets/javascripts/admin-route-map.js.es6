/**
 * 2016-12-10
 * Сделал по аналогии с https://github.com/gdpelican/babble/blob/b2a319/assets/javascripts/discourse/babble-route-map.js.es6
 */
export default {resource: 'admin', map() {
	/**
	 * 2016-12-10
	 * Fix `this.resource` deprecation: https://github.com/discourse/discourse-tagging/commit/84a99df
	 * «resetNamespace: true» здесь обязательно, иначе будет сбой:
	 * «There is no route named adminFiles».
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
}};