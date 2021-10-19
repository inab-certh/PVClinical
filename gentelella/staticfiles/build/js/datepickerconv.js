$(function() {
	$(".datepicker").each(function() {
		$(this).datepicker({
			format: "yyyy-mm-dd",
			startDate: $(this).attr('min'),
			endDate: $(this).attr('max'),
			autoclose: true,
			language: $("#curLang").data("lang")==="Greek"?"el":"en"
			});
	});
});
	    