export default Discourse.Route.extend({
	beforeModel() {this.replaceWith('adminFiles.downloads');}
});
