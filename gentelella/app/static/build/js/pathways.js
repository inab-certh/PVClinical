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


});
