var isForm = true;
var minAge = 12;
var maxAge = 120;
var isAge = false;

$(document).ready(function () {
	"use strict";
	$(".login-anonymous-button").click(function (e) {
		if (!isForm) {
			e.preventDefault();
			toggleForm();
		}
	});

	$(".arrow-up").click(function () {
		toggleForm();
	});

	function toggleForm() {
		// isForm = !isForm;
		// $(".hidden-form").toggleClass("showloginform");
		// $(".arrow-up").toggleClass("flip");
		// $(".login-col").toggleClass("fixlogincol");
	}

	$(".select").on("change", function () {
		$(this).removeClass("lightgray");
	});

	for (var i = minAge; i <= maxAge; i++) {
		$(".select").html($(".select").html() + '<option class="black" value="' + i + '">' + i + '</option>');
	}
});


