$(function(){
  $(".fold-table tr.view").on("click", function(){
    $(this).toggleClass("open").next(".fold").toggleClass("open").find("tr").toggleClass("open");
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

  $(".user-notes-table").DataTable({
      // pageLength: 10,
      filter: true,
      ordering: false,
      paging: true,
      columns: [{ visible: true, "bSearchable": true }],
      mark: {
        className: "highlight"
      }
      // deferRender: true,
      // scrollY: 200,
      // scrollCollapse: true,
      // scroller: true
  });

  $(".fold-table:not('.user-notes-table')").DataTable({
      // pageLength: 10,
      filter: false,
      ordering: false,
      paging: false,
      info: false,
      columns: [{ visible: true, "bSearchable": true }]
      // deferRender: true,
      // scrollY: 200,
      // scrollCollapse: true,
      // scroller: true
  });

  $(".dataTables_filter input").bind('change keydown keyup',function (){
    // console.log($(this).val().length);
    if($(this).val().length!=0) {
      $(".fold-table tr.view").addClass("open").next(".fold").addClass("open").find("tr").addClass("open");
    }
    if($(this).val().length===0) {
      $(".fold-table tr.view").removeClass("open").next(".fold").removeClass("open").find("tr").removeClass("open");
    }
    // console.log($("tr.fold:visible").closest("tr.view"));
    //
  });

});
