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

    $('#confirmBtn').click(function() {
        console.log("confirmed");
    });


    function show_hide_study_fields(std_chkbx) {
        if(std_chkbx.checked === false) {
            $("#studyStartDate").hide();
            $("#studyEndDate").hide();
            $(".calendar-icon-div").hide();
        } else {
            $("#studyStartDate").show();
            $("#studyEndDate").show();
            $(".calendar-icon-div").show();
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