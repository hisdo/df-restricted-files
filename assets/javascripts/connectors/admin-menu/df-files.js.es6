import NavItem from 'discourse/components/nav-item';
export default NavItem.extend({
	_init: function() {
		this.set('route', 'adminFiles');
		this.set('label', 'df.files.title');
	}.on('init')
});