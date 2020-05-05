import json
from django.utils.translation import gettext_lazy as _
from django.shortcuts import HttpResponse


def is_in_group(user, group):
    """ Check whether a user belongs to a specific group or not
    :param user: the user we want to check about
    :param group: the group the user might belong to
    :return: True if user exists and belongs to specific group, False otherwise
    """

    if user:
        return user.groups.filter(name=group)
    return False


def is_doctor(user):
    """ Check if user is a doctor
    :param user: the user we want to check about
    :return: True or False
    """
    return is_in_group(user, "Doctor")


def is_nurse(user):
    """ Check if user is a nurse
    :param user: the user we want to check about
    :return: True or False
    """
    return is_in_group(user, "Nurse")


def is_pv_expert(user):
    """ Check if user is a PV EXpert
    :param user: the user we want to check about
    :return: True or False
    """
    return is_in_group(user, "PV Expert")


def sorted_choices(choices_tpl):
    """ Returns choices_tpl sorted alphabetically
    """
    return sorted(choices_tpl, key=lambda el: el[1])


def str_upper(s):
    """ Strings (greek inclusive) to uppercase
    """

    gr_extra_trans = s.maketrans("ΆΈΉΊΌΎΏ", "ΑΕΗΙΟΥΩ")
    return s.upper().translate(gr_extra_trans)


def choices_max_length(tpl):
    """ Get the length of the longest (as string) choice in tpl
    """
    lst = dict(tpl).keys()
    return len(max(lst, key=len))


def delete_db_rec(obj):
    """ Delete object from db
    """
    if not hasattr(obj, "id") or not obj.id:
        resp_status = 404
        resp_message = _("Δυστυχώς η διαγραφή αυτή, δεν ήταν δυνατόν να ολοκληρωθεί!"
                         " Δεν υπάρχει η αντίστοιχη καταχώριση ακόμη στο σύστημα!")
    else:
        deleted = obj.delete()
        if deleted and deleted[0]:
            resp_status = 200
            resp_message = _("Η διαγραφή ολοκληρώθηκε επιτυχώς!")

        else:
            resp_status = 400
            resp_message = _("Δυστυχώς η διαγραφή αυτή, δεν ήταν δυνατόν να ολοκληρωθεί!")

    return HttpResponse(content=resp_message,
                        status=resp_status)


def atc_by_level(level, codes):
    """ Return all drugs' code (atc) part by the specified level
    :param level: the level of the (atc) code to be retrieved
    :param codes: the drug (atc) codes
    :return: code (atc) part specified by the level
    """

    level_chars = {1: 1, 2: 3, 3: 4, 4: 5, 5: 7}
    return sorted(set([code[0:level_chars[level]] for code in codes]))


def get_atc_children(parent, level, codes):
    """ Recursively get children (from next ATC level) for each level's parent
    :param parent: the parent node
    :param level: the ATC level of the parent
    :param codes: the last ATC level children
    :return: next ATC level children
    """
    children = list(set(filter(lambda el: el.startswith(parent), atc_by_level(level+1, codes))))
    # print(children)

    if level==4:
        return sorted(list(map(lambda el: {"text": el}, children)), key = lambda v: v["text"])

    return sorted([{"text": ch,
                    "nodes": get_atc_children(ch, level+1, codes)} for ch in children],
                  key = lambda v: v["text"])


def atc_hierarchy_tree(codes):
    """ Create the ATC hierarchy tree from the ATC codes (of drugs) given
    :param codes:  the ATC codes of drugs
    :return: the ATC tree
    """
    atc_tree = []

    levels = [atc_by_level(i+1, codes) for i in range(0, 5)]

    # Append to/create the ATC tree for the specific codes (of drugs) we have
    for root in levels[0]:
        atc_tree.append({"text": root, "nodes": get_atc_children(root, 1, codes)})

    return atc_tree


# def medDRA_flat_tree(conditions):
#     """ Create the flat tree of all nodes with every node containing its parents
#     :param conditions: all the possible conditions
#     :return: all condition nodes in proper format, containing the data about their parents
#     """
#     condition_type_level = {"soc": 1,
#                             "hlgt": 2,
#                             "hlt": 3,
#                             "pt": 4,
#                             "llt": 5}
#
#     # Children level to parent type for filtering conditions to get children of current level and parent
#     # On level 6 there is not parent, it's just used for icons
#     parent_types = {2: "soc", 3: "hlgt", 4: "hlt", 5: "pt", 6: "llt"}
#
#     # Enabled nodes by level type
#     enabled_level_types = ["pt",
#                            "llt"]
#
#     nodes = [{"id": "{}___{}".format(c.code, parent_types.get(condition_type_level.get(c.type)+1)),
#               "text": "{} - {}".format(c.name, c.code),
#               "icon": parent_types.get(condition_type_level.get(c.type)+1),
#               "state": {"disabled": c.type not in enabled_level_types},
#               "parent": "{}___{}".format(
#                   getattr(c, parent_types.get(condition_type_level.get(c.type))),
#                   parent_types.get(condition_type_level.get(c.type)))
#               if condition_type_level.get(c.type)!=1 else "#"
#               } for c in sorted(conditions, key=lambda x: x.name)]
#
#     return nodes

def medDRA_flat_tree(conditions):
    """ Create the flat tree of all nodes with every node containing its parents
    :param conditions: all the possible conditions
    :return: all condition nodes in proper format, containing the data about their parents
    """
    # Type to parent type (for tree)
    # type_2_ptype = {"soc": None,
    #                 "hlgt": "soc",
    #                 "hlt": "hlgt",
    #                 "pt": "hlt",
    #                 "llt": "pt"}
    #
    # type_2_code = dict([((c.type, c.code), c.anc_lvl1) for c in conditions])

    # Enabled nodes by level type
    enabled_level_types = ["pt", "llt"]

    nodes = [{"id": c.id,
              "text": "{} - {}".format(c.name, c.code),
              "icon": c.type,
              "state": {"disabled": c.type not in enabled_level_types},
              "parent": c.parent if c.type!="soc" else "#"
              # "parent": "{}___{}___{}".format(
              #     c.anc_lvl1,
              #     type_2_ptype.get(c.type),
              #     type_2_code.get((type_2_ptype.get(c.type), c.anc_lvl1))
              #     # ([""]+list(filter(
              #     #     lambda cond: cond.code == c.anc_lvl1 and cond.type == type_2_ptype.get(c.type),
              #     #     conditions))).pop().parent
              # ).strip("_") if c.type!="soc" else "#"
              } for c in sorted(conditions, key=lambda x: x.name)]

    with open("taratatzoym_nodes.json", "w") as fp:
        json.dump(nodes, fp)

    return nodes


# def medDRA_flat_tree(conditions):
#     """ Create the flat tree of all nodes with every node containing its parents
#     :param conditions: all the possible conditions
#     :return: all condition nodes in proper format, containing the data about their parents
#     """
#     condition_type_level = {"https://w3id.org/phuse/meddra#SystemOrganClassConcept": 1,
#                             "https://w3id.org/phuse/meddra#HighLevelGroupConcept": 2,
#                             "https://w3id.org/phuse/meddra#HighLevelConcept": 3,
#                             "https://w3id.org/phuse/meddra#PreferredConcept": 4,
#                             "https://w3id.org/phuse/meddra#LowLevelConcept": 5}
#
#     # Children level to parent type for filtering conditions to get children of current level and parent
#     # On level 6 there is not parent, it's just used for icons
#     parent_types = {2: "soc", 3: "hlgt", 4: "hlt", 5: "pt", 6: "llt"}
#
#     # Enabled nodes by level type
#     enabled_level_types = ["https://w3id.org/phuse/meddra#PreferredConcept",
#                            "https://w3id.org/phuse/meddra#LowLevelConcept"]
#
#     nodes = [{"id": "{}___{}".format(c.code, parent_types.get(condition_type_level.get(c.type)+1)),
#               "text": "{} - {}".format(c.name, c.code),
#               "icon": parent_types.get(condition_type_level.get(c.type)+1),
#               "state": {"disabled": c.type not in enabled_level_types},
#               "parent": "{}___{}".format(
#                   getattr(c, parent_types.get(condition_type_level.get(c.type))).replace(
#                       "https://w3id.org/phuse/meddra#m", ""),
#                   parent_types.get(condition_type_level.get(c.type)))
#               if condition_type_level.get(c.type)!=1 else "#"
#               } for c in sorted(conditions, key=lambda x: x.name)]
#
#     return nodes
