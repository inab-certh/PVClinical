$(document).ready(function(){
    $("[id*=ShinyBtn]").click(function(){
        var drug= $(this).data('drug');
        var con= $(this).data('con');
        var hash= $(this).data('hash');
        var lang = $("#curLang").data("lang").substring(0, 2).toLowerCase();
        var urlquickview1= openfda_shiny_endpoint + $(this).attr('id').replace('ShinyBtn','').replace(/\d+/,'') + "/?lang=" + lang + "&t1=" + drug + "&v1=patient.drug.openfda.generic_name&t2=" + con + "&v2=patient.reaction.reactionmeddrapt&hash=" + hash;
        var urlquickview2= openfda_shiny_endpoint + $(this).attr('id').replace('ShinyBtn','').replace(/\d+/,'') + "/?lang=" + lang + "&t1=" + drug + "&v1=patient.drug.openfda.generic_name&hash=" + hash;
        var urlquickview3= openfda_shiny_endpoint + $(this).attr('id').replace('ShinyBtn','').replace(/\d+/,'') + "/?lang=" + lang + "&t2=" + con + "&v2=patient.reaction.reactionmeddrapt&hash=" + hash;
        // console.log(urlquickview1);

        if (con == '') {
            document.getElementById('iframe_shiny').src = urlquickview2;
        } else if (drug == '') {
            document.getElementById('iframe_shiny').src = urlquickview3;
        } else {
            document.getElementById('iframe_shiny').src = urlquickview1;
        }
    });

    var openfda_shots_exist = false;

    function openfda_screenshots_exist(files_hashes) {
        $.ajax({
            url: "/ajax/openfda-screenshots-exist",
            data: {"hashes": JSON.stringify(files_hashes)},
            type: "GET",
            dataType: "json",
            async: false
        }).done(function(ret) {
            openfda_shots_exist = ret.exist;
        }).fail(function () {
            openfda_shots_exist = false;
        });
    }


    $("#shinyModal").on('hidden.bs.modal', function() {
        openfda_screenshots_exist(hashes);
    });

    var i=0;
    $("#opendfaChkBx").change(function() {
        if(this.checked) {
            openfda_screenshots_exist(hashes);
        }
        // console.log(openfda_shots_exist);
        if(openfda_shots_exist == true && $(this).prop("checked") == true){
            i=i+1;
            document.getElementById("proceed-report-btn").disabled = false;
            document.getElementById("result").disabled = false;
        }
        else {
            i=i-1;
            if(i==0){

            document.getElementById("proceed-report-btn").disabled = true;
            document.getElementById("result").disabled = true;
            }
        }
    });

    $("[id*=NotesBtn]").click(function(){
        hash= $(this).data('hash');
        var drug= $(this).data('drug');
        var con= $(this).data('con');
        note= $(this).data('note');

        $("#shinyModal_notes").val( note ) ;
        $("#label_shiny_note").text(note);
    });


    $(".note_chkb").on("change", function(){

        if($(this).is(':checked') && !(hash in all_notes)){
            // console.log(note)
            // console.log(hash)
            all_notes[hash]=note;
            // console.log(all_notes);
        }else if(!$(this).is(':checked') && (hash in all_notes)){
            delete all_notes[hash];
            // console.log(all_notes);
        }
    });

    $("#shinyModal_notes").on('show.bs.modal', function (){
        if(hash in all_notes){
            $(".note_chkb").prop("checked", true);
        }else{
            $(".note_chkb").prop("checked", false);
        }
    });

    $("#div2").hide();

    $("#link1").on("click", function() {
        $("#div1").show();
        $("#div2").hide();
    });
});

