$(function() {
    var result="";

    $("[type='radio']").prop("disabled", true);
    $("#id_q1_0").prop("disabled", false);
    $("#id_q1_1").prop("disabled", false);
    $("ul").css("color", "rgb(200, 200, 200)");
    $("#id_q1").css("color", "rgb(83, 83, 83)");
    $("p").find("label").css("color", "rgb(200, 200, 200)");
    $("p").find("label[for=id_q1_0]").css("color", "rgb(83, 83, 83)");
    // $("button").prop("disabled", false);

    $("#id_q1_0").change(function () {
        $("#id_q2_0").prop("disabled", false);
        $("#id_q2_1").prop("disabled", false);
        $("#id_q2").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q2_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q2_1]").css("color", "rgb(83, 83, 83)");
        $("#resultUn").css("color", "rgb(200, 200, 200)");
    });

    $("#id_q1_1").change(function () {
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);
        $("label[for=id_q2_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q2_1]").css("color", "rgb(200, 200, 200)");
        $(document).scrollTop($(document).height());
        $("#resultUn").css("color", "rgb(83, 83, 83)");
        result=$("#resultUn").text();


    });

    $("#id_q2_0").change(function () {
        name2=$(this).data('name');

        $("#id_q4_0").prop("disabled", false);
        $("#id_q4_1").prop("disabled", false);
        $("#id_q3_0").prop("disabled", true);
        $("#id_q3_1").prop("disabled", true);
        $("label[for=id_q4_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q4_1]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q3_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q3_1]").css("color", "rgb(200, 200, 200)");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
    });

    $("#id_q2_1").change(function () {
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#id_q3_0").prop("disabled", false);
        $("#id_q3_1").prop("disabled", false);
        $("label[for=id_q4_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q4_1]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q3_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q3_1]").css("color", "rgb(83, 83, 83)");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
    });


    $("#id_q3_1").change(function () {
        $("#id_q4_0").prop("disabled", true);
        $("#id_q4_1").prop("disabled", true);
        $("#resultUn").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q4_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q4_1]").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q4_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q4_1]").css("color", "rgb(83, 83, 83)");
        $("#resultUn").css("color", "rgb(200, 200, 200)");
        $("#id_q1_0").prop("disabled", true);
        $("#id_q1_1").prop("disabled", true);
        $("#id_q2_0").prop("disabled", true);
        $("#id_q2_1").prop("disabled", true);

    });

    $("#id_q4_0").change(function () {
        $("#id_q6_0").prop("disabled", false);
        $("#id_q6_1").prop("disabled", false);
        $("label[for=id_q6_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q6_1]").css("color", "rgb(83, 83, 83)");
        $("#id_q5_0").prop("disabled", true);
        $("#id_q5_1").prop("disabled", true);
        $("label[for=id_q5_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q5_1]").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q5_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q5_1]").css("color", "rgb(83, 83, 83)");
        $("#id_q6_0").prop("disabled", true);
        $("#id_q6_1").prop("disabled", true);
        $("label[for=id_q6_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q6_1]").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q6_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q6_1]").css("color", "rgb(83, 83, 83)");
        $("#resultPo").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q6_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q6_1]").css("color", "rgb(200, 200, 200)");
        $("#resultPo").css("color", "rgb(83, 83, 83)");
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
        $("label[for=id_q8_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q8_1]").css("color", "rgb(83, 83, 83)");
        $("#id_q7_0").prop("disabled", true);
        $("#id_q7_1").prop("disabled", true);
        $("label[for=id_q7_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q7_1]").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q7_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q7_1]").css("color", "rgb(83, 83, 83)");
        $("#id_q8_0").prop("disabled", true);
        $("#id_q8_1").prop("disabled", true);
        $("label[for=id_q8_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q8_1]").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q9_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q9_1]").css("color", "rgb(83, 83, 83)");
        $("#resultPo").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q9_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q9_1]").css("color", "rgb(200, 200, 200)");
        $("#resultPo").css("color", "rgb(83, 83, 83)");
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
        $("label[for=id_q9_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q9_1]").css("color", "rgb(200, 200, 200)");
        $("#resultDef").css("color", "rgb(83, 83, 83)");
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
        $("label[for=id_q9_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q9_1]").css("color", "rgb(83, 83, 83)");
        $("#resultDef").css("color", "rgb(200, 200, 200)");
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
        $("label[for=id_q10_0]").css("color", "rgb(200, 200, 200)");
        $("label[for=id_q10_1]").css("color", "rgb(200, 200, 200)");
        $("#resultDef").css("color", "rgb(83, 83, 83)");
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
        $("label[for=id_q10_0]").css("color", "rgb(83, 83, 83)");
        $("label[for=id_q10_1]").css("color", "rgb(83, 83, 83)");
        $("#resultDef").css("color", "rgb(200, 200, 200)");
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
        $("#resultPro").css("color", "rgb(83, 83, 83)");
        $("#resultPo").css("color", "rgb(200, 200, 200)");
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
        $("#resultPro").css("color", "rgb(200, 200, 200)");
        $("#resultPo").css("color", "rgb(83, 83, 83)");
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

    // $("#id_q1_1, #id_q3_1, #id_q5_1, #id_q7_1, #id_q8_0, #id_q9_0").change(function () {
    //     $("#saveQuestionnaire").prop("disabled", false);
    // });
    //
    // $("#id_q1_0, #id_q2_0, #id_q2_1, #id_q3_0, #id_q4_0," +
    //     " #id_q4_1, #id_q5_0, #id_q6_0, #id_q6_1, #id_q7_0, #id_q8_1, #id_q9_1").change(function () {
    //     $("#saveQuestionnaire").prop("disabled", true);
    // });
    $("input[id^='id_q']").change(function () {
        console.log($(this).css("color"));
        if($("th[id^='result']").filter(function(i, el){
            return $(el).css("color")=== "rgb(83, 83, 83)";}).length>0) {
            $("#saveQuestionnaire").prop("disabled", false);
        } else {
            $("#saveQuestionnaire").prop("disabled", true);
        }
    });

    $("#saveQuestionnaire").click(function() {
            $("input").prop("disabled", false);

    });

});