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


        var atc_tree = JSON.parse($("#atcTree").text());


        function _getChildren(node) {
            if (node.nodes === undefined) return [];
            var childrenNodes = node.nodes;
            node.nodes.forEach(function(n) {
                childrenNodes = childrenNodes.concat(_getChildren(n));
            });
            return childrenNodes;
        }

        $("#atcTree").treeview({
            data: atc_tree,
            levels: 1,

            // custom icons
            expandIcon: 'glyphicon glyphicon-plus',
            collapseIcon: 'glyphicon glyphicon-minus',
            emptyIcon: 'glyphicon',
            nodeIcon: '',
            selectedIcon: '',
            checkedIcon: 'glyphicon glyphicon-check',
            uncheckedIcon: 'glyphicon glyphicon-unchecked',

            // colors
            color: undefined, // '#000000',
            backColor: undefined, // '#FFFFFF',
            borderColor: undefined, // '#dddddd',
            onhoverColor: '#F5F5F5',
            selectedColor: '#FFFFFF',
            selectedBackColor: '#428bca',
            searchResultColor: '#D9534F',
            searchResultBackColor: undefined, //'#FFFFFF',

            // enables links
            enableLinks: false,

            // highlights selected items
            highlightSelected: true,

            // highlights search results
            highlightSearchResults: true,

            // shows borders
            showBorder: true,

            // shows icons
            showIcon: true,

            // shows checkboxes
            showCheckbox: true,

            // shows tags
            showTags: false,

            // enables multi select
            multiSelect: true,

            onNodeChecked: function (event, node) {
                var children_nodes = _.map(_getChildren(node), 'nodeId');
                $(this).treeview('checkNode', [children_nodes, {silent: true}]);

                /* Get only whole atc codes checked, find equivalent drugs and transfer
                those drugs to drugs' select2 box as selected drugs
                 */
                var all_drugs = $("[name='drugs_fld']").val();

                var tree_selected_drugs = children_nodes.grep(function (val) {
                    return all_drugs.find(val) != -1;
                });
                var all_drugs_names= all_drugs.map(function (drug) {
                    return drug.split(' - ').shift();
                });

            },
            onNodeUnchecked: function (event, node) {
                var children_nodes = _.map(_getChildren(node), 'nodeId');
                $(this).treeview('uncheckNode', [children_nodes, {silent: true}]);

            }
        });

        $("#atcTree").click(function () {
            var nodes = $("#atcTree").dataSource.view();
            console.log(nodes);
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