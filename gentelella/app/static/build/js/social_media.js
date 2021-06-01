$(function(){
    $(".social-iframe").load(function () {
        try {
            $(this).style.height = $(this).contentWindow.document.body.scrollHeight + 'px';
        }
        catch(typeError) {
            console.log("Not found");
        }
    });
});

function start_data_extraction(sc_id, keywords) {
    var csrftoken = $("[name=csrfmiddlewaretoken]").val();
    $.ajax({
        type: "POST",
        headers:{"X-CSRFToken": csrftoken},
        url: "/ajax/start-data-extraction",
        data: {"keywords": keywords, "scenarioID": sc_id,},
        dataType: "json",
        success: function (data) {
            // console.log("created");
            $("#processesInfoModal .modal-title").html(gettext("Επιτυχής εκκίνηση"));
            $("#processesInfoModal .modal-body").html(
                "<p>"+gettext("Η διεργασία εξόρυξης δεδομένων ξεκίνησε επιτυχώς! Για να τη σταματήσετε, πατήστε το σχετικό κουμπί λήξης.")+"</p>");
            $("#processesInfoModal").modal("show");
            $("#startSMDEBtn").attr("disabled", true);
            $("#stopSMDEBtn").attr("disabled", false);
          },
          error: function (data) {
            // console.log("not created");
            // console.log(data.status);
            $("#processesInfoModal .modal-title").html(gettext("Αποτυχία εκκίνησης"));
            $("#processesInfoModal .modal-body").html("<p>"+gettext("Συνέβη κάποιο σφάλμα! Δυστυχώς, δεν ήταν εφικτή η εκκίνηση διεργασίας εξόρυξης δεδομένων.")+"</p>");
            $("#processesInfoModal").modal("show");
        }
    });
}

function stop_data_extraction(sc_id, keywords) {
    var csrftoken = $("[name=csrfmiddlewaretoken]").val();
    $.ajax({
        type: "POST",
        headers:{"X-CSRFToken": csrftoken},
        url: "/ajax/stop-data-extraction",
        data: {"keywords": keywords, "scenarioID": sc_id,},
        dataType: "json",
        success: function (data) {
            // console.log("created");
            $("#processesInfoModal .modal-title").html(gettext("Επιτυχής παύση"));
            $("#processesInfoModal .modal-body").html(
                "<p>"+gettext("Η διεργασία εξόρυξης δεδομένων διακόπηκε επιτυχώς! Για να την επανεκκινήσετε, πατήστε το σχετικό κουμπί έναρξης.")+"</p>");
            $("#processesInfoModal").modal("show");
            $("#stopSMDEBtn").attr("disabled", true);
            $("#startSMDEBtn").attr("disabled", false);
          },
          error: function (data) {
            // console.log("not stopped");
            // console.log(data.status);
            $("#processesInfoModal .modal-title").html(gettext("Αποτυχία παύσης"));
            $("#processesInfoModal .modal-body").html("<p>"+gettext("Συνέβη κάποιο σφάλμα! Δυστυχώς, δεν ήταν εφικτή η διακοπή διεργασίας εξόρυξης δεδομένων.")+"</p>");
            $("#processesInfoModal").modal("show");
        }
    });
}
