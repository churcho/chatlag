// JavaScript Document

$(document).ready(function() {
	"use strict";
	
	var totalchats, additionalchats_width, chats_per_screen, current_screen, totalscreens, animate_width;
	current_screen = 0;
	
	function resize() {
		totalchats = $(".additional-chat").length;
		additionalchats_width = $(".additional-chat").width();
		chats_per_screen = 8;
		if ($(window).width() > 1200) {
			animate_width = 1020;
		} else if ($(window).width() > 992)  {
			animate_width = 880;
		} else {
			chats_per_screen = 2;
			animate_width = 400;
		}
		totalscreens = Math.round(totalchats/chats_per_screen);
		$(".more-chats-scroll").css({"width":totalchats*additionalchats_width});
		$(".more-chats-scroll").css({"margin-right":-current_screen*animate_width});
	}
	
	window.addEventListener('resize', function () {
		resize();
	});

	resize();
	
	$(".goright").click(function() {
		if (current_screen > 0) {
			current_screen--;
			$(".more-chats-scroll").animate({"margin-right":current_screen*animate_width});
			$(".goleft").removeClass("disabled");
			if (current_screen == 0) {
				$(".goright").addClass("disabled");
			}
		}
	});
	$(".goleft").click(function() {
		if (current_screen < totalscreens-1) {
			current_screen++;
			$(".more-chats-scroll").animate({"margin-right":-current_screen*animate_width});
			$(".goright").removeClass("disabled");
			if (current_screen >= totalscreens-1) {
				$(".goleft").addClass("disabled");
			}
		}
	});
	
	var stats = [41,120,521,12050];
	var steps = 20;
	var current_step = 1;
	increaseStats();
	
	function increaseStats() {
		for (var k=1; k<=4; k++) {
			$(".stats"+k).html(Math.round(stats[k-1]/steps*current_step));
		}
		current_step++;
		if (current_step < steps+1) {
			setTimeout(increaseStats, 50);
		}
	}
});