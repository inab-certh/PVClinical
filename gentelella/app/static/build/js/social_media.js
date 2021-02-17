$(function(){
    $(".social-iframe").load(function () {
        $(this).style.height = $(this).contentWindow.document.body.scrollHeight + 'px';
    })
});