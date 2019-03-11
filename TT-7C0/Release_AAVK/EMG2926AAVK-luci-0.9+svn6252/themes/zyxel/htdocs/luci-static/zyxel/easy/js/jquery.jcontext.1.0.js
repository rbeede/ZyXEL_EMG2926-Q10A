/* Copyright (c) 2010 Kean Loong Tan http://www.gimiti.com/kltan
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 * Name: jContext
 * Version: 1.0 (April 28, 2010)
 * Requires: jQuery 1.2+
 */
(function($) {
	$.fn.showMenu = function(options) {
		var opts = $.extend({}, $.fn.showMenu.defaults, options);
		$(this).bind("contextmenu",function(e){
			var mypos = $("#position").offset();											
			var leftpos = e.pageX-mypos.left;
			var toppos =  e.pageY-mypos.top
			$(opts.query).show().css({
				top:toppos+"px",
				left:leftpos+"px",
				position:"absolute",
				opacity: opts.opacity,
				zIndex: opts.zindex
			});
			return false;
		});
		$(document).bind("click",function(e){
			$(opts.query).hide();
		});
	};
	
	$.fn.showMenu.defaults = {
		zindex: 2000,
		query: document,
		opacity: 1.0
	};
})(jQuery);