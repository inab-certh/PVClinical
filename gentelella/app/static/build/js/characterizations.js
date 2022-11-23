$(function() {
    $("#charSaveBtn").click(function(event) {
        event.preventDefault();
        $.ajax({ // create an AJAX call...
                data: $('.x_panel form').serialize(), // get the form data
                type: 'post', // GET or POST
                url: window.location.href, // the file to call
                success: function(response) { // on success..
                    window.parent.closeCharModal();
                    window.parent.location.href = window.parent.location.href;
                    // console.log(response);
                },
                error: function (response) {
                    $(".x_panel form").submit();
                }
            });
            return false;

        });


    $("#charCancelBtn").click(function(event) {
        event.preventDefault();
        window.parent.closeCharModal();
    });

    window.closeCharModal = function(){
        $('#editCharModal').modal('hide');
    };

    $("#charAnalysisBtn").on("click", function(){
        const csrftoken = getCookie('csrftoken');
        var exec_url = '/ajax/gen-char-analysis';

        $.ajax({
            url: exec_url,
            data: {'char_id': char_id},
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
