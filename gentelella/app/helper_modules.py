import requests

from django.utils.translation import gettext_lazy as _
from django.shortcuts import HttpResponse

from bs4 import BeautifulSoup


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

    # Show checkboxes only for level 4 and 5 of ATCs
    if level==4:
        return sorted(list(map(lambda el: {"text": el, "hideCheckbox": False, "selectable": True},
                               children)), key = lambda v: v["text"])

    return sorted([{"text": ch,
                    "selectable": level==3,
                    "hideCheckbox": level!=3,
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
        atc_tree.append({"text": root, "selectable": False, "hideCheckbox": True,
                         "nodes": get_atc_children(root, 1, codes)})

    return atc_tree


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

    # with open("taratatzoym_nodes.json", "w") as fp:
    #     json.dump(nodes, fp)

    return nodes


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
    children = list(filter(lambda c: c.type == level_condition_type[level] and\
                                     getattr(c, parent_types[level]).replace("https://w3id.org/phuse/meddra#m", "")\
                                     == parent.code, conditions))

    children = list(set(children))

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

#Returns the PMCID code from MubMed papers

def getPMCID(handle):
    """ With a second query search PMC library for the PMCID of the papers.
    :param handle: the response from PMC library
    :return: PMCID if exists
    """
    html_response = handle.read()

    soup = BeautifulSoup(html_response)
    for script in soup(["script", "style"]):
        script.extract()
    text = soup.get_text()
    lines = (line.strip() for line in text.splitlines())
    # break multi-headlines into a line each
    chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
    # drop blank lines
    text = '\n'.join(chunk for chunk in chunks if chunk)
    listtxt = text.split('\n')
    if 'pubmed_pmc' in listtxt:
        pmcid = listtxt[-1]
    else:
        pmcid = " "
    return pmcid


def mendeley_pdf(access_token, title):
    """ Search for the pdf of the results papers in user's Mendeley library.
    :param access_token: user's access token
    :param title: title of the search paper
    :return: pdf link to mendeley library
    """
    access_token = access_token
    response_doc = requests.get(
        'https://api.mendeley.com/documents',
        params={'title': title},
        headers={'Authorization': 'Bearer {}'.format(access_token),
                 'Accept': 'application/vnd.mendeley-document.1+json'},
    )

    document_id = []
    doc = response_doc.json()
    for item in doc:
        document_id = item['id']
        response_file = requests.get(
            'https://api.mendeley.com/files',
            params={'document_id': document_id},
            headers={'Authorization': 'Bearer {}'.format(access_token),
                     'Accept': 'application/vnd.mendeley-file.1+json'},
        )
        file = response_file.json()
        for item in file:
            file_id = item['id']

        mendeley_pdf = 'https://www.mendeley.com/reference-manager/reader/' + document_id + '/' + file_id

        return mendeley_pdf


def sort_report_screenshots(ss_lst):
    """ Sorting report screenshots according to our needs
    :param ss_lst: the screenshots' list
    :return: the sorted list
    """

    # The list should be ordered according to specific beginning of words
    beginning_order_lst = ["irtable_", "irall_", "charlson_table_", "charlson_chart_", "demograph_table_",
                           "demograph_chart_", "drug_table_", "drug_chart_", "gen_table_", "gen_chart_", "pre_table_",
                           "pre_chart_", "pw_"]

    return sorted(ss_lst, key=lambda x: int("".join(
        map(lambda el: str(el[0]) if x.startswith(el[1]) else "", enumerate(beginning_order_lst)))))
