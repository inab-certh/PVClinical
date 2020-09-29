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

    function show_hide_study_fields(std_chkbx) {
        if(std_chkbx.checked === false) {
            $("#studyStartDate").hide();
            $("#studyEndDate").hide();
        } else {
            $("#studyStartDate").show();
            $("#studyEndDate").show();
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
