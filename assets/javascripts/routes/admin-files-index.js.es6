/**
 * 2015-07-29
 * Обратите внимание, что этот файл надо называть с суффиксом -index,
 * потому что иначе метод beforeModel() будет срабатывать не только для запроса /files,
 * но и для всех остальных запросов внутри /files,
 * и мы не сможем тогда отобразить страницу объекта /file/:id,
 * потому что в beforeModel() делаем перенаправление: this.replaceWith('adminFiles.downloads')
 */
export default Discourse.Route.extend({
	beforeModel() {this.replaceWith('adminFiles.downloads');}
});
