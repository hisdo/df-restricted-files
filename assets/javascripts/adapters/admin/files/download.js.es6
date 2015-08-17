import RestAdapter from 'discourse/adapters/rest';
export default RestAdapter.extend({
	findAll(store, type) {return this._super(store, type);}
	/**
	 * 2015-07-29
	 * pathFor родительского класса приводит имя типа (shop/product)
	 * ко множественному числу (shop/products).
	 * Нас это устраивает при запросе списка товаров,
	 * но для страницы товара хотелось бы иметь адрес с типом в единственном числе:
	 * /shop/product/:id
	 */
	,pathFor(store, type, id) {
		return (
			!id
			? this._super(store, type, id)
			: '/' + Ember.String.underscore(type) + '/' + id
		);
	}
});