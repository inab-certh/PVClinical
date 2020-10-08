$(function () {
        $("img[name^='pubmed_image_']").click(function () {
            console.log("Link starting");
            // scenario_id = $(".delete-sc-btn").data("scid");
            var scenario_id = $(this).attr('name').replace("pubmed_image_", "");
            console.log(scenario_id);
            $.ajax({
                url: 'ajax/mendeley_login',
                method: 'GET',
                dataType: 'json',
                success: function (data) {
                  if (data.logged_in === true){
                     window.open('/LiteratureWorkspace/'+ parseInt(scenario_id));
                  }
                 else{
                   $('#mendeleyModal').modal('show');
                  }


                  }
                });
        });
    });