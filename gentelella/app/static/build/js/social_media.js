$(function(){
    $(".social-iframe").load(function () {
        $(this).style.height = $(this).contentWindow.document.body.scrollHeight + 'px';
    })
});

function start_data_extraction(sc_id, keywords) {
    console.log(sc_id);
    console.log(keywords);
    $.ajax({
        url: "http://83.212.101.89:8090/tethys/rest/processes/create",
        data: {"keywords": keywords, "scenarioID": sc_id,},
        dataType: "json",
        success: function (data) {
            console.log("created");
          },
          error: function (data) {
            console.log("not created");
        }
    });
}
