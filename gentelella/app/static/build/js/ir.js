$(function() {
    var study_chkbx = $("input[name='add_study_window']");
    show_hide_study_fields(study_chkbx[0]);

    study_chkbx.change(function () {
        show_hide_study_fields(this);
    });

    var age_crit = $("#ageCrit select");
    show_hide_ext_age(age_crit);

    age_crit.change(function () {
        show_hide_ext_age($(this));
    });

    $("#irSaveBtn").click(function(event) {
        event.preventDefault();
        $.ajax({ // create an AJAX call...
                data: $('.x_panel form').serialize(), // get the form data
                type: 'post', // GET or POST
                url: window.location.href, // the file to call
                success: function(response) { // on success..
                    window.parent.closeIRModal();
                    window.parent.location.href = window.parent.location.href;
                    // console.log(response);
                },
                error: function (response) {
                    $(".x_panel form").submit();
                }
            });
            return false;

    //     console.log($("#message_container").hasClass("success"));
    //     event.preventDefault();
    //     $.ajax({
    //         url: window.parent.location.href,
    //         type: 'post',
    //         // dataType: 'json',
    //         data: $('.x_panel form'),
    //         success: function(data) {
    //             console.log($('.x_panel form').serialize());
    //             console.log("submitted");
    //             },
    //         error: function(err) {
    //             console.log(window.parent.location.href);
    //             console.log($('.x_panel form').serialize());
    //             console.log("error", err);
    //         }
    //
    //     });

    // });
    //
    // $(".x_panel form").submit(function(event) { // catch the form's submit event
    //         console.log("Message container: ");
    //         console.log($("#message_container").hasClass("success"));
    //         $(".x_panel form").submit();
            // $.ajax({ // create an AJAX call...
            //     data: $(this).serialize(), // get the form data
            //     type: $(this).attr('method'), // GET or POST
            //     url: $(this).attr('action'), // the file to call
            //     success: function(response) { // on success..
            //         console.log("response");
            //         // console.log(response);
            //     },
            //     error: function (response) {
            //         console.log(response.error());
            //     }
            // });
            // return false;
        });


    //  $('#editIRModal').on('hidden.bs.modal', function(e)
    // {
    //     window.parent.location.href = window.parent.location.href;
    // }) ;

    $("#irCancelBtn").click(function(event) {
        event.preventDefault();
        window.parent.closeIRModal();
    });

    // $("#editFormBtn").on("reloadForm", function (){
    //     console.log("reload form");
    //     window.location.reload();
    // });


    function show_hide_study_fields(std_chkbx) {
        if(std_chkbx.checked === false) {
            $(".date-fields").css("display", "none");
            // $("#studyStartDate").css("display", "none");
            // $("#studyEndDate").css("display", "none");
            // $(".calendar-icon-div").css("display", "none");
        } else {
            $(".date-fields").css("display", "block");
            // $("#studyStartDate").css("display", "block");
            // $("#studyEndDate").css("display", "block");
            // $(".calendar-icon-div").css("display", "block");
        }
    }

    function show_hide_ext_age(age_op) {
        if(age_op.find("option:selected").val().indexOf("bt")>=0 ) {
            $("#extAgeLimit").show();
            $("#ageConj").show();
        } else {
            $("#extAgeLimit").hide();
            $("#ageConj").hide();
        }
    }

    window.closeIRModal = function(){
        $('#editIRModal').modal('hide');
    };


});

// function() {
//     $('#confirmBtn').click(function() {
//         console.log("confirmed");
//         // $.ajax({
//         //     url: "{{ request.path }}",
//         //     method: 'DELETE',
//         //     data: {"scenario_id": $(this).data("record")},
//         //     beforeSend: function(xhr) {
//         //         xhr.setRequestHeader("X-CSRFToken", $('input[name=csrfmiddlewaretoken]').val());
//         //     }
//         //
//         // }) 	.always(function(){
//         //         $('#confirmModal').modal('hide');
//         //     })
//         //     .done(function(data) {
//         //         $('[class="modal-title"]').text("{% trans 'Επιτυχής διαγραφή!'%}");
//         //         $('[class="modal-body"]').text(data);
//         //
//         //         /* Info modal is already open */
//         //         $('#infoModal').on('hidden.bs.modal', function (e) {
//         //             window.location.replace("{% url 'index' %}");
//         //             //location.reload();
//         //         });
//         //
//         //         $("#dismissBtn").on("click", function () {
//         //             $('#infoModal').modal('hide');
//         //         });
//         //
//         //     })
//         //     .fail(function(resp){
//         //         $('[class="modal-title"]').text("{% trans 'Αποτυχία διαγραφής!'%}");
//         //         $('[class="modal-body"]').text(resp.responseText);
//         //         $('#infoModal').on('hidden.bs.modal', function (e) {
//         //             location.reload();
//         //         });
//         //     });
//     });
// }

