$(function() {
    $('.has-popover').popover({'trigger':'manual'
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

    $("div.scenario-info a.has-popover").on('click',function(e){
        e.preventDefault();
    });

    $("#menu_toggle").click(function () {
        if ($("body").hasClass("nav-sm")) {
            $("#topPVLogo").removeClass("hidden-md hidden-lg").addClass("ml-5");
            $(".navbar.nav_title").hide();
        } else {
            $("#topPVLogo").addClass("hidden-md hidden-lg").removeClass("ml-5");
            $(".navbar.nav_title").show();
        }
    });

    $("[data-toggle='popover']").popover();
    $("body").on("click", ".notes-btn", function () {
        var mod_url = $(this).data("url");
        var mod_id = $(this).data("id");
        $(".notesModal").attr("id", mod_id);
        $(".notesModal iframe").attr("src", mod_url);
        $("#" + mod_id).modal("show");
    });

    $(window).scroll(function () {
        var winScrollTop = $(window).scrollTop();
        var winHeight = $(window).height();
        var floaterHeight = $('#floater').outerHeight(true);
        var fromBottom = 350;
        var top = winScrollTop + winHeight - floaterHeight - fromBottom;
        $('#floater').css({'top': top + 'px'});
    });

    $(".viewModal").on('shown.bs.modal', function () {
        var iframe_cnts = $(this).find("iframe").contents();
        iframe_cnts.find(".alert-geninfo").hide();
        iframe_cnts.find(".scenario-details").hide();
    });
    $("#pubMedNotesModal, .notesModal").on('hidden.bs.modal', function () {
        if(window.location.href.indexOf("/notes/dashboard")!==-1){
            location.reload();
        }
    });
});