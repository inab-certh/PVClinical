$(document).ready(function(){

  $("[id*=ShinyBtn]").click(function(){
  // console.log("ok")
      var drug= $(this).data('drug');
      var con= $(this).data('con');
      var hash= $(this).data('hash');
      var urlquickview1= "http://83.212.101.89:3838/deployshiny/"+ $(this).attr('id').replace('ShinyBtn','').replace(/\d+/,'')+ "/?lang=en&t1=" + drug + "&v1=patient.drug.openfda.generic_name&t2=" + con+ "&v2=patient.reaction.reactionmeddrapt&hash=" + hash;
	  var urlquickview2= "http://83.212.101.89:3838/deployshiny/"+ $(this).attr('id').replace('ShinyBtn','').replace(/\d+/,'')+ "/?lang=en&t1=" + drug + "&v1=patient.drug.openfda.generic_name&hash=" + hash;
      var urlquickview3= "http://83.212.101.89:3838/deployshiny/"+ $(this).attr('id').replace('ShinyBtn','').replace(/\d+/,'')+ "/?lang=en&t2=" + con + "&v2=patient.reaction.reactionmeddrapt&hash=" + hash;
       console.log(urlquickview1);

     if (con == ''){
        document.getElementById('iframe_shiny').src = urlquickview2;
        }else if (drug == ''){
        document.getElementById('iframe_shiny').src = urlquickview3;
        }else{
        document.getElementById('iframe_shiny').src = urlquickview1;

     };
  });

	var i=0;
    $('input[type="checkbox"]').click(function(){
        if($(this).prop("checked") == true){
            i=i+1
            document.getElementById("result1").disabled = false;
        }
        else if($(this).prop("checked") == false){
            i=i-1
            if(i==0){

            document.getElementById("result1").disabled = true;
            }
        }
    });
});

$(document).ready(function(){
	var i=0;
    $('input[type="checkbox"]').click(function(){
        if($(this).prop("checked") == true){
            i=i+1
            document.getElementById("result").disabled = false;
        }
        else if($(this).prop("checked") == false){
            i=i-1
            if(i==0){
            document.getElementById("result").disabled = true;
            }
        }
    });
});

$(document).ready(function(){

    $("[id*=NotesBtn]").click(function(){
        hash= $(this).data('hash');
        var drug= $(this).data('drug');
        var con= $(this).data('con');
        note= $(this).data('note');

        $("#shinyModal_notes").val( note ) ;
        $("#label_shiny_note").text(note);
    });


    $(".note_chkb").on("change", function(){

        if($(this).is(':checked') && !(hash in all_notes)){
            // console.log(note)
            // console.log(hash)
            all_notes[hash]=note;
            // console.log(all_notes);
        }else if(!$(this).is(':checked') && (hash in all_notes)){
            delete all_notes[hash];
            // console.log(all_notes);
        }
    });

    $("#shinyModal_notes").on('show.bs.modal', function (){
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
});
