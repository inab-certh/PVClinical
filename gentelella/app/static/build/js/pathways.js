$(function() {
    $("#cpSaveBtn").click(function(event) {
        event.preventDefault();
        $.ajax({ // create an AJAX call...
                data: $('.x_panel form').serialize(), // get the form data
                type: 'post', // GET or POST
                url: window.location.href, // the file to call
                success: function(response) { // on success..
                    window.parent.closeCpModal();
                    window.parent.location.href = window.parent.location.href;
                    // console.log(response);
                },
                error: function (response) {
                    $(".x_panel form").submit();
                }
            });
            return false;

        });


    $("#cpCancelBtn").click(function(event) {
        event.preventDefault();
        window.parent.closeCpModal();
    });

    window.closeCpModal = function(){
        $('#editCpModal').modal('hide');
    };

    $("#cpAnalysisBtn").on("click", function(){
        const csrftoken = getCookie('csrftoken');
        var exec_url = '/ajax/gen-cp-analysis';

        $.ajax({
            url: exec_url,
            data: {'cp_id': cp_id},
            contentType:'application/json',
            headers: {"X-CSRFToken": csrftoken},
            dataType: 'json',
            cache: false,
            success: function(data){
                // console.log("OK!");
            },
            error: function (error) {
                console.log("Error!");
            }
        });
    });

});
