$(function() {
    $(window).load(function(){
        $("#loaderOverlay").fadeOut();
    });

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

    $("#scenariosTbl tr td a").on("click", function(){
        if($(this).attr("href")!="#") {
            $("#loaderOverlay").fadeIn();
        }
    });

    $(".ws-menu.btn-group>ul>li>a").on("click", function(){
        if(!$(this).attr("href").endsWith("#")) {
            $("#loaderOverlay").fadeIn();
        }
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
        var mod_id = $(this).data("id").replace(/\W/g, '');
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

    // $(".viewModal .modalIframe").on("load", function () {
    //     var iframe_cnts = $(this).contents();
    //     iframe_cnts.find(".alert-geninfo").hide();
    //     iframe_cnts.find(".scenario-details").hide();
    // });

    $(".viewModal").on('shown.bs.modal', function () {
        var modal_iframe = $("#"+$(this).attr("id")+" .modalIframe");

        // var iframe_src = modal_iframe.attr("src");
        // modal_iframe.attr("src", iframe_src);

        var iframe_cnts = modal_iframe.contents();
        iframe_cnts.find(".alert-geninfo").hide();
        iframe_cnts.find(".scenario-details").hide();
        iframe_cnts.find("#breadcrumbNav").hide();

    });

    $(".viewModal").on('hidden.bs.modal', function () {
        $("#loaderOverlay").fadeIn();
        location.reload();
    });

    $("#pubMedNotesModal, .notesModal").on('hidden.bs.modal', function () {
        if(window.location.href.indexOf("/notes")!==-1){
            location.reload();
        }
    });

    $(window).load(function() {
        var prev_active_breadcrumb = $("ol>.breadcrumb-item.active").prev();
        var prev_active_bc_a=prev_active_breadcrumb.find("a");
        if(prev_active_bc_a && prev_active_bc_a.attr("href")===window.location.href) {
            prev_active_bc_a.attr("href", $("form>div.btn-group>a.btn-dark").attr("href"));
        }
    });





    $(document).on("click", "button.report-btn", function (){
        $("#genReportConfirmModal").modal("show");
        var new_location = $(this).attr("data-href");
        $(document).on("click", "#genReportConfirmModal #confirmBtn", function() {
            $("#genReportConfirmModal").modal("hide");
            $("#loaderOverlay").fadeIn();
            window.location = new_location;
        }
        )
    });
});

function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            // Does this cookie string begin with the name we want?
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}



// document.onreadystatechange = function() {
//     if (document.readyState !== "complete") {
//         $("#loaderOverlay").fadeIn();
//     } else {
//         $("#loaderOverlay").fadeOut();
//     }
// };