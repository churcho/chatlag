// JavaScript Document

$(document).ready(function () {
	"use strict";

	var totalchats, additionalchats_width, chats_per_screen, current_screen, totalscreens, animate_width;
	current_screen = 0;

	function resize() {
		totalchats = $(".additional-chat").length;
		additionalchats_width = $(".additional-chat").width();
		if ($(window).width() > 1200) {
			chats_per_screen = 8;
			animate_width = 1080;
		} else if ($(window).width() > 992) {
			chats_per_screen = 8;
			animate_width = 880;
		} else {
			chats_per_screen = 2;
			animate_width = newFontSize * 100;
		}
		checkArrows();
		totalscreens = Math.round(totalchats / chats_per_screen);
		$(".more-chats-scroll").css({
			"width": totalchats * additionalchats_width
		});
		$(".more-chats-scroll").css({
			"margin-right": -current_screen * animate_width
		});
	}

	window.addEventListener('resize', function () {
		resize();
	});

	resize();

	function checkArrows() {
		if (current_screen == 0) {
			$(".goright").addClass("disabled");
		} else if (current_screen >= totalscreens - 1) {
			$(".goleft").addClass("disabled");
		}
	}

	function right() {
		if (current_screen > 0) {
			current_screen--;
			$(".more-chats-scroll").animate({
				"margin-right": -current_screen * animate_width
			});
			$(".goleft").removeClass("disabled");
			checkArrows();
		}
	}

	function left() {
		if (current_screen < totalscreens - 1) {
			current_screen++;
			$(".more-chats-scroll").animate({
				"margin-right": -current_screen * animate_width
			});
			$(".goright").removeClass("disabled");
			checkArrows();
		}
	}
	$(".goright").click(function () {
		right();
	});
	$(".goleft").click(function () {
		left();
	});

	document.getElementById("col-swipe").addEventListener('swiped-left', function (e) {
		right();
	});

	document.getElementById("col-swipe").addEventListener('swiped-right', function (e) {
		left();
	});
	var stats = [41, 12, 521, 1205];
	var steps = 20;
	var current_step = 1;

	var increaseOnce = true;

	$(window).scroll(function () {
		scrollStat();
	})

	function scrollStat() {
		if (isInViewport($("#row-stats")) && increaseOnce) {
			increaseOnce = false;
			increaseStats();
		}
	}
	scrollStat();

	function increaseStats() {
		for (var k = 1; k <= 4; k++) {
			$(".stats" + k).html(Math.round(stats[k - 1] / steps * current_step));
		}
		current_step++;
		if (current_step < steps + 1) {
			setTimeout(increaseStats, 50);
		}
	}

	function isInViewport(element) {
		var elementTop = element.offset().top;
		var elementBottom = elementTop + element.outerHeight();
		var viewportTop = $(window).scrollTop();
		var viewportBottom = viewportTop + $(window).height();
		return elementBottom > viewportTop && elementTop < viewportBottom;
	}

});
