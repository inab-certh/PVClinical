$(function() {
	$(".datepicker").each(function() {
		console.log($(this).attr('min'));
		console.log($(this).attr('max'));
		$(this).datepicker({
			format: "yyyy-mm-dd",
			startDate: $(this).attr('min'),
			endDate: $(this).attr('max'),
			autoclose: true,
			language: $("#curLang").data("lang")==="Greek"?"el":"en"
			});
	});
});
	    