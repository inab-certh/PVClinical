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

def get_medDRA_children(parent, level, conditions):
    """ Get children of a specific parent
    :param parent: the parent of the children
    :param level: the medDRA level from which we pick the children (HLGT, HLT, PT, LLT)
    :param conditions: all the conditions to filter in order to get the children
    :return: the children of the specific parent for the current level
    """

    if level not in range(2,6):
        return None

    level_condition_type = {2: "https://w3id.org/phuse/meddra#HighLevelGroupConcept",
                            3: "https://w3id.org/phuse/meddra#HighLevelConcept",
                            4: "https://w3id.org/phuse/meddra#PreferredConcept",
                            5: "https://w3id.org/phuse/meddra#LowLevelConcept"}

    # Children level to parent type for filtering conditions to get children of current level and parent
    # On level 6 there is not parent, it's just used for icons
    parent_types = {2: "soc", 3: "hlgt", 4: "hlt", 5: "pt", 6: "llt"}

    # Retrieve by filtering the conditions by children level type and parent
    children = list(
        filter(lambda c: c.type == level_condition_type[level] and\
                         getattr(c, parent_types[level]).replace("https://w3id.org/phuse/meddra#m", "")\
                         == parent.code, conditions))

    # Last level return from recursion
    if level == 5:
        return sorted(list(map(lambda ch: {"id": "{} - {}___{}".format(ch.name, ch.code, parent_types[level+1]),
                                           "text": "{} - {}".format(ch.name, ch.code),
                                           "icon": "{}".format(parent_types[level+1]),}, children)),
                      key=lambda v: v["text"])

    return sorted([{"id":"{} - {}___{}".format(ch.name, ch.code, parent_types[level+1]),
                    "text": "{} - {}".format(ch.name, ch.code),
                    "icon": "{}".format(parent_types[level+1]),
                    "children": get_medDRA_children(ch, level + 1, conditions)} for ch in children],
                  key=lambda v: v["text"])


def medDRA_hierarchy_tree(conditions):
    medDRA_tree = []
    soc_conditions = list(filter(lambda c: c.type == "https://w3id.org/phuse/meddra#SystemOrganClassConcept",
                                 conditions))

    # Append to/create the medDRA tree for all the soc conditions we have
    for soc_c in soc_conditions:
        medDRA_tree.append({"id":"{} - {}___soc".format(soc_c.name, soc_c.code),
                            "text": "{} - {}".format(soc_c.name, soc_c.code),
                            "icon": "soc",
                            "children": get_medDRA_children(soc_c, 2, conditions)})

    return medDRA_tree
