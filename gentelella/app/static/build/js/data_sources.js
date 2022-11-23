$(function() {
    $(".dataSourcesModal").on('shown.bs.modal', function() {
        var iframe = document.querySelector(".modalIframe");
        var old = iframe.dataset.src;
        iframe.src = old;
    });

});