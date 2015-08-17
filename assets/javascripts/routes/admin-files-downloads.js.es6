import Download from 'discourse/plugins/df-restrict-files/models/admin/files/download';
export default Discourse.Route.extend({
	model() {return this.store.findAll('admin/files/download');}
	,afterModel(downloads) {
		/**
		 * 2015-07-28
		 * Здесь мы можем что-нибудь сделать с результатом.
		 * Например: добавить в результат ещё один объект:
			products.pushObject(Product.create({id: 3, name: 'сиськи'}));
		 	return this._super(products)
		 * Обратите внимание, что сделать это мы мы можем и в адаптере,
		 * но там мы работаем с сырыми данными, пришедшими с сервера,
		 * а здесь мы работаем уже с объектами предметной области.
		 */
		//products.pushObject(Product.create({id: 3, name: 'сиськи'}));
		return this._super(downloads);
	}
});
