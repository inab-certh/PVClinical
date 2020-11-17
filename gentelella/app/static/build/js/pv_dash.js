$(function() {
    $("#menu_toggle").click(function(){
        if($("body").hasClass("nav-sm")) {
            $("#topPVLogo").removeClass("hidden-md hidden-lg").addClass("ml-5");
            $(".navbar.nav_title").hide();
        } else {
            $("#topPVLogo").addClass("hidden-md hidden-lg").removeClass("ml-5");
            $(".navbar.nav_title").show();
        }
    })

     $("[data-toggle='popover']").popover();

    // $(".iframe-box iframe").hover(function () {
    //     console.log("hover");
    //
    // });

    // $(".fullscreen-btn").click(function (e) {
    //     e.preventDefault();
    //     console.log($(this).parent().parent().find("iframe"));
    //     $(this).parent().parent().find("iframe").addClass("full-screen");
    // });
});