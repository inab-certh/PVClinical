from django.utils.translation import gettext_lazy as _


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
    if not obj.pk:
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
        return list(map(lambda el: {"text": el}, children))

    return [{"text": ch, "nodes": get_atc_children(ch, level+1, codes)} for ch in children]


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



