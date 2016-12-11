/**
 * 2016-12-10
 * Раньше называл этот файл «i.js.es6».
 * Discourse всё равно, как назван этот файл: важно лишь, чтобы он был расположен в папке «initializers».
 * Однако при отладке посредством размещения в коде точек останова и при имени «i.js.es6»
 * Google Chrome при останове открывает неверный одноимённый файл «i.js.es6».
 * Эта проблема присутствовала всегда, и раньше я её решал
 * закрытием неверных вкладок в отладчике Google Chrome и перезагрузкой страницы.
 * Однако сегодня такое решение не сработало, поэтому я переименовал файл.
 */
import ClickTrack from 'discourse/lib/click-track';
export default {name: 'df-restricted-files', initialize(c) {
	if (Discourse.SiteSettings['«Restricted_Files»_Enabled']) {
		/** @type {Function} */
		const original = ClickTrack.trackClick;
		ClickTrack.trackClick = e => {
			/** @type {jQuery} HTMLAnchorElement */
			const $a = $(e.currentTarget);
			/** @type {String} */
			const href = $a.attr('href') || $a.data('href');
			if (
				0 !== href.indexOf('/file/')
				|| 3 === e.which || 2 === e.which || e.shiftKey || e.metaKey || e.ctrlKey
			) {
				original.call(ClickTrack, e);
			}
			else {
				/**
				 * 2016-12-11
				 * Раньше здесь стояло:
				 * e.stopPropagation();
				 * e.preventDefault();
				 *
				 * Оба этих вызова и ранее были избыточны, потому что наша функция возвращает false,
				 * а это эквивалентно вызову stopPropagation и preventDefault:
				 * http://stackoverflow.com/a/4379459
				 *
				 * Более того, отныне вызов здесь preventDefault() ломает наш код из-за кода ядра:
						export function wantsNewWindow(e) {
							return (e.isDefaultPrevented() || e.shiftKey || e.metaKey || e.ctrlKey
								|| (e.button && e.button !== 0));
						}
				 * https://github.com/discourse/discourse/blob/v1.7.0.beta9/app/assets/javascripts/discourse/lib/intercept-click.js.es6#L3-L5
				 * Этот код вызывается из стандартного click-track:
				 * https://github.com/discourse/discourse/blob/v1.7.0.beta9/app/assets/javascripts/discourse/lib/click-track.js.es6#L66-L67
				 */
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
					,complete(ajax) {
						/** @link https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest */
						if (200 !== ajax.status) {
							bootbox.alert(ajax.responseText);
						}
						else {
							// 2015-08-16
							// По AJAX мы всё равно не можем загрузить файл,
							// поэтому вынуждены выполнять запрос повторно.
							/**
							 * 2016-12-11
							 * В ядре есть код:
									export function wantsNewWindow(e) {
										return (e.isDefaultPrevented() || e.shiftKey || e.metaKey || e.ctrlKey
											|| (e.button && e.button !== 0));
									}
							 * https://github.com/discourse/discourse/blob/v1.7.0.beta9/app/assets/javascripts/discourse/lib/intercept-click.js.es6#L3-L5
							 * Этот код вызывается из стандартного click-track:
							 * https://github.com/discourse/discourse/blob/v1.7.0.beta9/app/assets/javascripts/discourse/lib/click-track.js.es6#L66-L67
							 * Наше красивое решение позволяет нам вернуть false из wantsNewWindow()
							 * и, таким образом, передать обработку запроса серверу.
							 *
							 *
							 * /clicks/track?url=%2Ffile%2F112&post_id=40&topic_id=33
							 */
							e.isDefaultPrevented = () => false;
							/**
							 * 2016-12-11
							 * В принципе, вместо этой строчки и строчки выше мы могли бы просто вызвать:
							 * DiscourseURL.redirectTo(href);
							 * Однако вызов родительского ClickTrack позволяет нам задействовать
							 * стандартный счётчик кликов (хотя мы всё равно используем ещё и наш
							 * для отчётности перед администраторами).
							 */
							original.call(ClickTrack, e);
						}
					}
					,contentType: 'text/html'
					,data: {
						// 2015-08-17
						// К сожалению, Discourse в Vagrant почему-то теряет стандартный заголовок HTTP
						// X-Requested-With, поэтому нам приходится вручную давать нашему серверу понять,
						// что этот запрос — асинхронный, и не надо в ответ отдавать файл
						// и учитывать файл как уже скачанный.
						ajax: 1
						// 2015-08-17
						// Для статистики
						,post: postId, topic: topicId
					}
					,global: false
				});
			}
			// 2016-12-11
			// эквивалентно вызову stopPropagation и preventDefault: http://stackoverflow.com/a/4379459
			return false;
		};
	}
}};