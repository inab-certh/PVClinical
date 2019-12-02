$(function() {
    $("[name='drugs_fld']").change(function () {
            var all_drugs = $(this).val().map(function (drug) {

                return drug.split(' - ').shift();
            });

            $.ajax({
                url: $("#drugsNameCollapsible").attr("data-synonyms-url"),
                data: {"drugs": JSON.stringify(all_drugs)},
                dataType: 'json',
                success: function (data) {
                    var options_arr = [];

                    var selected_drugs = $("[name='drugs_fld']").find(":selected").map(function () {
                        return $(this).val().split(' - ').shift();
                    }).toArray();

                    console.log(selected_drugs);

                    // Remove common values in synonyms and selected drugs from synonyms array
                    var valid_synonyms = data.synonyms.filter(function(val) {
                        return selected_drugs.indexOf(val) == -1;
                    });

                    valid_synonyms.forEach(function (syn, index, valid_synonyms) {
                        options_arr.push(new Option(syn, syn))
                    });

                    // Change synonyms and send trigger
                    $("#drugsSynonyms").html(options_arr).trigger("change");

                  },
                  error: function (data) {
                    console.log("error "+data);
                }

            });
        });
        //
        // });

        $("#drugsSynonyms").select2MultiCheckboxes({

            templateSelection: function(selected, total) {
                return gettext("Επιλέξατε ")+selected.length+gettext(" από ")+total+gettext(" συνώνυμα");
            }
        });




    });

function moveToSelectedDrugs() {
    var checked_synonyms = Array.from($("#drugsSynonyms option:selected"));

    // Move checked synonyms to selected drugs list
    checked_synonyms.forEach( ch => {
        var $option = $("<option selected></option>").val(ch.value).text(ch.value);
        $("[name='drugs_fld']").append($option).trigger("change");
    })
}