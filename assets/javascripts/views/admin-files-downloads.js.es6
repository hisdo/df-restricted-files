// 2015-07-28
// Нельзя наследоваться здесь от Ember.Component вместо Ember.View,
// потому что иначе из шаблона не будут доступны переменные.
// Ember.JS не прощает помену :-)
export default Ember.View.extend({
	classNames: ['df-files-downloads']
	,_init: function() {
		this.set('test', 'admin-files-downloads VIEW');
	}.on('init')
});

