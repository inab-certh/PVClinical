// $(function(){
//     var lang = $('#curLang').attr('data-lang');
//     $("#allNotesTbl").DataTable({
//         destroy: true,
//         // pageLength: 10,
//         language: {
//             url: "/static/tr/datatables/" + lang + ".json"
//         },
//         // columnDefs: [
//         //     { "width": "56px", "targets": [0] },
//         //     { "width": "200px", "targets": [2,4] }
//         // ],
//         // filter: true,
//         // ordering: false,
//         // paging: true,
//         // columns: [{visible: true, "bSearchable": true}],
//         mark: {
//             className: "highlight"
//         }
//     });
//
//     var note_obj = {};
//
//     $("#allNotesTbl").on("click", ".pm-notes-btn", function (event) {
//         // event.preventDefault();
//         var note_id = $(this).attr("name").replace("pubMedNotesBtn", "");
//         $.ajax({
//             url: "/ajax/get-note",
//             data: {
//                 'note_id': note_id,
//             },
//             method: 'GET',
//             dataType: 'json',
//             success: function (data) {
//                 $("#pubMedNotesModal .note-hdn").text(data.pid);
//                 $("#pubMedNotesModal .note-title").text(data.title);
//                 $("#pubMedNotesModal textarea[name='allNotesTxt']").val(data.content);
//                 // $("#pubMedNotesModal").show();
//                 note_obj = data;
//             }
//         });
//     });
//
//     $("button[name^='saveNotesBtn']").click(function () {
//         $.ajax({
//             url: "/ajax/save_pubmed_input/",
//             data: {
//                 'scenario_id': note_obj.scenario_id,
//                 'title': note_obj.title,
//                 'pubmeddate' : note_obj.pubmeddate,
//                 'relevance' : note_obj.relevance,
//                 'pmid' : note_obj.pid,
//                 'url' : note_obj.url,
//                 'abstract' : note_obj.abstract,
//                 'notes' : $("#pubMedNotesModal textarea[name='allNotesTxt']").val(),
//                 'authors' : note_obj.authors,
//             },
//             method: 'GET',
//             dataType: 'json',
//             success: function (data) {
//                 if (data.message === 'Failure') {
//                     $("#pubMedSaveInfoModal .modal-body").text(gettext("Αποτυχία αποθήκευσης"));
//                     $("#pubMedSaveInfoModal").modal("show");
//                 } else {
//                     $("#pubMedSaveInfoModal .modal-body").text(gettext("Επιτυχής αποθήκευση"));
//                     $("#pubMedSaveInfoModal").modal("show");
//                 }
//             }
//         });
//     });
//
//
//     // });
//
//
// });