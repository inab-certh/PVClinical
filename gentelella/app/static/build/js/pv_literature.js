$(function () {
    $(document).on("click", "a>img[name^='pubmed_image_']", function () {
        // console.log("Link starting");
        // scenario_id = $(".delete-sc-btn").data("scid");
        var scenario_id = $(this).attr('name').replace("pubmed_image_", "");
        // console.log(scenario_id);
        $.ajax({
            url: 'ajax/mendeley_login',
            method: 'GET',
            dataType: 'json',
            success: function (data) {
                if (data.logged_in === true) {
                    $("#loaderOverlay").fadeIn();
                    window.open('/LiteratureWorkspace/' + parseInt(scenario_id), '_self');
                } else {
                    $('#mendeleyModal').modal('show');
                }


            },
         error: function (data) {
            console.log("error");
         }
            });
    });

    $("#dateUpdate").click(function () {
        $('#dateModal').modal('show');
    });

    $("#updatebtn").click(function () {
        // console.log("Link starting");
        var first = $('#firstDate').val();
        // console.log(first);
        var last = $('#lastDate').val();
        // console.log(last);
        var scenario_id = $("#scenario_id").text();
        window.open('/LiteratureWorkspace/' + parseInt(scenario_id) +'/' + parseInt(first) +'/' + parseInt(last), '_self');

    });
});