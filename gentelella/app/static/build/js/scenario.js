$(function() {
    $("[name='drugs_fld']").change(function () {
        $('#atcTree').treeview('collapseAll', {silent: true});
        // $('#atcTree').treeview('uncheckAll', {silent: true});
        var selected = $(this).val();


        if(selected===null) {
            $('#atcTree').treeview('uncheckAll', {silent: true});
        }

        var selected_drugs = selected != null?selected.map(function (drug) {
            return drug.split(' - ').shift();
        }):[];

        var selected_atcs = selected != null?selected.map(function (drug) {
            return drug.split(' - ').pop();
        }):[];

        // Find checked atcs which are not in the drugs_fld, and uncheck them
        var checked_atcs = $("#atcTree").treeview('getChecked');
        if(checked_atcs.length > selected_atcs.length){
            console.log("Okie");
            // var uncheck_nodes = checked_atcs.filter(function (ch_atc) {
            // return selected_atcs.indexOf(ch_atc.text);
            // });

            // $("#atcTree").treeview('uncheckNode', [uncheck_nodes, {silent: true}]);

        }



        // var all_children = $("li.node-atcTree").map(function () {
        //     var root = $("#atcTree").treeview('getNode', $(this).data("nodeid"));
        //     return _getChildren(root)
        // });
        //
        // console.log(all_children);
        //
        // var nodes_to_check = all_children.filter(function (node) {
        //     // console.log(node);
        //     return (selected_atcs.indexOf(node.text) != -1);
        // }).toArray();

        var nodes_to_check = $("li.node-atcTree").map(function () {
            var root = $("#atcTree").treeview('getNode', $(this).data("nodeid"));
            return _getChildren(root).filter(function (node) {
                return (selected_atcs.indexOf(node.text) != -1);
            });
        }).toArray();


        // console.log(selected_atcs, nodes_to_uncheck)

        // var nodes_to_uncheck = all_children.filter(function (indx, node) {
        //     return (selected_atcs.indexOf(node.text) == -1);
        // }).toArray();



        //
        // var nodes_to_check = $("li.node-atcTree").map(function () {
        //     var root = $("#atcTree").treeview('getNode', $(this).data("nodeid"));
        //     return _getChildren(root).filter(function (node) {
        //         return (selected_atcs.indexOf(node.text)  != -1);
        //     });
        // }).toArray();

        var more_to_check = []
        nodes_to_check.forEach(function (node_to_check) {
            // $("#atcTree").treeview('checkNode', [node_to_check, {silent: true}]);

            var siblings = $("#atcTree").treeview('getSiblings', [node_to_check, {silent: true}]);
            var checked_siblings = siblings.filter(function (s) {
                return s.state.checked == true;
            });

            var ancestors = _getAncestors(node_to_check);

            // If all siblings of the same level are checked, then check ancestors too
            if(siblings.length == checked_siblings.length) {
                console.log(node_to_check);
                ancestors.forEach(function (ancestor) {
                    more_to_check.push(ancestor);
                })

                // $("#atcTree").treeview('checkNode', [ancestors])

            }

            // $("#atcTree").treeview('revealNode', [node_to_check, {silent: true}]);

        });

        console.log(more_to_check);

        $("#atcTree").treeview('checkNode', [nodes_to_check, {silent: true}]);
        $("#atcTree").treeview('checkNode', [more_to_check]);
        $("#atcTree").treeview('revealNode', [nodes_to_check, {silent: true}]);


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

    function _getAncestors(node) {
        // If there is no parent, return empty array
        if (node.parentId === undefined) return [];

        var parent = node //$("#atcTree").treeview('getParent', [node.parentId, {silent: true}]);
        var ancestors = [];

        while (parent.parentId) {
            var siblings = $("#atcTree").treeview('getSiblings', [parent, {silent: true}]);
            var checked_siblings = siblings.filter(function (s) {
                return s.state.checked == true;
            });
            parent = $("#atcTree").treeview('getParent', [parent.parentId, {silent: true}]);
            if(siblings.length === checked_siblings.length) {
                ancestors.push(parent);
            }

        };

        return ancestors;
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
            $(this).treeview('checkNode', [children_nodes]);

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

            // Append selected drugs to drugs_fld box
            var selected_fld_drugs = $("[name='drugs_fld']").val()==null?[]:$("[name='drugs_fld']").val();
            selected_fld_drugs = selected_fld_drugs.filter(function (drug) {
                return drug.indexOf(node.text) == -1;
            });

            $("[name='drugs_fld']").val(selected_fld_drugs).trigger("change");


            // console.log(selected_fld_drugs)


            // Append selected drugs to drugs_fld box
            // var all_selected_drugs = $("[name='drugs_fld']").val()==null?[]:$("[name='drugs_fld']").val();
            // all_selected_drugs = all_selected_drugs.concat(selected_drugs_by_atc.filter((item) => all_selected_drugs.indexOf(item) == -1));

        }
    });


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