$(function(){
  $(".fold-table tr.view").on("click", function(){
    $(this).toggleClass("open").next(".fold").toggleClass("open");
  });

  $("iframe[id^='noteIframe']").hide();
  $("button[id^='closeBtn']").hide();

  $("button[id^='editBtn']").click(function () {
    var parent_div = $(this).parent();
    parent_div.find("iframe").show();
    parent_div.find("button[id^='editBtn']").hide();
    parent_div.find("button[id^='closeBtn']").show();
  });

  $("button[id^='closeBtn']").click(function () {
    var parent_div = $(this).parent();
    parent_div.find("iframe").hide();
    parent_div.find("iframe[id^='noteIframe']").hide();
    parent_div.find("button[id^='editBtn']").show();
    parent_div.find("button[id^='closeBtn']").hide();
  });

  $("iframe").load(function () {
    var note_id = parseInt($(this).attr("id").replace("noteIframe", ""));
    $.ajax({
      url: "ajax/get-note-content",
      data: {
        "note_id": note_id
      },
      dataType: "json",
      success: function (data) {
        var parent_div = $(this).parent();
        $("#noteContent"+note_id).html(data["note_content"]);
      }
    });
  });

  $(".fold-table").DataTable({
      // pageLength: 10,
      filter: true,
      columns: [{ visible: true, "bSearchable": true }]
      // deferRender: true,
      // scrollY: 200,
      // scrollCollapse: true,
      // scroller: true
  });
  $(".fold-table").on('click', 'td.details-control', function () {
        var tr = $(this).closest('tr');
        var row = table.row( tr );

        if ( row.child.isShown() ) {
            // This row is already open - close it
            row.child.hide();
            tr.removeClass('shown');
        }
        else {
            // Open this row
            row.child( format(row.data()) ).show();
            tr.addClass('shown');
        }
    } );

});
