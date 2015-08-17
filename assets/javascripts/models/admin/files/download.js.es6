/**
 * 2015-07-28
 * Чтобы этот класс автоматически использовался для загружаемых с сервера моделей,
 * его файловый путь должен оканчиваться на ту строку, которую мы указали в route:
	export default Discourse.Route.extend({
		model() {return this.store.findAll('shop/product');}
	});
 * https://github.com/discourse/discourse/blob/v1.4.0.beta6/app/assets/javascripts/discourse/models/store.js.es6#L127
 * content = result[typeName].map(obj => this._hydrate(type, obj, result)),
 *
 * 2015-07-29
 * Обратите внимание, что наследоваться надо именно от RestModel, а не от Discourse.Model.
 * Если унаследоваться от Discourse.Model, то сначала оно вроде как работает,
 * но при повторной загрузке страницы Discourse уже работает с кэшем
 * и пытается вызвать у объекта метод munge,
 * который отсутствует у Discourse.Model и присутствует у RestModel:
	const klass = this.container.lookupFactory('model:' + type) || RestModel;
	existing.setProperties(klass.munge(obj));
 * @link https://github.com/discourse/discourse/blob/v1.4.0.beta6/app/assets/javascripts/discourse/models/store.js.es6#L215-216
 */
import RestModel from 'discourse/models/rest';
export default RestModel.extend({
	timeFormatted: function() {
		debugger;
		const date = new Date(this.get('time'));
		return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
	}.property('time')
});