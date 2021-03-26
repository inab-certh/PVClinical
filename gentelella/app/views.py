import json
import os
import re
import requests

from math import ceil
from itertools import chain
from itertools import product

from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.contrib.auth.decorators import user_passes_test
from django.contrib.auth.models import User
from django.contrib import messages
from django.shortcuts import get_object_or_404
from django.shortcuts import render
from django.template import loader
from django.http import HttpResponse
from django.http import HttpResponseForbidden
from django.http import QueryDict
from django.shortcuts import HttpResponseRedirect
from django.http import JsonResponse
from django.shortcuts import redirect
from django.utils.translation import gettext_lazy as _
from django.urls import reverse

from app import ohdsi_wrappers
from app.errors_redirects import forbidden_redirect
from app.forms import ScenarioForm
from app.forms import IRForm
from app.forms import CharForm
from app.forms import NotesForm
from app.forms import PathwaysForm
from app.helper_modules import atc_hierarchy_tree
from app.helper_modules import is_doctor
from app.helper_modules import is_nurse
from app.helper_modules import is_pv_expert
from app.helper_modules import delete_db_rec
from app.helper_modules import getPMCID
# from app.helper_modules import mendeley_cookies
from app.helper_modules import mendeley_pdf
from app.models import Notes
from app.models import PubMed
from app.models import Scenario
# from app.ohdsi_wrappers import update_ir
# from app.ohdsi_wrappers import create_ir
from app.entrezpy.entrezpylib import conduit
from app.retrieve_meddata import KnowledgeGraphWrapper
from app.pubmed import PubmedAnalyzer

from Bio import Entrez
from mendeley import Mendeley


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def OpenFDAWorkspace(request, scenario_id=None):
    template = loader.get_template('app/OpenFDAWorkspace.html')
    scenario = {}
    sc = Scenario.objects.get(id=scenario_id)
    drugs = [d for d in sc.drugs.all()]
    conditions = [c for c in sc.conditions.all()]
    all_combs = list(product([d.name for d in drugs] or [""],
                             [c.name for c in conditions] or [""]))
    scenario = {"drugs": drugs,
                "conditions": conditions,
                "all_combs": all_combs,
                "owner": sc.owner.username,
                "status": sc.status.status,
                "timestamp": sc.timestamp,
                "sc_id": scenario_id
                }

    return HttpResponse(template.render({"scenario": scenario, "shiny_endpoint": settings.SHINY_ENDPOINT}, request))


def get_synonyms(request):
    """ Get all the synonyms for a list of drugs
    :param request: The request from which the list of drugs to search for synonyms will be retrieved
    :return: The list of synonyms for the drugs' list
    """

    drugs = json.loads(request.GET.get("drugs", None))

    knw = KnowledgeGraphWrapper()
    synonyms = knw.get_synonyms(drugs)

    data={}
    data["synonyms"] = synonyms
    return JsonResponse(data)


def filter_whole_set(request):
    """ Get all drugs or conditions containing the characters given as input
    :param request: The request from which the characters given as input will be retrieved
    :return: The list of drugs or conditions containing the characters given as input
    """

    set_type = request.GET.get("type", None)
    term = request.GET.get("term", None)

    knw = KnowledgeGraphWrapper()

    whole_set = knw.get_drugs() if set_type == "drugs" else knw.get_conditions()
    whole_set = ["{}{}".format(
        el.name, " - {}".format(el.code) if el.code else "") for el in whole_set]
    subset = list(filter(lambda el: term.lower().strip() in el.lower(), whole_set))
    subset = sorted(subset, key=lambda x: 'a' + x if\
        x.lower().startswith(term.lower().strip()) else 'b' + x)

    data={}
    data["results"]=[{"id":elm, "text":elm} for elm in subset]

    return JsonResponse(data)


def get_all_drugs(request):
    """ Get all cached drugs
    :param request:
    :return: all cached drugs
    """
    knw = KnowledgeGraphWrapper()

    all_drugs = knw.get_drugs()
    all_drugs = ["{}{}".format(
        el.name, " - {}".format(el.code) if el.code else "") for el in all_drugs]

    data={}
    data["drugs"] = all_drugs
    return JsonResponse(data)


def get_medDRA_tree(request):
    """ Get the medDRA hierarchy tree
    :param request: The request from which the medDRA tree will be retrieved
    :return: The medDRA hierarchy tree
    """
    knw = KnowledgeGraphWrapper()

    data={}
    data["medDRA_tree"] = knw.get_medDRA_tree()
    return JsonResponse(data)


def get_conditions_nodes_ids(request):
    """ Get the ids of the tree nodes containing the condition we want
    :param request:
    :return: the condition ids containing the ids of the conditions contained in
    the url as parameters
    """

    req_conditions = json.loads(request.GET.get("conditions", None))

    # knw = KnowledgeGraphWrapper()
    # medDRA_tree_str = json.dumps(knw.get_medDRA_tree())
    with open(os.path.join(settings.JSONS_DIR, "medDRA_tree.json")) as fp:
        medDRA_tree_str = fp.read()

    # Find in json string all conditions with ids relevant to conditions' requested
    rel_conds_lst = [list(map(lambda c: c.replace("\",", ""), re.findall(
        "{}___[\S]+?,".format(condition.split(" - ").pop()), medDRA_tree_str))) for condition in req_conditions]
    # print(rel_conds_lst)
    rel_conds_lst = list(chain.from_iterable(rel_conds_lst))
    # all_conditions = knw.get_conditions()
    # rel_conds_lst = [filter(lambda c: c.code == condition.split(" - ").pop(),
    #                         all_conditions) for  condition in req_conditions]
    # rel_conds_lst = list(map(lambda cond: cond.id, chain.from_iterable(rel_conds_lst)))

    data = {}
    data["conds_nodes_ids"] = rel_conds_lst

    return JsonResponse(data)

def get_note_content(request):
    """ Get note content from db
    :param request: The request from which the note content is asked
    :return: The note content
    """

    data = {}
    try:
        data["note_content"] = Notes.objects.get(id=request.GET.get("note_id", None)).content
    except Notes.DoesNotExist:
        data["note_content"] = ""
    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def index(request):
    # print(request.META.get('HTTP_REFERER'))

    scenarios = []
    for sc in Scenario.objects.order_by('-timestamp').all():
        scenarios.append({
            "id": sc.id,
            "title": sc.title,
            "drugs": sc.drugs.all(),
            "conditions": sc.conditions.all(),
            "owner": sc.owner.username,
            "status": dict(sc.status.status_choices).get(sc.status.status),
            "timestamp": sc.timestamp
        })

    if request.method == 'DELETE':
        scenario_id = QueryDict(request.body).get("scenario_id")
        scenario = None
        if scenario_id:
            try:
                scenario = Scenario.objects.get(id=int(scenario_id))
            except:
                pass
        return delete_db_rec(scenario)

    template = loader.get_template('app/index.html')

    return HttpResponse(template.render({"scenarios": scenarios}, request))


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def add_edit_scenario(request, scenario_id=None):
    """ Add or edit scenario view. If scenario id is None, then a new scenario is created
    Otherwise, retrieve the specific scenario that id refers to
    :param request: request
    :param scenario_id: the specific scenario, None for new scenario
    :return: the form view
    """
    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    if scenario_id:
        scenario = get_object_or_404(Scenario, pk=scenario_id)
    else:
        scenario = Scenario()
        scenario.owner = request.user


    delete_switch = "enabled" if scenario.id else "disabled"


    if request.method == 'POST':
        scform = ScenarioForm(request.POST,
                              instance=scenario, label_suffix='')

        if scform.is_valid():
            sc=scform.save()
            messages.success(
                request,
                _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))

            return HttpResponseRedirect(reverse('edit_scenario', args=(sc.id,)))

        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))


    elif request.method == 'DELETE':
        return delete_db_rec(scenario)

    # GET request method
    else:
        scform = ScenarioForm(label_suffix='',  instance=scenario)

    all_drug_codes = list(map(lambda d: d.code, scform.all_drugs))

    context = {
        "title": _("Σενάριο"),
        "atc_tree": json.dumps(atc_hierarchy_tree(all_drug_codes)),
        "delete_switch": delete_switch,
        "scenario_id": scenario.id,
        "form": scform,
    }

    return render(request, 'app/add_edit_scenario.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def ohdsi_workspace(request, scenario_id=None):
    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    sc = get_object_or_404(Scenario, id=scenario_id)

    # ohdsi_workspace = OHDSIWorkspace.objects.get_or_create(sc_id=scenario_id)
    drugs_cohort_name = None
    conditions_cohort_name = None

    # Get drugs concept set id
    sc_drugs = sc.drugs.all()
    if sc_drugs:
        drugs_names = [d.name for d in sc_drugs]

        try:
            drugs_cohort_name = ohdsi_wrappers.create_cs_coh(drugs_names, "Drug")
        except Exception as e:
            error_response = HttpResponse(content=str(e), status=500)
            return error_response

    condition_distinct_cohort_names = []
    # Get conditions concept set id
    sc_conditions = sc.conditions.all()
    if sc_conditions:
        conditions_names = [c.name for c in sc_conditions]
        try:
            conditions_cohort_name = ohdsi_wrappers.create_cs_coh(conditions_names, "Condition")
        except Exception as e:
            error_response = HttpResponse(content=str(e), status=500)
            return error_response

        if len(conditions_names) > 1:
            try:
                # Distinct condition concept sets and cohorts creation for cohort pathways
                for condition_distinct in conditions_names:
                    condition_distinct_cohort_names.append(ohdsi_wrappers.create_cs_coh([condition_distinct], "Condition"))
            except Exception as e:
                error_response = HttpResponse(content=str(e), status=500)
                return error_response

    coh_gen_errors = [_("Σφάλμα τροφοδότησης πληθυσμού ασθενών που λαμβάνουν τα συγκεκριμένα φάρμακα"),
                      _("Σφάλμα τροφοδότησης πληθυσμού ασθενών που παρουσιάζουν τις επιλεγμένες ανεπιθύμητες ενέργειες")
                      ]
    drugs_cohort = ohdsi_wrappers.get_entity_by_name("cohortdefinition", drugs_cohort_name) or {}
    conditions_cohort = ohdsi_wrappers.get_entity_by_name("cohortdefinition", conditions_cohort_name) or {}
    conditions_distinct_cohorts = [ohdsi_wrappers.get_entity_by_name("cohortdefinition", cond_dist_coh_name) or {}
                                   for cond_dist_coh_name in condition_distinct_cohort_names]

    # Generate cohorts
    for indx, coh in enumerate(list(filter(None, [drugs_cohort, conditions_cohort] + conditions_distinct_cohorts))):
        recent_gen_exists = ohdsi_wrappers.cohort_generated_recently(coh, recent=True,
                                                                     days_before=settings.COHORT_RECENT_DAYS_LIMIT)
        coh_id = coh.get("id")
        if coh_id and not recent_gen_exists:
            status = ohdsi_wrappers.generate_cohort(coh_id)
            if status == "FAILED":
                error_response = HttpResponse(
                    content= coh_gen_errors[indx > 0], status=500)
                return error_response

    ir_id = None
    char_id = None
    cp_id = None

    if drugs_cohort and conditions_cohort:
        ir_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name"),
                                                              [drugs_cohort] + [conditions_cohort])), "ir")
        ir_ent = ohdsi_wrappers.get_entity_by_name("ir", ir_name)

        if ir_ent:
            ir_id = ir_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_ir([drugs_cohort], [conditions_cohort])
            ir_id = res_json.get("id")

        cp_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name"),
                                                              [drugs_cohort] + conditions_distinct_cohorts)), "cp")
        cp_ent = ohdsi_wrappers.get_entity_by_name("pathway-analysis", cp_name)

        if cp_ent:
            cp_id = cp_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_cp([drugs_cohort], conditions_distinct_cohorts)
            cp_id = res_json.get("id")

    if drugs_cohort or conditions_cohort:
        char_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name", ""),
                                                                filter(None,[drugs_cohort, conditions_cohort]))), "char")
        char_ent = ohdsi_wrappers.get_entity_by_name("cohort-characterization", char_name)

        if char_ent:
            char_id = char_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_char(list(filter(None, [drugs_cohort, conditions_cohort])))
            char_id = res_json.get("id")

    all_drugs_coh = ohdsi_wrappers.get_entity_by_name("cohortdefinition", "All drugs cohort") or {}
    all_conditions_coh = ohdsi_wrappers.get_entity_by_name("cohortdefinition", "All conditions cohort") or {}

    context = {
        "title": _("Περιβάλλον εργασίας OHDSI"),
        "de_id": all_drugs_coh.get("id"),
        "co_id": all_conditions_coh.get("id"),
        "ir_id": ir_id,
        "char_id": char_id,
        "cp_id": cp_id,
        "sc_id": scenario_id
    }

    return render(request, 'app/ohdsi_workspace.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def incidence_rates(request, sc_id, ir_id, read_only=1):
    """ Add or edit incidence rates (ir) view. Retrieve the specific ir that ir_id refers to
    :param request: request
    :param ir_id: the specific ir record's id
    :param sc_id: the specific scenario's id
    :param read_only: 0 if False 1 if True
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    ir_url = "{}/ir/{}".format(settings.OHDSI_ENDPOINT, ir_id)

    ir_exists = ohdsi_wrappers.url_exists(ir_url)
    ir_options = {}
    if ir_exists:
        ir_options = ohdsi_wrappers.get_ir_options(ir_id)
    elif ir_id:
        messages.error(
            request,
            _("Δεν βρέθηκε ανάλυση ρυθμού επίπτωσης με το συγκεκριμένο αναγνωριστικο!"))

    # delete_switch = "enabled" if ir_exists else "disabled"


    if request.method == 'POST':
        # sc_id = sc_id or request.POST.get("sc_id")
        irform = IRForm(request.POST, label_suffix='', ir_options=ir_options, read_only=read_only)

        if irform.is_valid():
            # ir_options = {}
            # ir_options["targetIds"] =
            # ir_options["outcomeIds"] =

            ir_options["age"] = irform.cleaned_data.get("age")
            ir_options["ext_age"] = irform.cleaned_data.get("ext_age")
            ir_options["age_crit"] = irform.cleaned_data.get("age_crit")

            ir_options["genders"] = irform.cleaned_data.get("genders")
            ir_options["study_start_date"] = str(irform.cleaned_data.get("study_start_date"))
            ir_options["study_end_date"] = str(irform.cleaned_data.get("study_end_date"))

            # if ir_exists:
            rstatus, rjson = ohdsi_wrappers.update_ir(ir_id, **ir_options)
            # else:
            #     rstatus, rjson = ohdsi_wrappers.create_ir(ir_id, **ir_options)

            if rstatus == 200:
                messages.success(
                    request,
                    _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))
                return HttpResponseRedirect(reverse('edit_ir', args=(sc_id, ir_id, )))
            else:
                messages.error(
                    request,
                    _("Συνέβη κάποιο σφάλμα. Παρακαλώ προσπαθήστε ξανά!"))
                results_url = "{}/#/iranalysis/{}".format(settings.OHDSI_ATLAS, ir_id)
                # ir_resp = requests.get(ir_url)

                context = {
                    # "delete_switch": delete_switch,
                    "sc_id": sc_id,
                    "ir_id": ir_id,
                    "results_url": results_url,
                    "read_only": read_only,
                    "form": irform,
                    "title": _("Ανάλυση Ρυθμού Επίπτωσης")
                }
                return render(request, 'app/ir.html', context, status=500)

        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            results_url = "{}/#/iranalysis/{}".format(settings.OHDSI_ATLAS, ir_id)
            # ir_resp = requests.get(ir_url)

            context = {
                # "delete_switch": delete_switch,
                "sc_id": sc_id,
                "ir_id": ir_id,
                "results_url": results_url,
                "read_only": read_only,
                "form": irform,
                "title": _("Ανάλυση Ρυθμού Επίπτωσης")
            }
            return render(request, 'app/ir.html', context, status=400)


    # elif request.method == 'DELETE':
    #     return delete_db_rec(ohdsi_workspace)

    # GET request method
    else:
        # if "ohdsi-workspace" in http_referer:
        #     sc_id = http_referer.rsplit('/', 1)[-1]
        irform = IRForm(label_suffix='', ir_options=ir_options, read_only=read_only)
        # irform["sc_id"].initial = sc_id
        # update_ir(ir_id)

    results_url = "{}/#/iranalysis/{}".format(settings.OHDSI_ATLAS, ir_id)
    # ir_resp = requests.get(ir_url)

    additional_info = {}
    additional_info["time-study-info"] = "{} {} {} {}".format(
        _("Χρονικό παράθυρο μελέτης: "), ir_options.get("study_start_date"), _("έως"),
        ir_options.get("study_end_date")) if ir_options.get("study_start_date") and ir_options.get("study_end_date") \
        else _("Δεν έχει οριστεί συγκεκριμένο χρονικό παράθυρο μελέτης!")
    # additional_info["age_crit_info"] = "{} {}"

    age_crit_dict = dict([("lt", _("Μικρότερη από")), ("lte", _("Μικρότερη ή ίση με")),
                          ("eq", _("Ίση με")), ("gt", _("Μεγαλύτερη από")),
                          ("gte", _("Μεγαλύτερη ή ίση με")), ("bt", _("Ανάμεσα σε")),
                          ("!bt", _("Όχι ανάμεσα σε"))])
    additional_info["age_crit_info"] = "{} {} {}".format(
        _("Κριτήριο ηλικίας:"), age_crit_dict.get(ir_options.get("age_crit")).lower(),
        " {} ".format(_("και")).join([str(ir_options.get("age")), str(ir_options.get("ext_age"))]))\
        if ir_options.get("age_crit") else _("Δεν έχει οριστεί συγκεκριμένο ηλικιακό κριτήριο!")

    genders_dict = dict([("MALE", _("Άρρεν")), ("FEMALE", _("Θήλυ"))])
    additional_info["gender_crit_info"] = "{} {}".format(
        _("Κριτήριο φύλου:"), " {} ".format(_("και")).join([str(genders_dict.get(k)) for k in ir_options.get("genders")])) \
        if ir_options.get("genders") else _("Δεν έχει οριστεί συγκεκριμένο κριτήριο για το φύλο!")



    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "ir_id": ir_id,
        "results_url": results_url,
        "read_only": read_only,
        "form": irform,
        "add_info": additional_info,
        "title": _("Ανάλυση Ρυθμού Επίπτωσης")
    }

    return render(request, 'app/ir.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def characterizations(request, sc_id, char_id, read_only=1):
    """ Add or edit characterizations view. Retrieve the specific characterization analysis
     that char_id refers to
    :param request: request
    :param char_id: the specific characterization record's id
    :param sc_id: the specific scenario's id
    :param read_only: 0 if False 1 if True
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    char_url = "{}/cohort-characterization/{}".format(settings.OHDSI_ENDPOINT, char_id)

    char_exists = ohdsi_wrappers.url_exists(char_url)
    char_options = {}
    if char_exists:
        char_options = ohdsi_wrappers.get_char_options(char_id)
    elif char_id:
        messages.error(
            request,
            _("Δεν βρέθηκε χαρακτηρισμός πληθυσμού με το συγκεκριμένο αναγνωριστικο!"))

    # delete_switch = "enabled" if ir_exists else "disabled"


    if request.method == 'POST':
        # sc_id = sc_id or request.POST.get("sc_id")
        char_form = CharForm(request.POST, label_suffix='', char_options=char_options, read_only=read_only)

        if char_form.is_valid():
            char_options["features"] = list(map(int, char_form.cleaned_data.get("features")))

            rstatus, rjson = ohdsi_wrappers.update_char(char_id, **char_options)

            if rstatus == 200:
                messages.success(
                    request,
                    _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))
                return HttpResponseRedirect(reverse('edit_char', args=(sc_id, char_id, )))
            else:
                messages.error(
                    request,
                    _("Συνέβη κάποιο σφάλμα. Παρακαλώ προσπαθήστε ξανά!"))
                status_code = 500
                # results_url = "{}/#/cc/characterizations/{}".format(settings.OHDSI_ATLAS, char_id)
                #
                # context = {
                #     # "delete_switch": delete_switch,
                #     "sc_id": sc_id,
                #     "char_id": char_id,
                #     "results_url": results_url,
                #     "read_only": read_only,
                #     "form": char_form,
                #     "title": _("Χαρακτηρισμός Πληθυσμού")
                # }
                # return render(request, 'app/characterizations.html', context, status=500)

        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            status_code = 400
            # results_url = "{}/#/cc/characterizations/{}".format(settings.OHDSI_ATLAS, char_id)
            # # ir_resp = requests.get(ir_url)
            #
            # context = {
            #     # "delete_switch": delete_switch,
            #     "sc_id": sc_id,
            #     "char_id": char_id,
            #     "results_url": results_url,
            #     "read_only": read_only,
            #     "form": char_form,
            #     "title": _("Χαρακτηρισμός Πληθυσμού")
            # }
            # return render(request, 'app/characterizations.html', context, status=400)


    # elif request.method == 'DELETE':
    #     return delete_db_rec(ohdsi_workspace)

    # GET request method
    else:
        # if "ohdsi-workspace" in http_referer:
        #     sc_id = http_referer.rsplit('/', 1)[-1]
        char_form = CharForm(label_suffix='', char_options=char_options, read_only=read_only)
        status_code = 200
        # irform["sc_id"].initial = sc_id
        # update_ir(ir_id)

    results_url = "{}/#/cc/characterizations/{}".format(settings.OHDSI_ATLAS, char_id)
    # ir_resp = requests.get(ir_url)

    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "char_id": char_id,
        "results_url": results_url,
        "read_only": read_only,
        "form": char_form,
        "title": _("Χαρακτηρισμός Πληθυσμού")
    }

    return render(request, 'app/characterizations.html', context, status=status_code)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def drug_exposure(request):
    """ View drug exposure of the whole population
    :param request: request
    :return: the drug exposure view (iframe)
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    de_url = "{}/#/datasources/{}/drug".format(settings.OHDSI_ATLAS, settings.OHDSI_CDM_NAME)

    context = {
        "de_url": de_url,
        "title": _("Έκθεση σε φάρμακα")
    }

    return render(request, 'app/drug_exposure.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def condition_occurrence(request):
    """ View conditions occurrences distribution on the whole population
    :param request: request
    :return: the condition occurrence view (iframe)
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    co_url = "{}/#/datasources/{}/condition".format(settings.OHDSI_ATLAS, settings.OHDSI_CDM_NAME)

    context = {
        "co_url": co_url,
        "title": _("Εκδήλωση κατάστασης")
    }

    return render(request, 'app/condition_occurrence.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def pathways(request, sc_id, cp_id, read_only=1):
    """ Add or edit cohort pathways view. Retrieve the specific cohort pathways analysis
     that cp_id refers to
    :param request: request
    :param cp_id: the specific cohort pathway record's id
    :param sc_id: the specific scenario's id
    :param read_only: 0 if False 1 if True
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    cp_url = "{}/pathway-analysis/{}".format(settings.OHDSI_ENDPOINT, cp_id)

    cp_exists = ohdsi_wrappers.url_exists(cp_url)
    cp_options = {}
    if cp_exists:
        cp_options = ohdsi_wrappers.get_cp_options(cp_id)
    elif cp_id:
        messages.error(
            request,
            _("Δεν βρέθηκε ανάλυση Μονοπατιού Ακολουθίας Εκδήλωσης Συμβάντων στον υπό εξέταση πληθυσμό με το συγκεκριμένο αναγνωριστικο!"))

    # delete_switch = "enabled" if ir_exists else "disabled"


    if request.method == 'POST':
        # sc_id = sc_id or request.POST.get("sc_id")
        cp_form = PathwaysForm(request.POST, label_suffix='', cp_options=cp_options, read_only=read_only)

        if cp_form.is_valid():
            cp_options["combinationWindow"] = cp_form.cleaned_data.get("combination_window")
            cp_options["minCellCount"] = cp_form.cleaned_data.get("min_cell_count")
            cp_options["maxDepth"] = cp_form.cleaned_data.get("max_depth")

            rstatus, rjson = ohdsi_wrappers.update_cp(cp_id, **cp_options)

            if rstatus == 200:
                messages.success(
                    request,
                    _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))
                return HttpResponseRedirect(reverse('edit_char', args=(sc_id, cp_id, )))
            else:
                messages.error(
                    request,
                    _("Συνέβη κάποιο σφάλμα. Παρακαλώ προσπαθήστε ξανά!"))
                status_code = 500
        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            status_code = 400

    # GET request method
    else:
        cp_form = PathwaysForm(label_suffix='', cp_options=cp_options, read_only=read_only)
        status_code = 200

    results_url = "{}/#/pathways/{}/executions".format(settings.OHDSI_ATLAS, cp_id)

    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "cp_id": cp_id,
        "results_url": results_url,
        "read_only": read_only,
        "form": cp_form,
        "title": _("Μονοπάτι Ακολουθίας Εκδήλωσης Συμβάντων Πληθυσμού")
    }

    return render(request, 'app/pathways.html', context, status=status_code)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def gentella_html(request):
    context = {}
    # The template to be loaded as per gentelella.
    # All resource paths for gentelella end in .html.

    # Pick out the html file name from the url. And load that template.
    load_template = request.path.split('/')[-1]
    if not load_template.replace(".html", ""):
        return redirect("index")
    template = loader.get_template('app/' + load_template)
    return HttpResponse(template.render(context, request))


def unauthorized(request):
    return HttpResponseForbidden()


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def pubMed_view(request, scenario_id=None, page_id=None, first=None, end=None):
    """ Load papers that are relevant to scenario that user creates and check user's Mendeley library for papers that
    get from the results.
    :param request: request
    :param scenario_id: the specific scenario, None for new scenario
    :param page_id: the specific result page that user searching for, None for first page
    :param start: the start date for search query
    :param end: the end date for search query
    :return: the Literature Workspase view view
    """
    data = {}


    sc = Scenario.objects.get(id=scenario_id)
    drugs = [d for d in sc.drugs.all()]

    conditions = [c for c in sc.conditions.all()]

    # ac_token = requests.get('access_token')

    all_combs = list(product([d.name for d in drugs] or [""],
                             [c.name for c in conditions] or [""]))

    scenario = {"id": scenario_id,
                "drugs": drugs,
                "conditions": conditions,
                "all_combs": all_combs,
                "owner": sc.owner.username,
                "status": sc.status.status,
                "timestamp": sc.timestamp
                }

    records={}
    total_results = 0
    user = request.user
    social = user.social_auth.get(provider='mendeley-oauth2')
    mend_cookies = [social.extra_data['access_token']]
    # mend_cookies = mendeley_cookies()

    if first != None and end != None:
        begin = int(first) -1
        last = int(end) - 1
    else:
        begin = first
        last = end

    if mend_cookies != []:

        try:

            # access_token = mend_cookies[0].value
            # print(access_token)
            access_token = mend_cookies[0]

            if page_id == None:
                page_id = 1

                for j in all_combs:
                    if j[1]:
                        query = j[0] +' AND '+ j[1]
                        results = pubmed_search(query, 0, 10, access_token, begin, last)
                        if results != {}:
                            records.update(results[0])
                            total_results = total_results + results[1]
                    else:
                        query = j[0]
                        results = pubmed_search(query, 0, 10, access_token, begin, last)
                        if results != {}:
                            records.update(results[0])
                            total_results = total_results + results[1]
            else:

                start = 10*page_id - 10

                for j in all_combs:
                    if j[1]:
                        query = j[0] +' AND '+ j[1]
                        results = pubmed_search(query, start, 10, access_token, begin, last)
                        records.update(results[0])
                        total_results = results[1]
                    else:
                        query = j[0]
                        results = pubmed_search(query, start, 10, access_token, begin, last)
                        records.update(results[0])
                        total_results = results[1]

            pages_no = ceil(total_results/10)
            pages = list(range(1, pages_no))
            if first != None and end != None:
                dates = [str(first), str(end)]
            else:
                dates = []

            if records == {}:
                return render(request, 'app/LiteratureWorkspace.html', {"scenario": scenario})

            return render(request, 'app/LiteratureWorkspace.html', {"scenario": scenario, 'records': records, 'pages': pages, 'page_id': page_id, 'results': total_results, 'dates':dates})

        except Exception as e:
            print(e)
            # previous_url = request.META.get('HTTP_REFERER')

            url = '/dashboard'


            return redirect(url)


    else:

        client_id = 8886
        redirect_uri = "http://127.0.0.1:8000/"
        client_secret = "75nLSO6SJtSD8um3"
        mendeley = Mendeley(client_id, redirect_uri=redirect_uri)

        auth = mendeley.start_implicit_grant_flow()

        login_url = auth.get_login_url()

        url = '/dashboard'

        return redirect(url)

def is_logged_in(request):
    """ Checks if the user is logged in Mendeley platform.
    :param request: request
    :return: Json response
    """
    try:
        user = request.user
        social = user.social_auth.get(provider='mendeley-oauth2')
        cookie_list = [social.extra_data['access_token']]
        # print(cookie_list)
        restoken = requests.get(
            'https://api.mendeley.com/files',
            headers={'Authorization': 'Bearer {}'.format(cookie_list[0]),
                     'Accept': 'application/vnd.mendeley-file.1+json'},
        )
        if restoken.status_code != 200:
            cookie_list = []
    except:
        cookie_list = []

    data = {
        'logged_in': (cookie_list != [])
    }

    return JsonResponse(data)



def pubmed_search(query, begin, max, access_token, start, end):
    """ Search for papers relevant to the scerario that user creates in PubMed library.
    :param query: query for Pubmed library search that created from combo of drug and
    reaction with the logic operator AND
    :param begin: the number of the first paper that will retrieve from PubMed library,
    depends on page_id
    :param max: the max number of the retrieved papers from Pubmed library
    :return: a list with a dictionary which contains records of the retrieved papers and
    the  total number of the retrieved papers for a certain query. If there are no results
    for the query, returns an empty dictionary
    """
    # pvclinical.project @ gmail.com
    # , apikey = '40987f0b48b279c32047b1386f249d8cb308'

    w = conduit.Conduit(email='pvclinical.project@gmail.com', apikey = '40987f0b48b279c32047b1386f249d8cb308')
    fetch_pubmed = w.new_pipeline()
    q = query
    if start==None and end==None:
        sid = fetch_pubmed.add_search(
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released',
             'datetype': 'pdat'})

        s = w.run(fetch_pubmed)
        qres = s.get_result()
        total_results = qres.size()
        sid = fetch_pubmed.add_search(
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released', 'retmax': max,
             'datetype': 'pdat'})
        fetch_pubmed.add_fetch({'retmode': 'xml', 'rettype': 'fasta', 'retstart': begin}, dependency=sid,
                               analyzer=PubmedAnalyzer())


        a = w.run(fetch_pubmed)

        res = a.get_result()
    else:
        sid = fetch_pubmed.add_search(
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released', 'mindate': start, 'maxdate':end,
             'datetype': 'pdat'})

        s = w.run(fetch_pubmed)
        qres = s.get_result()
        total_results = qres.size()
        sid = fetch_pubmed.add_search(
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released', 'retmax': max, 'mindate': start, 'maxdate':end,
             'datetype': 'pdat'})
        fetch_pubmed.add_fetch({'retmode': 'xml', 'rettype': 'fasta', 'retstart': begin}, dependency=sid,
                               analyzer=PubmedAnalyzer())

        a = w.run(fetch_pubmed)

        res = a.get_result()

    try:

        for i in res.pubmed_records.keys():

            res.pubmed_records[i].documents = mendeley_pdf(access_token, res.pubmed_records[i].title)

            qr = q.split(' AND ')
            if len(qr) > 1:
                res.pubmed_records[i].drug = qr[0]
                res.pubmed_records[i].condition = qr[1]

            else:
                res.pubmed_records[i].drug = qr[0]
            authors = res.pubmed_records[i].authors
            res.pubmed_records[i].authors = ';'.join(str(x['lname'] + "," + x['fname'].replace(' ', '')) if x['fname'] else str(x['lname']) for x in res.pubmed_records[i].authors )


            Entrez.email = 'pvclinical.project@gmail.com'
            handle = Entrez.elink(dbfrom="pubmed", db="pmc", linkname="pubmed_pmc", id=res.pubmed_records[i].pmid,
                                  retmode="text")
            pmcid = getPMCID(handle)

            if pmcid != " ":
                res.pubmed_records[i].pmcid = pmcid
                url = "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC" + pmcid + "/pdf/"
                if check_url(url) != 404:
                    res.pubmed_records[i].url = url

            elif res.pubmed_records[i].idlist:
                res.pubmed_records[i].url = "https://doi.org/" + res.pubmed_records[i].idlist

            else:
                res.pubmed_records[i].url = "http://www.ncbi.nlm.nih.gov/pubmed/" + res.pubmed_records[i].pmid

            pmid = "PM" + res.pubmed_records[i].pmid
            handle.close()
            try:
                if PubMed.objects.get(pid=res.pubmed_records[i].pmid):
                    pubmed = PubMed.objects.get(pid=res.pubmed_records[i].pmid)
                    res.pubmed_records[i].notes = pubmed.notes
                    res.pubmed_records[i].user = pubmed.user
                    res.pubmed_records[i].relevance = pubmed.relevance
            except PubMed.DoesNotExist:
                res.pubmed_records[i] = res.pubmed_records[i]

        return [res.pubmed_records, total_results]

    except AttributeError:
        return {}


def check_url(url):
    """ Checks if the pdf url exists for a PubMed paper.
    :param url: url that created with PMCID
    :return: the status code of the response
    """
    MAX_RETRIES = 20

    session = requests.Session()
    adapter = requests.adapters.HTTPAdapter(max_retries=MAX_RETRIES)
    session.mount('https://', adapter)
    session.mount('http://', adapter)

    r = session.get(url)

    return r.status_code


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def get_note(request):
    """ Get note from db
    :param request: The request from which the note is asked
    :return: The note
    """

    data = {}
    # note_id is <pid>_<scenario_id>
    (pid, scid) = request.GET.get("note_id", "").split("_")

    try:
        note = PubMed.objects.get(pid=pid, scenario_id=scid, user=request.user)
        data = {"scenario_id": note.scenario_id.id, "title": note.title, "user": note.user.id,
                "pubmeddate": note.pubdate, "content": note.notes, "pid": note.pid,
                "abstract": note.abstract, "authors": note.authors, "url": note.url,
                "relevance": note.relevance}
    except Notes.DoesNotExist:
        data = {}
    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def save_pubmed_input(request):
    """ Save the notes and the relevance of a paper that user chose.
    :param request: request
    :return: Json response
    """

    scenario_id = request.GET.get('scenario_id', None)
    relevance = request.GET.get('relevance', None)
    notes = request.GET.get('notes', None)
    pid = request.GET.get("pmid", None)
    title = request.GET.get("title", None)
    abstract = request.GET.get("abstract", None)
    pubdate = request.GET.get("pubmeddate", None)
    authors = request.GET.get("authors", None)
    url = request.GET.get("url", None)
    user = request.user

    scenario = Scenario.objects.get(id=scenario_id)

    try:
        pm = PubMed.objects.get(scenario_id=scenario, user=user, pid=pid)
        if relevance:
            pm.notes = notes
            pm.relevance = relevance
        else:
            pm.notes = notes
    except PubMed.DoesNotExist:
        pm = PubMed(user=user, pid=pid, title=title, abstract=abstract, pubdate=pubdate, authors=authors,
                    url=url, relevance=relevance, notes=notes, scenario_id =scenario)
    try:
        pm.save()
        data = {
            'message': 'Success'
        }
    except:
        data = {
            'message': 'Failure'
        }
    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def paper_notes_view(request):
    """ Save the notes and the relevance of a paper that user chose.
    :param request: request
    :return: redirect to paper_notes view where user can review the paper
    and add it to his Mendeley library.
    """
    metainfo = {}
    if request.method == 'POST':

        metainfo['title'] = request.POST.get("title")
        metainfo['abstract'] = request.POST.get("abstract")
        metainfo['pmcid'] = request.POST.get("pmcid")
        metainfo['authors'] = request.POST.get("authors")
        metainfo['doi'] = request.POST.get("doi")
        metainfo['pmid'] = request.POST.get("pmid")
        metainfo['user'] = request.user


    return render(request, 'app/paper_notes.html', {'metainfo': metainfo})


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def keep_notes(request, ws_id, wsview_id, sc_id=None ):
    """ Add or edit notes as a user for a specific view in a workspace of a scenario
    :param request: request
    :param sc_id: the specific scenario's id.
    Can be None in the cases of drug exposure and condition occurence views in OHDSI workspace
    :param ws_id:  the workspace's id
    :param wsview_id: the workspace's view id
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    tmp_user = User.objects.get(username=request.user)
    try:
        tmp_scenario = Scenario.objects.get(id=sc_id)
    except Scenario.DoesNotExist:
        tmp_scenario = None

    tmp_workspace = settings.WORKSPACES.get(ws_id)

    try:
        nobj = Notes.objects.get(user=tmp_user,
                                 scenario=tmp_scenario, workspace=tmp_workspace,
                                 wsview=wsview_id)
    except Notes.DoesNotExist:
        nobj = Notes(user=tmp_user,
                     scenario=tmp_scenario, workspace=tmp_workspace,
                     wsview=wsview_id)

    if request.method == 'POST':
        notes_form = NotesForm(request.POST, instance=nobj, label_suffix='')
        # sc_id = sc_id or request.POST.get("sc_id")

        if notes_form.is_valid():
            nf = notes_form.save(commit=False)
            nf.user = tmp_user
            nf.workspace = tmp_workspace
            nf.scenario = tmp_scenario
            nf.wsview = wsview_id

            # clean_content = notes_form.cleaned_data.get("content")

            # notes_form.content = clean_content

            nf.save()

            messages.success(
                request,
                _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))
            return HttpResponseRedirect(reverse('keep_notes', args=tuple(filter(None,(sc_id, ws_id, wsview_id)))))

        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            status_code = 400

    # GET request method
    else:
        notes_form = NotesForm(instance=nobj, label_suffix='')
        status_code = 200

    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "ws_id": ws_id,
        "wsview_id": wsview_id,
        "form": notes_form,
        "title": _("Σημειώσεις")
    }

    return render(request, 'app/notes.html', context, status=status_code)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def aggregated_notes(request, lang):
    """ Add, edit or view aggregated the notes kept for user's scenarios
    :param request: request
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    try:
        user = User.objects.get(username=request.user)
        user_notes = Notes.objects.filter(user=user).order_by("scenario", "workspace", "wsview")
        # Get scenarios that the user's notes concern
        scenarios = Scenario.objects.filter(
            id__in=map(lambda el: el.scenario.id, filter(lambda elm: elm.scenario!=None, user_notes))
        ).order_by("title")

        # List of structured notes in form {<scenario>:{<workspace>:{<worskpace_view>: <note>, ...}, ...}
        struct_notes = []
        views_dict = {"ir": _("Ρυθμός Επίπτωσης"), "char": _("Χαρακτηρισμός Πληθυσμού"),
                      "pathways": _("Μονοπάτι Ακολουθίας Συμβάντων"), "de": _("Έκθεση σε Φάρμακα"),
                      "co": _("Εκδήλωση Κατάστασης")}
        rev_avail_workspaces = dict(map(reversed, settings.WORKSPACES.items()))
        for sc in scenarios:
            notes_for_scenario = Notes.objects.filter(scenario=sc)
            workspaces_ids = set(map(lambda n: n.workspace, notes_for_scenario))
            sc_info = {}
            sc_info[sc]= {}
            # sc_info[sc]["workspaces"] = map(lambda ws_id: rev_avail_workspaces.get(ws_id), workspaces_ids)
            for ws_id in workspaces_ids:
                # Not for workspace with ws_id in the specific scenario
                notes_for_ws = notes_for_scenario.filter(workspace=ws_id)
                wsviews = list(map(lambda n: n.wsview, notes_for_ws))
                sc_info[sc][rev_avail_workspaces[ws_id]] = {}
                # sc_info[sc][rev_avail_workspaces[ws_id]] = {"wsviews": wsviews}
                for wsv in wsviews:
                    wsv_trans = views_dict.get(wsv) or wsv
                    sc_info[sc][rev_avail_workspaces[ws_id]][wsv_trans] = notes_for_ws.get(wsview=wsv)
            struct_notes.append(sc_info)

        # Notes that are common for all scenarios, on the various workspaces
        scenarios_independent_notes = user_notes.filter(scenario=None)

        workspaces_for_ind_notes = set(map(lambda n: n.workspace, scenarios_independent_notes))
        sc_ind_ws_wsview_notes = dict([(rev_avail_workspaces.get(ws),
                                        dict([(views_dict.get(ws_note.wsview) or ws_note.wsview, ws_note
                                             ) for ws_note in scenarios_independent_notes.filter(workspace=ws)
                                       ])) for ws in workspaces_for_ind_notes])

        struct_notes.append({None: sc_ind_ws_wsview_notes})

        status_code = 200
    except Exception as e:
        status_code = 500

    context = {"struct_notes": struct_notes,
               "lang": lang,
               # "sc_ind_notes": sc_ind_ws_wsview_notes,
               "status": status_code
               }

    return render(request, 'app/notes_aggregated.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def allnotes(request):

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    try:
        user = User.objects.get(username=request.user)

        if Notes.objects.filter(user=user) != "":
            user_notes = Notes.objects.filter(user=user).order_by("scenario", "workspace", "wsview")

            lista_notes_scid_without = list(map(lambda el: el.scenario.id, filter(lambda elm: elm.scenario != None, user_notes)))
            lista_title_scenarios_without = list(map(lambda el: el.scenario.title, filter(lambda elm: elm.scenario != None, user_notes)))
            dict_sc_id_title = dict(zip(lista_notes_scid_without, lista_title_scenarios_without))

            notesforscenario = []
            notesfornonescen = []

            for n in Notes.objects.order_by('-note_datetime').all():
                if n.scenario_id != None:
                    if n.workspace == 1:
                        work = 'OHDSI'
                    if n.workspace == 2:
                        work = 'OpenFDA'
                    if n.wsview == 'ir':
                        wsview_title = 'Incidence Rate'
                    elif n.wsview == 'char':
                        wsview_title = 'Cohort Caracterization'
                    elif n.wsview == 'pathways':
                        wsview_title = 'Cohort Pathways'

                    else:
                        wsview_title = n.wsview

                    for key in dict_sc_id_title:
                        if n.scenario_id == key:
                            scenario_title = dict_sc_id_title[key]

                    notesforscenario.append({
                        "workspace": work,
                        "content": n.content,
                        "wsview": n.wsview,
                        "wsview_title": wsview_title,
                        "scenario": n.scenario_id,
                        "scenario_title": scenario_title,
                        "note_datetime": n.note_datetime,
                    })
                else:

                    work = 'OHDSI'
                    if n.wsview == 'de':
                        wsview_title = 'Drug Exposure'
                    elif n.wsview == 'co':
                        wsview_title = 'Condition Occurence'

                    notesfornonescen.append({
                        "scenario": None,
                        "note_datetime": n.note_datetime,
                        "workspace": work,
                        "content": n.content,
                        "wsview": n.wsview,
                        "wsview_title": wsview_title

                    })
        else:
            notesfornonescen = []
            notesforscenario = []

        notespubmed = []
        if PubMed.objects.filter(user=user) != "":

            user_pubmed_notes = PubMed.objects.filter(user=user).order_by("scenario_id", "title", "notes")
            list_pubscen_sc = list(map(lambda el: el.scenario_id.id, filter(lambda elm: elm.scenario_id != None, user_pubmed_notes)))
            list_pubscen_title = list(map(lambda el: el.scenario_id.title,filter(lambda elm: elm.scenario_id != None, user_pubmed_notes)))
            dictpub_sc_id_title = dict(zip(list_pubscen_sc, list_pubscen_title))

            for p in PubMed.objects.order_by('-pubdate').all():
                for key in dictpub_sc_id_title:
                    scenario_title = dictpub_sc_id_title[key]
                notespubmed.append({
                    "workspace": 'PubMed',
                    "notes": p.notes,
                    "wsview": p.title,
                    "title": p.title,
                    "scenario_id": p.scenario_id_id,
                    "scenario_title": scenario_title,
                    "pubmeddate": p.pubdate,
                    "abstract": p.abstract,
                    "pmid": p.pid,
                    "authors": p.authors,
                    "created": p.created
                })
        else:
            notespubmed = []

        status_code = 200
    except Exception as e:
        status_code = 500

    context = {'notesfornonescen': notesfornonescen, 'notesforscenario': notesforscenario , 'notespubmed': notespubmed, "status": status_code}
    return render(request, 'app/all_notes.html', context)


def final_report(request, scenario_id=None):
    sc = Scenario.objects.get(id=scenario_id)
    drugs = [d for d in sc.drugs.all()]
    conditions = [c for c in sc.conditions.all()]
    all_combs = list(product([d.name for d in drugs] or [""],
                             [c.name for c in conditions] or [""]))

    scenario_open = sc.id

    synolo=[]
    from hashlib import blake2b
    for i in range(len(all_combs)):
        p = sc.title+str(sc.owner)+str(i)
        k = repr(p).encode('utf-8')
        h = blake2b(key=k, digest_size=16)
        hash = h.hexdigest()
        synolo.append(hash)
    drug_condition_hash=[]
    m=0
    for i in all_combs:
            k=list(i)
            k.append(synolo[m])
            p=tuple(k)
            drug_condition_hash.append(p)
            m=m+1

    context = {'scenario_open': scenario_open, "REPORT_ENDPOINT": settings.REPORT_ENDPOINT,'drug_condition_hash':drug_condition_hash}
    return render(request, 'app/final_report.html', context)

def report_pdf(request, scenario_id=None):
    import requests
    from bs4 import BeautifulSoup
    import pandas as pd
    import os

    scenario_id = scenario_id or json.loads(request.GET.get("scenario_id", None))

    sc = Scenario.objects.get(id=scenario_id)
    scenario = sc.title

    drugs = [d for d in sc.drugs.all()]
    conditions = [c for c in sc.conditions.all()]
    all_combs = list(product([d.name for d in drugs] or [""],
                             [c.name for c in conditions] or [""]))

    synolo=[]
    from hashlib import blake2b
    for i in range(len(all_combs)):
        p = sc.title+str(sc.owner)+str(i)
        k = repr(p).encode('utf-8')
        h = blake2b(key=k, digest_size=16)
        hash = h.hexdigest()
        synolo.append(hash)
    drug_condition_hash=[]
    m=0
    for i in all_combs:
            k=list(i)
            k.append(synolo[m])
            p=tuple(k)
            drug_condition_hash.append(p)
            m=m+1

    r = requests.get(settings.REPORT_ENDPOINT)
    soup = BeautifulSoup(r.text, 'html.parser')

    dictpng={}
    dictcsv={}
    dict_dash_csv={}
    dict_rr_d={}
    dict_rr_e={}
    dict_lr={}
    dict_lre={}
    dashboard_png=[]
    lrTest_png=[]
    lreTest_png=[]
    dict1={}
    dict2={}
    dict3={}

    dict_hash_combination={}

    for i,j,k in drug_condition_hash:

        if i != '' and j != '':

            dict_hash_combination[k]= i+' - '+j

            files_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_timeseries".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))

            files_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_timeseries_prr".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            if files_png:
                dict1.setdefault(k, []).append(files_png[0])
            else:
                dict1.setdefault(k, []).append('')

            if files_csv:
                df1 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+files_csv[0]))
                styler1 = df1.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict1.setdefault(k, []).append(styler1.render())
            else:
                dict1.setdefault(k, []).append('')

            dynprr_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_prrplot".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            dynprr_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_prrcounts".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            dynprr_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_concocounts".format(k) in elm,
                                     map(lambda el: el.get_text(), soup.find_all('a'))))
            dynprr_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_eventcounts".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            if dynprr_png:
                dict2.setdefault(k, []).append(dynprr_png[0])
            else:
                dict2.setdefault(k, []).append('')

            if dynprr_csv:
                dict2.setdefault(k, []).append('-Report counts and PRR')
                df1 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dynprr_csv[0]))
                styler1 = df1.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict2.setdefault(k, []).append(styler1.render())
            else:
                dict2.setdefault(k, []).append('')
                dict2.setdefault(k, []).append('')

            if dynprr_csv1:
                dict2.setdefault(k, []).append('-Drugs in scenario reports')
                df2 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dynprr_csv1[0]))
                styler2 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict2.setdefault(k, []).append(styler2.render())
            else:
                dict2.setdefault(k, []).append('')
                dict2.setdefault(k, []).append('')

            if dynprr_csv2:
                dict2.setdefault(k, []).append('-Events in scenario reports')
                df3 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dynprr_csv2[0]))
                styler3 = df3.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict2.setdefault(k, []).append(styler3.render())
            else:
                dict2.setdefault(k, []).append('')
                dict2.setdefault(k, []).append('')


            changep_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_cpmeanplot".format(k) in elm,
                                   map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_png1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_cpvarplot".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_png2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_cpbayesplot".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_png3 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_yearplot".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_codrugs".format(k) in elm,
                                      map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_qevents".format(k) in elm,
                                       map(lambda el: el.get_text(), soup.find_all('a'))))
            if changep_png:
                dict3.setdefault(k, []).append('-Change in mean analysis ')
                dict3.setdefault(k, []).append(changep_png[0])
            else:
                dict3.setdefault(k, []).append('')
                dict3.setdefault(k, []).append('')

            if changep_png1:
                dict3.setdefault(k, []).append('-Change in variance analysis')
                dict3.setdefault(k, []).append(changep_png1[0])
            else:
                dict3.setdefault(k, []).append('')
                dict3.setdefault(k, []).append('')

            if changep_png2:
                dict3.setdefault(k, []).append('-Bayesian changepoint analysis')
                dict3.setdefault(k, []).append(changep_png2[0])
            else:
                dict3.setdefault(k, []).append('')
                dict3.setdefault(k, []).append('')

            if changep_png3:
                dict3.setdefault(k, []).append('-Report counts by date')
                dict3.setdefault(k, []).append(changep_png3[0])
            else:
                dict3.setdefault(k, []).append('')
                dict3.setdefault(k, []).append('')

            if changep_csv:
                dict3.setdefault(k, []).append('-Drugs in scenario reports')
                df3 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+changep_csv[0]))
                styler3 = df3.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict3.setdefault(k, []).append(styler3.render())
            else:
                dict3.setdefault(k, []).append('')
                dict3.setdefault(k, []).append('')

            if changep_csv1:
                dict3.setdefault(k, []).append('-Events in scenario reports')
                df3 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+changep_csv1[0]))
                styler3 = df3.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict3.setdefault(k, []).append(styler3.render())
            else:
                dict3.setdefault(k, []).append('')
                dict3.setdefault(k, []).append('')


 # SOS edw na thimamai oti exw prosthesei auto to if, poly simantiko giati sto event epairne to eventcounts
        #for drug only
        if j== "":
            dash_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_primary".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            dash_png1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_serious".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            dash_png2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_sexplot".format(k) in elm,
                                      map(lambda el: el.get_text(), soup.find_all('a'))))
            if dash_png: dashboard_png.append(dash_png1[0])
            if dash_png1: dashboard_png.append(dash_png1[0])
            if dash_png2: dashboard_png.append(dash_png2[0])

            dash_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_event".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            dash_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_concomitant".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            dash_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_indication".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))

            if dash_csv: dict_dash_csv['Events']=dash_csv[0]
            if dash_csv1:dict_dash_csv['Concomitant Medications']=dash_csv1[0]
            if dash_csv2:dict_dash_csv['Indications']=dash_csv2[0]

            rr_d_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_codrug".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_d_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_coquerye2".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_d_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_eventtotals".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_d_csv3 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_indquery".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_d_csv4 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_prr".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_d_csv5 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_specifieddrug".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            if rr_d_csv4: dict_rr_d['PRR and ROR Results']= rr_d_csv4[0]
            if rr_d_csv5: dict_rr_d['Analyzed Event Counts for Specified Drug']= rr_d_csv5[0]
            if rr_d_csv2: dict_rr_d['Analyzed Event Counts for All Drug']= rr_d_csv2[0]
            if rr_d_csv1: dict_rr_d['Ranked Event Counts for Drug']= rr_d_csv1[0]
            if rr_d_csv: dict_rr_d['Drugs in scenario reports']= rr_d_csv[0]
            if rr_d_csv3: dict_rr_d['Indications in scenario reports']= rr_d_csv3[0]

            lr_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_allindata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lr_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_coqadata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lr_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_coqevdata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lr_csv3 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_inqprr".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lr_csv4 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_prrindata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lr_csv5 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_resindata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lr_csv6 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_prres".format(k) in elm,
                                  map(lambda el: el.get_text(), soup.find_all('a'))))
            if lr_csv6: dict_lr['LTR Results based on Total Events'] = lr_csv6[0]
            if lr_csv2: dict_lr['Analyzed Event Counts for Drug'] = lr_csv2[0]
            if lr_csv: dict_lr['Analyzed Event Counts for All Drugs'] = lr_csv[0]
            if lr_csv4: dict_lr['Drugs in scenario reports'] = lr_csv4[0]
            if lr_csv5: dict_lr['Event counts for drug'] = lr_csv5[0]
            if lr_csv1: dict_lr['Counts for all events'] = lr_csv1[0]
            if lr_csv3: dict_lr['Indications in scenario reports'] = lr_csv3[0]

            lr_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_histogram".format(k) in elm,
                                   map(lambda el: el.get_text(), soup.find_all('a'))))
            if lr_png: lrTest_png.append(lr_png[0])

        #for condition only
        if i == "":
            rr_e_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_codrug".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_e_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_coquerye2".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_e_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_eventtotals".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_e_csv3 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_indquery".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_e_csv4 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_prr".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            rr_e_csv5 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_specifieddrug".format(k) in elm,
                                    map(lambda el: el.get_text(), soup.find_all('a'))))
            if rr_e_csv4: dict_rr_e['PRR and ROR Results']= rr_e_csv4[0]
            if rr_e_csv5: dict_rr_e['Analyzed Drug Counts for Specified Event']= rr_e_csv5[0]
            if rr_e_csv2: dict_rr_e['Analyzed Drug Counts for All events']= rr_e_csv2[0]
            if rr_e_csv1: dict_rr_e['Ranked Drug Counts for Event']= rr_e_csv1[0]
            if rr_e_csv: dict_rr_e['Events in scenario reports']= rr_e_csv[0]
            if rr_e_csv3: dict_rr_e['Indications in scenario reports']= rr_e_csv3[0]

            lre_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Eallindata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lre_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Ecoqadata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lre_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Ecoqevdata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lre_csv3 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Einqprr".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lre_csv4 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Eprrindata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lre_csv5 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Eresindata".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
            lre_csv6 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_Eprres".format(k) in elm,
                                  map(lambda el: el.get_text(), soup.find_all('a'))))
            if lre_csv6: dict_lre['LTR Results based on Total Drugss'] = lre_csv6[0]
            if lre_csv2: dict_lre['Analyzed Drug Counts for Event'] = lre_csv2[0]
            if lre_csv: dict_lre['Analyzed Drug Counts for All Events'] = lre_csv[0]
            if lre_csv4: dict_lre['Events in scenario reports'] = lre_csv4[0]
            if lre_csv5: dict_lre['Drug counts for event'] = lre_csv5[0]
            if lre_csv1: dict_lre['Counts for all drugs'] = lre_csv1[0]
            if lre_csv3: dict_lre['Indications in scenario reports'] = lre_csv3[0]

            lre_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_Ehistogram".format(k) in elm,
                                   map(lambda el: el.get_text(), soup.find_all('a'))))
            if lre_png: lreTest_png.append(lre_png[0])
        if i=='' or j=='':
            files_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_timeseries".format(k) in elm,
                                                             map(lambda el: el.get_text(), soup.find_all('a'))))
            files_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_timeseries_prr".format(k) in elm,
                                                            map(lambda el: el.get_text(), soup.find_all('a'))))
            if files_png:
                dictpng[k] = files_png[0]
            if files_csv:
                dictcsv[k] = files_csv[0]

    dict_quickview={}
    for i, j, k in drug_condition_hash:
        for key in dictpng:
            if k == key:
                    dict_quickview.setdefault(i, []).append(dictpng[key])

    for i, j, k in drug_condition_hash:
        for key in dictcsv:
            if k == key:
                df1 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dictcsv[key]))
                styler1 = df1.loc[:9].style.hide_columns(['Unnamed: 0', 'Definition']).hide_index()
                dict_quickview[i].append(styler1.render())


    for i in dict_dash_csv:
        df2 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dict_dash_csv[i]))
        styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
        dict_dash_csv[i]=styler1.render()

    for i in dict_rr_d:
        df2 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dict_rr_d[i]))
        styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
        dict_rr_d[i] = styler1.render()

    for i in dict_lr:
        df2 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dict_lr[i]))
        styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
        dict_lr[i] = styler1.render()
    for i in dict_rr_e:
        df2 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dict_rr_e[i]))
        styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
        dict_rr_e[i] = styler1.render()

    for i in dict_lre:
        df2 = pd.read_csv(r'{}'.format(settings.REPORT_ENDPOINT+dict_lre[i]))
        styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
        dict_lre[i] = styler1.render()

    user = sc.owner

    if Notes.objects.filter(user=user) != "":
        user_notes = Notes.objects.filter(user=user).order_by("scenario", "workspace", "wsview")
        notes_wsview_openfda = list(map(lambda el: el.wsview, filter(lambda elm: elm.workspace == 2, user_notes)))
        dict_openfda_notes={}
        notes_openfda={}
        for i in notes_wsview_openfda:
            notes_content_openfda = list(map(lambda el: el.content, filter(lambda elm: elm.wsview == i, user_notes)))
            dict_openfda_notes[i]=notes_content_openfda[0]
        for i, j in all_combs:
            for key in dict_openfda_notes:
                if i + ' - ' + j == key:
                    notes_openfda[key]=dict_openfda_notes[key]
                if i == key:
                    notes_openfda[key]=dict_openfda_notes[key]
                if j == key:
                    notes_openfda[key]=dict_openfda_notes[key]
    empty_OpenFDA=''
    for key in dict1:
        for j in dict1[key]:
            if j != '':
               empty_OpenFDA='no'
    for key in dict2:
        for j in dict2[key]:
            if j != '':
                empty_OpenFDA = 'no'

    for key in dict3:
        for j in dict3[key]:
            if j != '':
                empty_OpenFDA = 'no'

    context = {"REPORT_ENDPOINT": settings.REPORT_ENDPOINT,'all_combs':all_combs, 'scenario': scenario,'dict_quickview':dict_quickview,'dashboard_png':dashboard_png, 'dict_dash_csv':dict_dash_csv ,
               'dict_rr_d':dict_rr_d, 'dict_lr': dict_lr, 'lrTest_png':lrTest_png, 'dict_rr_e':dict_rr_e,'dict_lre': dict_lre, 'lreTest_png':lreTest_png,
               'notes_openfda':notes_openfda,'dict1':dict1, 'dict2':dict2, 'dict3':dict3, 'dict_hash_combination':dict_hash_combination, 'empty_OpenFDA':empty_OpenFDA}



    return render(request, 'app/report_pdf.html', context)

def print_report(request,scenario_id=None):

    scenario_id = scenario_id or json.loads(request.GET.get("scenario_id", None))
    sc=Scenario.objects.get(id=scenario_id)

    import pdfkit
    pdfkit.from_url('http://127.0.0.1:8000/report_pdf/{}'.format(sc.id), '/tmp/report.pdf')

    import webbrowser
    webbrowser.open(r'file:///tmp/report.pdf')

    return render(request, 'app/print_report.html')

