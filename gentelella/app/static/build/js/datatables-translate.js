$(document).ready(function() {
    var language = $('#curLang').attr('data-lang');

    $('.dt-multilingual').DataTable( {
        destroy: true,
        "language": {
            "url": "/static/tr/datatables/"+language+".json"
        },
        columnDefs: [
            { "width": "56px", "targets": [0] },
            { "width": "200px", "targets": [2,4] }
        ]
    } );
} );