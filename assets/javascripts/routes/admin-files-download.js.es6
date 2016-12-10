import Download from 'discourse/plugins/df-restricted-files/models/admin/files/download';
export default Discourse.Route.extend({
	/** @link http://guides.emberjs.com/v1.11.0/models/finding-records/ */
	model(params) {
		debugger;
		return this.store.find('admin/files/download', params.id);
	}
});