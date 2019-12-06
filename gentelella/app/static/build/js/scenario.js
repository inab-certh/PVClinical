$(function() {
    $("[name='drugs_fld']").change(function () {
            var selected_drugs = $(this).val().map(function (drug) {
                return drug.split(' - ').shift();
            });

            $.ajax({
                url: $("#drugsNameCollapsible").attr("data-synonyms-url"),
                data: {"drugs": JSON.stringify(selected_drugs)},
                dataType: 'json',
                success: function (data) {
                    var options_arr = [];

                    // var selected_drugs = $("[name='drugs_fld']").find(":selected").map(function () {
                    //     return $(this).val().split(' - ').shift();
                    // }).toArray();


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
                var all_drugs = $("[name='drugs_fld'] option").map(function () {
                        return $(this).val()}).toArray();

                // Add parent node in children_nodes_list
                var candidate_nodes = children_nodes;
                candidate_nodes.push(node.nodeId);

                // Selected node(s) at the last level atc code hierarchy, 7 digits value
                var selected_atcs_ids = candidate_nodes.filter(function (nodeId) {
                    return $("#atcTree").treeview('getNode', nodeId).text.length == 7;
                });

                var selected_atcs = selected_atcs_ids.map(function (nodeId) {
                    return $("#atcTree").treeview('getNode', nodeId).text
                });

                var selected_drugs_by_atc = all_drugs.filter(function (drug) {
                    return selected_atcs.indexOf(drug.split(' - ').pop()) != -1;
                });

                // Append selected drugs to drugs_fld box
                var all_selected_drugs = $("[name='drugs_fld']").val()==null?[]:$("[name='drugs_fld']").val();
                all_selected_drugs = all_selected_drugs.concat(selected_drugs_by_atc.filter((item) => all_selected_drugs.indexOf(item) == -1));

                $("[name='drugs_fld']").val(all_selected_drugs).trigger("change");

            },
            onNodeUnchecked: function (event, node) {
                var children_nodes = _.map(_getChildren(node), 'nodeId');
                $(this).treeview('uncheckNode', [children_nodes, {silent: true}]);

            }
        });

        // $("#atcTree").click(function () {
        //     var nodes = $("#atcTree").dataSource.view();
        //     console.log(nodes);
        // });


    });

function moveToSelectedDrugs() {
    var checked_synonyms = $("#drugsSynonyms option:selected").map(function () {
        return $(this).val();
    }).toArray();

    // Move checked synonyms to selected drugs list
    var all_drugs = $("[name='drugs_fld'] option").map(function () {
        return $(this).val()
    }).toArray();

    var selected_synonyms = all_drugs.filter(function (drug) {
        return checked_synonyms.indexOf(drug.split(' - ').shift()) != -1;
    });

    var all_selected_drugs = $("[name='drugs_fld']").val();
    var all_selected_drugs = all_selected_drugs.concat(selected_synonyms.filter((item) => all_selected_drugs.indexOf(item) == -1));
    $("[name='drugs_fld']").val(all_selected_drugs).trigger("change");
}