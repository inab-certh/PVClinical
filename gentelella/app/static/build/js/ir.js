$(function() {
    var study_chkbx = $("input[name='add_study_window']");
    show_hide_study_fields(study_chkbx[0]);

    study_chkbx.change(function () {
        show_hide_study_fields(this);
    });

    function show_hide_study_fields(chkbx) {
        console.log("okie");
        console.log(chkbx.checked);
        if(chkbx.checked === false) {
            $("#studyStartDate").hide();
            $("#studyEndDate").hide();
        } else {
            $("#studyStartDate").show();
            $("#studyEndDate").show();
        }
    }
});
