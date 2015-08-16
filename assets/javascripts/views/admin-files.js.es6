// 2015-07-28
// Нельзя наследоваться здесь от Ember.Component вместо Ember.View,
// потому что иначе из шаблона не будут доступны переменные.
// Ember.JS не прощает помену :-)
export default Ember.View.extend({
	classNames: ['df-files']
	,_init: function() {
		this.set('test', 'admin-files VIEW');
	}.on('init')
});
