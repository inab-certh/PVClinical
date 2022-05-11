$(function() {
    var languages = {"Greek": "el", "English": "en"};

    var all_drugs = get_all_drugs();

    $(".customselect2tagwidget[name='drugs_fld'], .customselect2tagwidget[name='conditions_fld']").select2({
        language: languages[$("#curLang").attr("data-lang")],
        allowClear: true,
        minimumInputLength: 2,
        ajax: {
            url: "/ajax/filter-whole-set",
            dataType: "json",
            type: "GET",
            quietMillis: 50,
            data: function(params) {
                return {
                    type: $(this).attr("name").replace("_fld",""),
                    term: params.term,
                    page: params.page
                };
            },
            processResults: function (data, params) {
                params.page = params.page || 1;
                page_size = 7;

                return {
                    results: data.results.slice((params.page - 1) * page_size, params.page * page_size),
                    pagination: {
                      more: (params.page * page_size) < data.total_count
                    }

                // return {
                //     results: data.results
                };
            },
            cache: true
        }
    });


    $("[name='drugs_fld']").change(function () {
        $("#loaderOverlay").fadeIn();
        var selected = $(this).val();

        if(selected===null) {
            $("#atcTree").treeview('uncheckAll', {silent: true});
        }

        var selected_drugs = selected != null?selected.map(function (drug) {
            return drug.split(' - ').shift();
        }):[];

        var selected_atcs = selected != null?selected.map(function (drug) {
            return drug.split(' - ').pop();
        }):[];

        // Find checked atcs which are not in the drugs_fld, and uncheck them
        var checked_atcs = $("#atcTree").treeview('getChecked');
        var atcs_to_uncheck = checked_atcs.filter(function (ch_atc) {
            return ch_atc.text.length==7 && selected_atcs.indexOf(ch_atc.text) == -1;
        });

        if(atcs_to_uncheck.length!==0) {
            $("#atcTree").treeview('uncheckNode', [atcs_to_uncheck]);
        }

        var nodes_to_check = $("#atcTree").treeview("getNodes").filter(function (node) {
                return (selected_atcs.indexOf(node.text) != -1);
        });

        $("#atcTree").treeview('checkNode', [nodes_to_check, {silent: true}]);

        $("#atcTree").treeview('revealNode', [nodes_to_check, {silent: true}]);

        $.ajax({
            url: $("#drugsNameCollapsible").attr("data-synonyms-url"),
            data: {"drugs": JSON.stringify(selected_drugs)},
            dataType: "json",
            success: function (data) {
                var options_arr = [];

                // Remove common values in synonyms and selected drugs from synonyms array
                var valid_synonyms = data.synonyms.filter(function(val) {
                    return selected_drugs.indexOf(val) == -1;
                });

                valid_synonyms.forEach(function (syn, index, valid_synonyms) {
                    options_arr.push(new Option(syn, syn));
                });


                // Change synonyms and send trigger
                $("#drugsSynonyms").html(options_arr).trigger("change");
              },
              error: function (data) {
                console.log("error "+data);
            }
        });
        $("#loaderOverlay").fadeOut();
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
        var ancestors = [];
        while (node.parentId!=undefined) {
            var parent = $("#atcTree").treeview("getNodes").filter(function (cnode) {
                return node.parentId ===  cnode.nodeId;
            })[0];
            // var parent = $("#atcTree").treeview("findNodes", ["^"+node.parentId+"$", "nodeId"])[0];
            if(parent.selectable) {
                ancestors.push(parent);
            }
            node = parent;

        }
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
            var children_nodes = _getChildren(node);
            var check_nodes = [];

            check_nodes = check_nodes.concat(children_nodes);

            var siblings = $("#atcTree").treeview('getSiblings', [node, {silent: true}]);
            var checked_siblings = siblings.length!==0?siblings.filter(function (s) {
                return s.state.checked;
            }):[];

            if(siblings.length === checked_siblings.length) {
                if(node.parentId!=undefined){
                    var par = $("#atcTree").treeview("findNodes", ["^"+node.parentId+"$", "nodeId"])[0];
                    if(par.selectable === true){
                        check_nodes.push(par);
                    }

                }
            }

            // Some are already checked, so just check the ones not already checked
            var to_be_checked = check_nodes.length!==0?check_nodes.filter(function (n) {
                return !n.state.checked;
            }):[];
            if(to_be_checked.length!==0) {
                $("#atcTree").treeview('checkNode', [to_be_checked, {silent: true}]);
            }

            /* Get only whole atc codes checked, find equivalent drugs and transfer
            those drugs to drugs' select2 box as selected drugs
             */
            // var all_drugs = $("[name='drugs_fld'] option").map(function () {
            //         return $(this).val()}).toArray();

            // Add parent node in children_nodes_list
            var candidate_nodes = children_nodes.map(function (node){
                return node.nodeId;
            });
            candidate_nodes.push(node.nodeId);

            // Selected node(s) at the last level atc code hierarchy, 7 digits value
            var selected_atcs_ids = candidate_nodes.filter(function (nodeId) {
                var all_nodes = $("#atcTree").treeview("getNodes");
                // return $("#atcTree").treeview("findNodes", ["^"+nodeId+"$","nodeId"])[0].text.length == 7;
                return all_nodes.filter(function (node){
                    return node.nodeId === nodeId && node.text.length === 7;
                });
                // return $("#atcTree").treeview("findNodes", ["^"+nodeId+"$","nodeId"])[0].text.length == 7;
            });

            var selected_atcs = selected_atcs_ids.map(function (nodeId) {
                var all_nodes = $("#atcTree").treeview("getNodes");
                return all_nodes.filter(function (node){
                    return node.nodeId === nodeId;
                })[0].text;
                // return $("#atcTree").treeview("findNodes", ["^"+nodeId+"$", "nodeId"])[0].text;
            });

            var selected_drugs_by_atc = all_drugs.filter(function (drug) {
                return selected_atcs.indexOf(drug.split(' - ').pop()) != -1;
            });


            // Append selected drugs to drugs_fld box
            var all_selected_drugs = $("[name='drugs_fld']").val()==null?[]:$("[name='drugs_fld']").val();
            all_selected_drugs = all_selected_drugs.concat(selected_drugs_by_atc.filter((item) => all_selected_drugs.indexOf(item) == -1));


            /* Mechanism to update options in drugs' select2 element with values selected
            from tree view
             */
            $("[name='drugs_fld']").empty();
            for(i=0;i<all_selected_drugs.length;i++){
                var data = {
                    id: all_selected_drugs[i],
                    text: all_selected_drugs[i]
                };

                var newOption = new Option(data.text, data.id, false, false);
                $("[name='drugs_fld']").append(newOption);

            }

            $("[name='drugs_fld']").val(all_selected_drugs).trigger("change");
        },
        onNodeUnchecked: function (event, node) {
            // $("#atcTree").treeview('uncheckNode', [children_nodes, {silent: true}]);
            var uncheck_nodes = _getChildren(node);
            var ancestors = _getAncestors(node);

            // Some ancestors might already be unchecked
            uncheck_nodes = uncheck_nodes.concat(ancestors.length!==0?ancestors.filter(function (a) {
                return a.state.checked;
            }):[]);

            // Some to_be_unchecked nodes might already be unchecked
            uncheck_nodes = uncheck_nodes.length!==0?uncheck_nodes.filter(function (n) {
                return n.state.checked;
            }):[];

            $("#atcTree").treeview('uncheckNode', [uncheck_nodes, {silent: true}]);

            // Append selected drugs to drugs_fld box
            var selected_fld_drugs = $("[name='drugs_fld']").val()==null?[]:$("[name='drugs_fld']").val();
            selected_fld_drugs = selected_fld_drugs.filter(function (drug) {
                return drug.indexOf(node.text) === -1;
            });

            $("[name='drugs_fld']").val(selected_fld_drugs).trigger("change");

        }
    });

    // A fake change trigger to initialize form
    $("[name='drugs_fld']").trigger("change");

    var medDRA_tree = get_medDRA_tree();

    var refresh = true;
    $("#loaderOverlay").fadeIn();
    $("#medDRATree").jstree({
        "core": {
            "multiple": true,
            "data": medDRA_tree
        },

        "plugins": ["search", "checkbox"],
        "search": {
                    "case_sensitive": false,
                    "show_only_matches": false
                }
    })
        .bind("ready.jstree", function (event, data) {
            var init_sel_conditions = get_conditions_ids($("[name='conditions_fld']").val());
            init_sel_conditions = init_sel_conditions?init_sel_conditions:[];
            check_open_leaves(init_sel_conditions);
            $("#loaderOverlay").fadeOut();
        });

    var cur_sel_conditions = [];

    $("[name='conditions_fld']").change(function () {

        var sel_conditions = $(this).val();
        var prev_sel_conditions = cur_sel_conditions;

        cur_sel_conditions = get_conditions_ids(sel_conditions);

        // Find differences in the selected conditions and deselect the ones
        // that do not exist anymore
        var desel_conditions = prev_sel_conditions.filter(
            x => cur_sel_conditions.indexOf(x) === -1);

        var new_sel_conditions = cur_sel_conditions.filter(
            x => prev_sel_conditions.indexOf(x) === -1);

        // $("#medDRATree").jstree("deselect_node", desel_conditions);
        uncheck_close_leaves(desel_conditions);
        check_open_leaves(new_sel_conditions);
    });

    $('#medDRATree')
      // listen for event
    .on('changed.jstree', function (e, data) {

        $("#loaderOverlay").fadeIn();
        var i, j, r = [];

        if (refresh) {
            for(i = 0, j = data.selected.length; i < j; i++) {
                var node_txt = data.instance.get_node(data.selected[i]).text;
                if(r.indexOf(node_txt) === -1){
                    r.push(node_txt);

                    if($("option:contains('"+node_txt+"')").length===0) {
                        $("[name='conditions_fld']").append(
                            "<option id=\""+node_txt+"\">"+node_txt+"</option>");
                    }

                }
            }

            $("[name='conditions_fld']").val(r).trigger("change");

        }

        $("#loaderOverlay").fadeOut();


      })
      // create the instance
      .jstree();


    function get_all_drugs() {
        /* Make an ajax call using all-drugs python callback
        to retrieve all drugs */
        var drugs=[];
        $.ajax({
            url: "/ajax/all-drugs",
            type: "GET",
            dataType: "json",
            async: false
        }).done(function(data) {
            drugs = data.drugs;
        }).fail(function () {
            drugs = [];
        });
        return drugs;
    }

    function get_medDRA_tree() {
        /* Make an ajax call using medDRA-tree python callback
        to retrieve all drugs */
        var medDRA_tree=[];
        $.ajax({
            url: "/ajax/medDRA-tree",
            type: "GET",
            dataType: "json",
            async: false
        }).done(function(data) {
            medDRA_tree = data.medDRA_tree;
        }).fail(function () {
            medDRA_tree = [];
        });
        return medDRA_tree;
    }

    function get_conditions_ids(conditions) {
        /* Make an ajax call using conds-nodes-ids python callback
        to retrieve all drugs */
        var conds_nodes_ids=[];

        // $("#loaderOverlay").fadeIn();

        conditions = conditions?conditions:[];

        $.ajax({
            // beforesend: function(){
            //     $("#loaderOverlay").fadeIn();
            // },
            // complete: function(){
            //     $("#loaderOverlay").fadeOut();
            // },
            url: "/ajax/conds-nodes-ids",
            data: {"conditions": JSON.stringify(conditions)},
            type: "GET",
            dataType: "json",
            async: false
        }).done(function(data) {
            conds_nodes_ids = data.conds_nodes_ids;
        }).fail(function () {
            conds_nodes_ids = [];
        });
        return conds_nodes_ids;
    }

    // Function to check leaves and open the whole paths to those leaves
    function check_open_leaves(sel_conditions) {
        // sel_conditions.sort();
        refresh = false;
        // $("medDRATree").jstree("select_node", sel_conditions, false, false);
        for (var i = 0; i < sel_conditions.length; i++) {
            if(i==sel_conditions.length-1){
                refresh = true;
            }
            $("#medDRATree").jstree("check_node", sel_conditions[i]);
            $("#medDRATree").jstree()._open_to(sel_conditions[i]);
        }
        refresh = true;
    }

    // Function to uncheck leaves and close the whole paths to those leaves
    function uncheck_close_leaves(desel_conditions) {
        // sel_conditions.sort();
        refresh = false;
        // $("medDRATree").jstree("select_node", sel_conditions, false, false);
        for (var i = 0; i < desel_conditions.length; i++) {
            if(i==desel_conditions.length-1){
                refresh = true;
            }
            $("#medDRATree").jstree("uncheck_node", desel_conditions[i]);
            $("#medDRATree").jstree("close_node", desel_conditions[i]);
        }
        refresh = true;
    }

});

function move_to_selected_drugs() {
    var checked_synonyms = $("#drugsSynonyms option:selected").map(function () {
        return $(this).val();
    }).toArray();

    // Move checked synonyms to selected drugs list
    var all_drugs = $("[name='drugs_fld'] option").map(function () {
        return $(this).val();
    }).toArray();

    var all_selected_drugs = $("[name='drugs_fld']").val();

    var all_selected_drugs = all_selected_drugs.concat(checked_synonyms);

    var options_arr = [];

    // Get all options from drug field and concantenate with selected synonyms
    all_selected_drugs.forEach(function (all_opts, index) {
        options_arr.push(new Option(all_opts, all_opts))
    });


    // Change/update drug options and send trigger
    $("[name='drugs_fld']").html(options_arr).trigger("change");

    // var all_selected_drugs = all_selected_drugs.concat(selected_synonyms.filter((item) => all_selected_drugs.indexOf(item) == -1));
    $("[name='drugs_fld']").val(all_selected_drugs).trigger("change");
}
