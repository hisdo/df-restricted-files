import ClickTrack from 'discourse/lib/click-track';
export default {name: 'df-restrict-files', initialize() {
	if (Discourse.SiteSettings['«Restrict_Files»_Enabled']) {
		/** @type {Function} */
		const original = ClickTrack.trackClick;
		ClickTrack.trackClick = function(e) {
			/** @type {jQuery} HTMLAnchorElement */
			var $a = $(e.currentTarget);
			/** @type {String} */
			var href = $a.attr('href') || $a.data('href');
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
				$.ajax(href, {
					cache: false
					,complete: function(ajax, textStatus) {
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
					/**
					 * 2015-08-17
					 * К сожалению, Discourse в Vagrant почему-то теряет стандартный заголовок HTTP
					 * X-Requested-With, поэтому нам приходится вручную давать нашему серверу понять,
					 * что этот запрос — асинхронный, и не надо в ответ отдавать файл
					 * и учитывать файл как уже скачанный.
					 */
					,data: {
						ajax: 1
					}
					,global: false
				});
			}
			// Important!
			return false;
		};
	}
}};
