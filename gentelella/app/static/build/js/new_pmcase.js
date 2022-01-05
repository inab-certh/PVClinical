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

    $(".pmselect2tagwidget[name='scenarios'] option").each(function(){
        $(this).addClass("has-popover");
        $(this).attr("data-toggle", "popover");
        // $(this).attr("data-sanitize", "false");
        // $(this).attr("title", $(this).text());
        var popover_content="";
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
            alert("Error: " + e);
        });
        $(this).attr("data-trigger", "manual");
        $(this).attr("data-placement", "right");
        $(this).attr("data-html", "true");
        $(this).attr("data-container", "body");
        $(this).attr("data-width", "100%");
        $(this).attr("data-content", popover_content);
    });

    // $("body").on("hover", ".select2-results__option", function () {
    //     console.log("hovvvvvvvvvver");
    //
    // });

    // $("body").on('shown.bs.popover', function(){
    //   alert('Popover is completely visible!');
    // });

    $(".pmselect2tagwidget[name='scenarios']").on("select2:open", function(e){
        $(".pmselect2tagwidget option").popover("hide");
    });

    $(".pmselect2tagwidget[name='scenarios']").on("select2:close", function(e){
        $(".pmselect2tagwidget option").popover("hide");
    });

    $("body").on("mouseenter", ".select2-results__option", function(e){
        var sc_id = $(this).attr("id").split("-").pop();
        // console.log($(".popover"));
        $(".pmselect2tagwidget[name='scenarios'] option").filter(function(){return this.value!==""+sc_id}).popover("hide");
        // setTimeout(function() {
            $(".pmselect2tagwidget[name='scenarios'] option").filter(function(){return this.value==""+sc_id}).popover("show");
            // }, 2000);

        clearInterval($(this).data("timer") );
    });

    $('[data-toggle="popover"]').popover({"trigger":"manual"
    }).on("mouseenter", function () {
        var _this = this;
        $(this).popover("show");
        $(".popover").on("mouseleave", function () {
            $(_this).popover('hide');
        });
    }).on("mouseleave", function () {
        var _this = this;
        setTimeout(function () {
            if (!$(".popover:hover").length) {
                $(_this).popover("hide");
            }
        }, 100);
    });

    // $('body').on('mouseleave', '.select2-results__option', function(e){
    //     var sc_id = $(this).attr("id").split("-").pop();
    //     $(".pmselect2tagwidget option").filter(function(){return this.value==""+sc_id}).popover("hide");
    //     clearInterval($(this).data('timer') );
    // });


    // $(".pmselect2tagwidget").on('select2:open', function (e) {
    //     var data = e.params.data;
    //     console.log(data);
    //     console.log(data.id);
    //     console.log($("option#"+data.id));
    //     // $('[data-toggle="popover"]').popover("show");
    // });
    //

    // $('[data-toggle="popover"]').popover();
});

