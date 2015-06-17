import ClickTrack from 'discourse/lib/click-track';
export default {name: 'df-restrict-files', initialize() {
	/** @type {Function} */
	var original = ClickTrack.trackClick;
	/** @type {Boolean} */
	var pluginEnabled = Discourse.SiteSettings['«Restrict_Files»_Enabled'];
	ClickTrack.trackClick = function(e) {
		/** @type {jQuery} HTMLAnchorElement */
		var $a = $(e.currentTarget);
		/** @type {String} */
		var href = $a.attr('href') || $a.data('href');
		if (
			!pluginEnabled
			|| (0 !== href.indexOf('/file/'))
			|| (3 === e.which)
			|| (2 === e.which)
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
						original.call(ClickTrack, e);
					}
					else {
						bootbox.alert(ajax.responseText);
					}
				}
				,contentType: 'text/html'
				,global: false
			});
		}
		// Important!
		return false;
	};
}};
