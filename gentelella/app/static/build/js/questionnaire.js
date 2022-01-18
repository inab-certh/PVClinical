$(function() {
    var result="";

    $("[type='radio']").prop("disabled", true);
    $("#id_q1_0").prop("disabled", false);
    $("#id_q1_1").prop("disabled", false);
    $("ul").css("color", "#C8C8C8");
    $("#id_q1").css("color", "#535353");
    $("p").find("label").css("color", "#C8C8C8");
    $("p").find("label[for=id_q1_0]").css("color", "#535353");
    $("button").prop("disabled", false);

    $("#id_q1_0").change(function () {
        $("#id_q2_0").prop("disabled", false);
        $("#id_q2_1").prop("disabled", false);
        $("#id_q2").css("color", "#535353");
        $("label[for=id_q2_0]").css("color", "#535353");
        $("label[for=id_q2_1]").css("color", "#535353");
        $("#resultUn").css("color", "#C8C8C8");
    });

    $("#id_q1_1").change(function () {
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("label[for=id_q2_0]").css("color", "#C8C8C8");
        $("label[for=id_q2_1]").css("color", "#C8C8C8");
        $(document).scrollTop($(document).height());
        $("#resultUn").css("color", "#535353");
        result=$("#resultUn").text();


    });

    $("#id_q2_0").change(function () {
        name2=$(this).data('name');

        $("#id_q4_0").prop("disabled", false);
        $("#id_q4_1").prop("disabled", false);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("label[for=id_q4_0]").css("color", "#535353");
        $("label[for=id_q4_1]").css("color", "#535353");
        $("label[for=id_q3_0]").css("color", "#C8C8C8");
        $("label[for=id_q3_1]").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
    });

    $("#id_q2_1").change(function () {
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", false);
        $("#id_q3_1").prop("disabled", false);
        $("label[for=id_q4_0]").css("color", "#C8C8C8");
        $("label[for=id_q4_1]").css("color", "#C8C8C8");
        $("label[for=id_q3_0]").css("color", "#535353");
        $("label[for=id_q3_1]").css("color", "#535353");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
    });


    $("#id_q3_1").change(function () {
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#resultUn").css("color", "#535353");
        $("label[for=id_q4_0]").css("color", "#C8C8C8");
        $("label[for=id_q4_1]").css("color", "#C8C8C8");
        $(document).scrollTop($(document).height());
        result=$("#resultUn").text();

        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);

    });

    $("#id_q3_0").change(function () {
        $("#id_q4_0").prop("disabled", false);
        $("#id_q4_1").prop("disabled", false);
        $("label[for=id_q4_0]").css("color", "#535353");
        $("label[for=id_q4_1]").css("color", "#535353");
        $("#resultUn").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);

    });

    $("#id_q4_0").change(function () {
        $("#id_q6_0").prop("disabled", false);
        $("#id_q6_1").prop("disabled", false);
        $("label[for=id_q6_0]").css("color", "#535353");
        $("label[for=id_q6_1]").css("color", "#535353");
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("label[for=id_q5_0]").css("color", "#C8C8C8");
        $("label[for=id_q5_1]").css("color", "#C8C8C8");
        $("#id_q1_1").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
    });

    $("#id_q4_1").change(function () {
        $("#id_q5_0").prop("disabled", false);
        $("#id_q5_1").prop("disabled", false);
        $("label[for=id_q5_0]").css("color", "#535353");
        $("label[for=id_q5_1]").css("color", "#535353");
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("label[for=id_q6_0]").css("color", "#C8C8C8");
        $("label[for=id_q6_1]").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);

    });


    $("#id_q5_0").change(function () {
        $("#id_q6_0").prop("disabled", false);
        $("#id_q6_1").prop("disabled", false);
        $("label[for=id_q6_0]").css("color", "#535353");
        $("label[for=id_q6_1]").css("color", "#535353");
        $("#resultPo").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
    });

    $("#id_q5_1").change(function () {
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("label[for=id_q6_0]").css("color", "#C8C8C8");
        $("label[for=id_q6_1]").css("color", "#C8C8C8");
        $("#resultPo").css("color", "#535353");
        $(document).scrollTop($(document).height());
        result=$("#resultPo").text();

        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
    });

    $("#id_q6_0").change(function () {
        $("#id_q8_0").prop("disabled", false);
        $("#id_q8_1").prop("disabled", false);
        $("label[for=id_q8_0]").css("color", "#535353");
        $("label[for=id_q8_1]").css("color", "#535353");
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
        $("label[for=id_q7_0]").css("color", "#C8C8C8");
        $("label[for=id_q7_1]").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
    });

    $("#id_q6_1").change(function () {
        $("#id_q7_0").prop("disabled", false);
        $("#id_q7_1").prop("disabled", false);
        $("label[for=id_q7_0]").css("color", "#535353");
        $("label[for=id_q7_1]").css("color", "#535353");
        $("#id_q8_0").prop("disabled", true);
        $("#id_q8_1").prop("disabled", true);
        $("label[for=id_q8_0]").css("color", "#C8C8C8");
        $("label[for=id_q8_1]").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
    });

    $("#id_q7_0").change(function () {
        $("#id_q9_0").prop("disabled", false);
        $("#id_q9_1").prop("disabled", false);
        $("label[for=id_q9_0]").css("color", "#535353");
        $("label[for=id_q9_1]").css("color", "#535353");
        $("#resultPo").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
    });

    $("#id_q7_1").change(function () {
        $("#id_q9_0").prop("disabled", true);
        $("#id_q9_1").prop("disabled", true);
        $("label[for=id_q9_0]").css("color", "#C8C8C8");
        $("label[for=id_q9_1]").css("color", "#C8C8C8");
        $("#resultPo").css("color", "#535353");
        $(document).scrollTop($(document).height());
        result=$("#resultPo").text();

        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
    });

    $("#id_q8_0").change(function () {
        $("#id_q9_0").prop("disabled", true);
        $("#id_q9_1").prop("disabled", true);
        $("label[for=id_q9_0]").css("color", "#C8C8C8");
        $("label[for=id_q9_1]").css("color", "#C8C8C8");
        $("#resultDef").css("color", "#535353");
        $(document).scrollTop($(document).height());
        result=$("#resultDef").text();

        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
    });

    $("#id_q8_1").change(function () {
        $("#id_q9_0").prop("disabled", false);
        $("#id_q9_1").prop("disabled", false);
        $("label[for=id_q9_0]").css("color", "#535353");
        $("label[for=id_q9_1]").css("color", "#535353");
        $("#resultDef").css("color", "#C8C8C8");
            $("#id_q1_0").prop("disabled", true);
            $("#id_q1_1").prop("disabled", true);
            $("#id_q2_0").prop("disabled", true);
            $("#id_q2_1").prop("disabled", true);
            $("#id_q3_0").prop("disabled", true);
            $("#id_q3_1").prop("disabled", true);
            $("#id_q4_0").prop("disabled", true);
            $("#id_q4_1").prop("disabled", true);
            $("#id_q5_0").prop("disabled", true);
            $("#id_q5_1").prop("disabled", true);
            $("#id_q6_0").prop("disabled", true);
            $("#id_q6_1").prop("disabled", true);
            $("#id_q7_0").prop("disabled", true);
            $("#id_q7_1").prop("disabled", true);
    });

    $("#id_q9_0").change(function () {
        $("#id_q10_0").prop("disabled", true);
        $("#id_q10_1").prop("disabled", true);
        $("label[for=id_q10_0]").css("color", "#C8C8C8");
        $("label[for=id_q10_1]").css("color", "#C8C8C8");
        $("#resultDef").css("color", "#535353");
        $(document).scrollTop($(document).height());
        result=$("#resultDef").text();

        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
        $("#id_q8_0").prop("disabled", true);
        $("#id_q8_1").prop("disabled", true);
    });

    $("#id_q9_1").change(function () {
        $("#id_q10_0").prop("disabled", false);
        $("#id_q10_1").prop("disabled", false);
        $("label[for=id_q10_0]").css("color", "#535353");
        $("label[for=id_q10_1]").css("color", "#535353");
        $("#resultDef").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
        $("#id_q8_0").prop("disabled", true);
        $("#id_q8_1").prop("disabled", true);
    });

    $("#id_q10_0").change(function () {
        $("#resultPro").css("color", "#535353");
        $("#resultPo").css("color", "#C8C8C8");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
        $("#id_q8_0").prop("disabled", true);
        $("#id_q8_1").prop("disabled", true);
        $("#id_q9_0").prop("disabled", true);
        $("#id_q9_1").prop("disabled", true);
    });

    $("#id_q10_1").change(function () {
        $("#resultPro").css("color", "#C8C8C8");
        $("#resultPo").css("color", "#535353");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
        $("#id_q8_0").prop("disabled", true);
        $("#id_q8_1").prop("disabled", true);
        $("#id_q9_0").prop("disabled", true);
        $("#id_q9_1").prop("disabled", true);
    });

    $("#save_questionnaire").click(function() {
            $("input").prop("disabled", false);

    });

});