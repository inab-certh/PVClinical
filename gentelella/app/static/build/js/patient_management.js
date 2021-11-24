$(function() {
    var languages = {"Greek": "el", "English": "en"};

    $(".pmselect2tagwidget[name='scenarios']").select2({
        language: languages[$("#curLang").attr("data-lang")],
        allowClear: true,
        minimumInputLength: 0,
        maximumSelectionLength: 1,
        // ajax: {
        //     url: "/ajax/filter-whole-set",
        //     dataType: "json",
        //     type: "GET",
        //     quietMillis: 50,
        //     data: function(params) {
        //         return {
        //             type: $(this).attr("name").replace("_fld",""),
        //             term: params.term,
        //             page: params.page
        //         };
        //     },
        //     processResults: function (data, params) {
        //         params.page = params.page || 1;
        //         page_size = 7;
        //
        //         return {
        //             results: data.results.slice((params.page - 1) * page_size, params.page * page_size),
        //             pagination: {
        //               more: (params.page * page_size) < data.total_count
        //             }
        //
        //         // return {
        //         //     results: data.results
        //         };
        //     },
        //     cache: true
        // }
    });

    $(".pmselect2tagwidget option").each(function(){
        // $(this).addClass('has-popover');
        $(this).attr("data-toggle", "popover");
        // $(this).attr("title", $(this).text());
        var popover_content;
        var sc_id=$(this).val();

        $.ajax({
            url: "/ajax/get-popover-content",
            data: {"sc_id": sc_id},
            type: "GET",
            dataType: "html",
            async: false
        }).done(function(data) {
            popover_content = data;
        }).fail(function (e) {
            alert('Error: ' + e);
        });
        $(this).attr("data-trigger", "manual");
        $(this).attr("data-placement", "right");
        $(this).attr("data-html", "true");
        $(this).attr("data-container", "body");
        $(this).attr("data-width", "100%");
        $(this).attr("data-content", popover_content);
    });


});

