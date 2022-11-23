$(document).ready(function(){

  $('#drugDateRange input').bsDatepicker({
    autoclose: true
  });
  $("#drugDateRange").attr('onkeydown', 'return false');
  
  
    $('#daterange input').bsDatepicker({
    autoclose: true
  });
  $("#daterange").attr('onkeydown', 'return false');
});

