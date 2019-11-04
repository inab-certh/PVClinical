$(document).ready(function() {
    var language = $('#curLang').attr('data-lang');

    $('.dt-multilingual').DataTable( {
        destroy: true,
        "language": {
            "url": "/static/tr/datatables/"+language+".json"
        }
    } );
} );