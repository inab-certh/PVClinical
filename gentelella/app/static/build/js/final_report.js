$(function() {
    var openfda_proceed_disabled = true;
    var ohdsi_proceed_disabled = true;
    var pubmed_proceed_disabled = true;

    var event; // The custom event that will be created
    proceed_elm = document.createElement("div");

    function triggerProceedActivation(el) {
        if (document.createEvent) {
            event = document.createEvent("Event");
            event.initEvent("proceedactivation", true, true);
            event.eventName = "proceedactivation";
            el.dispatchEvent(event);
        } else {
            event = document.createEventObject();
            event.eventName = "proceedactivation";
            event.eventType = "proceedactivation";
            el.fireEvent("on" + event.eventType, event);
        }
    }

    proceed_elm.addEventListener("proceedactivation", function(e) {
        var proceed_disabled = openfda_proceed_disabled && Object.keys(all_notes).length === 0 &&
            ohdsi_proceed_disabled && pubmed_proceed_disabled;

        $("#proceed-report-btn").prop("disabled", proceed_disabled);
        $("#resultBtn").prop("disabled", proceed_disabled);
    });

    // $("#concomitantSwitch").on('change', function() {
    //     if ($(this).is(":checked")) {
    //         switchStatus = $(this).is(":checked");
    //     }
    //     else {
    //        switchStatus = $(this).is(":checked");
    //     }
    // });


    $("[id*=ShinyBtn]").click(function(){
        var drug= $(this).data("drug");
        var con= $(this).data("con");
        var hash= $(this).data("hash");
        var lang = $("#curLang").data("lang").substring(0, 2).toLowerCase();
        var concomitant = $("#concomitantSwitch").is(":checked")? "TRUE": "FALSE";
        var urlquickview1= openfda_shiny_endpoint + $(this).attr("id").replace("ShinyBtn","").replace(/\d+/,"") + "/?lang=" + lang + "&t1=" + drug + "&v1=patient.drug.openfda.generic_name&t2=" + con + "&v2=patient.reaction.reactionmeddrapt&concomitant="+concomitant+"&hash=" + hash;
        var urlquickview2= openfda_shiny_endpoint + $(this).attr("id").replace("ShinyBtn","").replace(/\d+/,"") + "/?lang=" + lang + "&t1=" + drug + "&v1=patient.drug.openfda.generic_name&concomitant="+concomitant+"&hash=" + hash;
        var urlquickview3= openfda_shiny_endpoint + $(this).attr("id").replace("ShinyBtn","").replace(/\d+/,"") + "/?lang=" + lang + "&t2=" + con + "&v2=patient.reaction.reactionmeddrapt&concomitant="+concomitant+"&hash=" + hash;

        if (con == "") {
            document.getElementById("iframe_shiny").src = urlquickview2;
        } else if (drug == "") {
            document.getElementById("iframe_shiny").src = urlquickview3;
        } else {
            document.getElementById("iframe_shiny").src = urlquickview1;
        }
    });

    var openfda_shots_exist = false;


    /**
     *  Activate or deactivate proceed buttons.
     *  If even one openFDA screenshot exists and checkbox is checked, activate.
     *  Deactivate otherwise.
    */
    function openfda_set_proceed_btns_status(files_hashes) {
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
        }).always(function(){
            // console.log($("#openfdaChkBx").is(":checked"));
            openfda_proceed_disabled = !(openfda_shots_exist == true);
            triggerProceedActivation(proceed_elm);
        });
    }
    function ohdsi_set_proceed_btns_status() {
        ohdsi_proceed_disabled = !(ir_table_rep || ir_all_rep || pre_table_rep || pre_chart_rep || drug_table_rep ||
            drug_chart_rep || demograph_table_rep || demograph_chart_rep || charlson_table_rep || charlson_chart_rep ||
            gen_table_rep || gen_chart_rep || cp_all_rep)
        triggerProceedActivation(proceed_elm);
    }

    function pubmed_set_proceed_btns_status() {
        pubmed_proceed_disabled = !(Object.keys(allPubTitles).length>0 || Object.keys(allPubNotes).length>0);
        triggerProceedActivation(proceed_elm);
    }

    $(".ohdsi-report-modal").on("hidden.bs.modal", function() {
        ohdsi_set_proceed_btns_status();
    });

    $("#shinyModal").on("hidden.bs.modal", function() {
        openfda_set_proceed_btns_status(hashes);
        $(this).find("iframe").attr("src", "");
    });

    $(".pubmed-report-modal").on("hidden.bs.modal", function() {
        pubmed_set_proceed_btns_status();
    });

    $("[id^=pubnote]").change(function(){

        var pubnote_rep= $(this).data("series");
        var note= $(this).data("note");

        if ($(this).is(":checked")) {
            allPubNotes[pubnote_rep]=$(this).data("objid");
        }else{
            // pubnote_rep = $(this).data("series") ;
            // allPubNotes[pubnote_rep]="";
            delete allPubNotes[pubnote_rep];
        }
    });

    $("[id^=pubtitle]").change(function(){

        var pubtitle_rep= $(this).data("series");

        if ($(this).is(":checked")) {
            allPubTitles[pubtitle_rep]=$(this).data("objid");

        }else{
            // pubtitle_rep = $(this).data("series") ;
            // allPubTitles[pubtitle_rep]="";
            delete allPubTitles[pubtitle_rep];
        }
        pubmed_set_proceed_btns_status();
    });


    var i=0;

    $("[id*=NotesBtn]").click(function(){
        hash= $(this).data("hash");
        var drug= $(this).data("drug");
        var con= $(this).data("con");
        note= $(this).data("note");

        var modal_id = $(this).data("target");
        $(modal_id).val(note) ;
        // $(".cke_shiny_note_contents textarea").text(note);
        // $("#shinyModal_notes .cke_shiny_note_contents textarea").addClass("ckeditor")
        $(".notes-editor iframe").contents().find("html, body").css(
            {"background-color": "#f4f4f4", "color": "#333333b3", "cursor": "not-allowed"});
    });

    $(".note_chkb").on("change", function(){
        if($(this).is(":checked") && !(hash in all_notes)){
            console.log(note);
            console.log(hash);
            all_notes[hash]=note;
            console.log(all_notes);
        } else if(!$(this).is(":checked") && (hash in all_notes)){
            delete all_notes[hash];
            // console.log(all_notes);
        }
    });

    $(".report-note-modal").on("hidden.bs.modal", function() {
        triggerProceedActivation(proceed_elm);
    });

    $("#shinyModal_notes").on("show.bs.modal", function (){
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

    $("#socialMediaModal iframe").load(function () {
        try {
            $(this).style.overflow = "hidden";
            $(this).style.height = $(this).contentWindow.document.body.scrollHeight + 'px';
        }
        catch(typeError) {
            console.log("Not found");
        }
    });

    $("#smGraphicsBtn").click(function() {
        $("#socialMediaModal iframe").attr("src", twitter_query_url);


    });

});

