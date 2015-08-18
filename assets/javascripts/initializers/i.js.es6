import ClickTrack from 'discourse/lib/click-track';
import NavItem from 'discourse/plugins/df-core/models/nav-item';
export default {name: 'df-restrict-files', initialize(c) {
	if (Discourse.SiteSettings['«Restrict_Files»_Enabled']) {
		/*Discourse.NavItem.reopenClass({
			buildList : function(category, args) {
				var list = this._super(category, args);
				if (!category) {
					list.push(NavItem.create({href: '/files', name: 'files'}));
				}
				return list;
			}
		});*/
		/** @type {Function} */
		const original = ClickTrack.trackClick;
		ClickTrack.trackClick = function(e) {
			/** @type {jQuery} HTMLAnchorElement */
			const $a = $(e.currentTarget);
			/** @type {String} */
			const href = $a.attr('href') || $a.data('href');
			if (
				0 !== href.indexOf('/file/')
				|| 3 === e.which
				|| 2 === e.which
				|| e.shiftKey
				|| e.metaKey
				|| e.ctrlKey
			) {
				original.call(ClickTrack, e);
			}
			else {
				e.stopPropagation();
				e.preventDefault();
				// Remove the href, put it as a data attribute
				if (!$a.data('href')) {
					$a.addClass('no-href');
					$a.data('href', $a.attr('href'));
					$a.attr('href', null);
					// Don't route to this URL
					$a.data('auto-route', true);
				}
				// restore href
				setTimeout(() => {
					$a.removeClass('no-href');
					$a.attr('href', $a.data('href'));
					$a.data('href', null);
				}, 50);
				/** @type {Number} */
				const postId = parseInt($a.closest("article[id^='post_']").attr('data-post-id'));
				/** @type {Number} */
				const topicId = parseInt($a.closest('#topic').attr('data-topic-id'));
				$.ajax(href, {
					cache: false
					,complete(ajax, textStatus) {
						/** @link https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest */
						if (200 === ajax.status) {
							/**
							 * 2015-08-16
							 * По AJAX мы всё равно не можем загрузить файл,
							 * поэтому вынуждены выполнять запрос повторно.
							 */
							original.call(ClickTrack, e);
						}
						else {
							bootbox.alert(ajax.responseText);
						}
					}
					,contentType: 'text/html'
					,data: {
						/**
						 * 2015-08-17
						 * К сожалению, Discourse в Vagrant почему-то теряет стандартный заголовок HTTP
						 * X-Requested-With, поэтому нам приходится вручную давать нашему серверу понять,
						 * что этот запрос — асинхронный, и не надо в ответ отдавать файл
						 * и учитывать файл как уже скачанный.
						 */
						ajax: 1
						// 2015-08-17
						// Для статистики
						,topic: topicId
						,post: postId
					}
					,global: false
				});
			}
			// Important!
			return false;
		};
	}
}};
