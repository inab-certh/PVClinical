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


    var sc_id = 'None';

     $("#myInput").on("keyup", function() {
        var value = $(this).val().toLowerCase();
        $("#collapseScen a").filter(function() {
          $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
        });
      });

    $(document).on('click', 'input[type="checkbox"]', function() {
        $('input[type="checkbox"]').not(this).prop('checked', false);
    });

    $('input[name="scenarios"]').on("change", function() {
        if($('input[name="scenarios"]:checked').length == 1) {
            sc_id = $(this).val();
        }
    });

    $("#completedQuestDiv").hide();

    var old_scen_options = $("[name='scenarios'] option");
    var old_scen_opts_val_lst = $.map( old_scen_options, function( opt, index ) {
        return opt.value;
    });

    $('#addPatScenModal').on('hidden.bs.modal', function () {
        // var new_scen_options = [];
        var new_scen_opts_val_lst =[];

        $.ajax({
            url: "/ajax/get-updated-scenarios-ids",
            dataType: "json",
            success: function (data) {
                new_scen_opts_val_lst = data.scenarios_ids;

                var difference = new_scen_opts_val_lst.filter(x => !old_scen_opts_val_lst.includes(x));

                if(difference && difference.length!=0) {
                    // $("[name='scenarios']").val(difference);
                    // $("[name='scenarios']").trigger("change");
                    sessionStorage.setItem("difference", difference);
                    sessionStorage.setItem("pat_id", $("[name='patient_id']").val());
                    sessionStorage.setItem("questionnaires", $("[name='questionnaires']").val());

                    $("#loaderOverlay").fadeIn();
                    var loc = window.location;
                    window.location = loc.protocol + '//' + loc.host + loc.pathname + loc.search;
                    // $(".ma-form").submit();
                }
              },
            error: function (res) {
                console.log("error "+res);
            }
        });

        // var new_scen_opts_val_lst = $.map( new_scen_options, function( opt, index ) {
        //     return opt.value;
        // });

        // $("#loaderOverlay").fadeIn();
        // var loc = window.location;
        // window.location = loc.protocol + '//' + loc.host + loc.pathname + loc.search;
        // location.reload();
    });
    //
    // $('#questionnaireModal').on('hidden.bs.modal', function () {
    //     $("#loaderOverlay").fadeIn();
    //     // var loc = window.location;
    //     // window.location = loc.protocol + '//' + loc.host + loc.pathname + loc.search;
    //     // console.log(loc);
    //     // location.reload();
    // });

    $('#questionnaireModal').on('hide.bs.modal', function () {
        $("#loaderOverlay").fadeIn();
        $.ajax({
            url: "/ajax/retr-del-session-pmcvars",
            dataType: "json",
            success: function (data) {
                // $("[name='patient_id']").val(data["pat_id"]).trigger("change");
                // $("[name='scenarios']").val(data["sc_id"]).trigger("change");
                if(data["quest_id"] && data["quest_id"].length!=0) {
                    $("[name='questionnaires']").val(data["quest_id"]).trigger("change");
                    $(".ma-form").submit();
                }
              },
            error: function (res) {
                console.log("error "+res);
            }
        });
    });


    var init_patient_id = $("[name='patient_id']").val();
    var init_sc_id = $("[name='scenarios']").val();
    var init_quest_id = $("[name='questionnaires']").val();

    if(init_patient_id && init_sc_id && init_quest_id) {
        $(".btn-group>.save.btn").prop("disabled", false);
    } else {
        $(".btn-group>.save.btn").prop("disabled", true);
    }

    // $("[name='patient_id'], [name='scenarios'], [name='questionnaires']").on("change", function () {
    //     var patient_id = $("[name='patient_id']").val();
    //     var sc_id = $("[name='scenarios']").val();
    //     var questionnaire_id = $("[name='questionnaires']").val();
    //
    //     console.log($(".invalid-feedback"));
    //     if(patient_id && sc_id && questionnaire_id && !$(".invalid-feedback")) {
    //         $(".btn-group>.save.btn").prop("disabled", false);
    //         $("#completedQuestDiv").show();
    //     } else {
    //         $(".btn-group>.save.btn").prop("disabled", true);
    //         $("#completedQuestDiv").hide();
    //     }
    // });

    $(window).load(function () {
        var difference = sessionStorage.getItem("difference");
        sessionStorage.removeItem("difference");

        if(difference && difference.length!=0) {
            $("[name='scenarios']").val(difference).trigger("change");
            $("[name='patient_id']").val(sessionStorage.getItem("pat_id"))
            $("[name='questionnaires']").val(sessionStorage.getItem("questionnaires")).trigger("change");
            sessionStorage.removeItem("pat_id");
            sessionStorage.removeItem("questionnaires");
            $("[name='patient_id']").trigger("change");
        }

        var patient_id = $("[name='patient_id']").val();
        var sc_id = $("[name='scenarios']").val();
        var questionnaire_id = $("[name='questionnaires']").val();

        if(patient_id && sc_id && questionnaire_id && $(".invalid-feedback").length===0) {
            $(".btn-group>.save.btn").prop("disabled", false);
            $("#completedQuestDiv").show();
        } else {
            $(".btn-group>.save.btn").prop("disabled", true);
            $("#completedQuestDiv").hide();
        }
    });

    $("[name='patient_id'], [name='scenarios']").on("change", function () {
        var patient_id = $("[name='patient_id']").val();
        var sc_id = $("[name='scenarios']").val();

        if(patient_id && sc_id) {
            $(".ma-form").submit();
        } else {
            $("#questModalBtn").prop("disabled", true);
        }
    });

    $('#questModalBtn').on("click", function(){
        var patient_id = $("[name='patient_id']").val();
        var sc_id = $("[name='scenarios']").val();

        if(patient_id && sc_id){
            var url=$('#questModalBtn').data('url')+'/'+patient_id+'/'+sc_id;
            $('#iframe_quest').attr('src', url);

            $.ajax({
                url: "/ajax/new_pmcase",
                data: {"patient_id":patient_id,"sc_id":sc_id },
                dataType: "html",
                success: function (res) {
                    $('#questionnaireModal').modal('show');
                  },
                  error: function (res) {
                    console.log("error "+res);
                }
            });

        }
        // else{
        //     {#location.reload();#}
        //     $('#patManQuestFillInfoModal').modal('show');
        // };

    });


    $("#addPatScenModal iframe").on("load", function(){
        var iframe_cnts = $(this).contents();
        iframe_cnts.find("a#topPVLogo").hide();
        iframe_cnts.find("form#languageForm").hide();
        iframe_cnts.find("div.container.body div.main_container div.alert-geninfo").hide();
        iframe_cnts.find("div.container.body div.main_container div.top_nav").hide();
        iframe_cnts.find("div.container.body div.main_container div.x_panel .btn-group.ws-menu").hide();
        iframe_cnts.find("div.container.body div.main_container div.x_panel .btn-group>a.btn-dark").hide();
        iframe_cnts.find("footer").hide();
    });

    $(".btn-group>.save.btn").click(function (e) {
       e.preventDefault();
       $("[name='saveCtrl']").val(1).trigger("change");
       $(".ma-form").submit();
    });

});

