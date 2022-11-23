import ast
import concurrent.futures
import hashlib
import html

import datetime
import glob
import json
import os
import re
import requests
import tempfile
import uuid
import urllib

import pandas as pd
import pdfkit
import shutil

from math import ceil
from itertools import chain
from itertools import product
from requests.auth import HTTPBasicAuth

from bs4 import BeautifulSoup
from Bio import Entrez
from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.contrib.auth.decorators import user_passes_test
from django.contrib.auth.models import User
from django.contrib import messages
from django.forms.models import model_to_dict
from django.shortcuts import get_object_or_404
from django.shortcuts import render
from django.template import loader
from django.http import FileResponse
from django.http import HttpResponse
from django.http import HttpResponseForbidden
from django.http import HttpResponseNotAllowed
from django.http import QueryDict
from django.shortcuts import HttpResponseRedirect
from django.http import JsonResponse
from django.shortcuts import redirect
from django.utils.translation import gettext_lazy as _
from django.urls import reverse

from app import ohdsi_wrappers
from app import ohdsi_shot

from app.errors_redirects import forbidden_redirect
from app.errors_redirects import timeout_redirect
from app.forms import ScenarioForm
from app.forms import IRForm
from app.forms import CharForm
from app.forms import NotesForm
from app.forms import PathwaysForm
from app.forms import IndividualCaseForm
from app.forms import QuestionnaireForm
from app.helper_modules import atc_hierarchy_tree
from app.helper_modules import delete_db_rec
from app.helper_modules import getPMCID
from app.helper_modules import is_doctor
from app.helper_modules import is_nurse
from app.helper_modules import is_pv_expert
from app.helper_modules import mendeley_pdf
from app.helper_modules import sort_report_screenshots
from app.models import Notes
from app.models import PubMed
from app.models import Scenario
from app.models import IndividualCase
from app.models import Questionnaire
from app.entrezpy import conduit
from app.retrieve_meddata import KnowledgeGraphWrapper
from app.pubmed import PubmedAnalyzer


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def OpenFDAWorkspace(request, scenario_id=None):

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

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

    return HttpResponse(template.render({"scenario": scenario, "openfda_shiny_endpoint": settings.OPENFDA_SHINY_ENDPOINT}, request))


def get_synonyms(request):
    """ Get all the synonyms for a list of drugs
    :param request: The request from which the list of drugs to search for synonyms will be retrieved
    :return: The list of synonyms for the drugs' list
    """

    drugs = json.loads(request.GET.get("drugs", None))

    knw = KnowledgeGraphWrapper()
    synonyms = knw.get_synonyms(drugs)

    data = {}
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

    data = {}
    data["results"] = [{"id": elm, "text": elm} for elm in subset]

    return JsonResponse(data)

# @csrf_exempt
def gen_ir_analysis(request):
    """ Generate ir analysis callback
    :param request:
    :return: the response from the generation attempt
    """

    ir_id = json.loads(request.GET.get("ir_id", None))
    resp_status = ohdsi_wrappers.generate_ir_analysis(ir_id)

    return JsonResponse({}, status=resp_status)


def del_ir_analysis(request):
    """ Delete ir analysis callback
    :param request:
    :return: the response from the deletion attempt
    """

    ir_id = json.loads(request.GET.get("ir_id", None))
    resp_status = ohdsi_wrappers.delete_ir_analysis(ir_id)
    return JsonResponse({"status": resp_status})


def gen_char_analysis(request):
    """ Generate char analysis callback
    :param request:
    :return: the response from the generation attempt
    """

    char_id = json.loads(request.GET.get("char_id", None))
    resp_status = ohdsi_wrappers.generate_char_analysis(char_id)
    return JsonResponse({}, status=resp_status)


def gen_cp_analysis(request):
    """ Generate pathway analysis callback
    :param request:
    :return: the response from the generation attempt
    """

    cp_id = json.loads(request.GET.get("cp_id", None))
    resp_status = ohdsi_wrappers.generate_cp_analysis(cp_id)
    return JsonResponse({}, status=resp_status)


def get_all_drugs(request):
    """ Get all cached drugs
    :param request:
    :return: all cached drugs
    """
    knw = KnowledgeGraphWrapper()

    all_drugs = knw.get_drugs()
    all_drugs = ["{}{}".format(
        el.name, " - {}".format(el.code) if el.code else "") for el in all_drugs]

    data = {}
    data["drugs"] = all_drugs
    return JsonResponse(data)


def get_medDRA_tree(request):
    """ Get the medDRA hierarchy tree
    :param request: The request from which the medDRA tree will be retrieved
    :return: The medDRA hierarchy tree
    """
    knw = KnowledgeGraphWrapper()

    data = {}
    data["medDRA_tree"] = knw.get_medDRA_tree()
    return JsonResponse(data)


def get_conditions_nodes_ids(request):
    """ Get the ids of the tree nodes containing the condition we want
    :param request:
    :return: the condition ids containing the ids of the conditions contained in
    the url as parameters
    """

    req_conditions = json.loads(request.GET.get("conditions", None))

    with open(os.path.join(settings.JSONS_DIR, "medDRA_tree.json")) as fp:
        medDRA_tree_str = fp.read()

    # Find in json string all conditions with ids relevant to conditions' requested
    # rel_conds_lst = [list(map(lambda c: c.replace("\",", ""), re.findall(
    #     "{}___[\S]+?,".format(condition.split(" - ").pop()), medDRA_tree_str))) for condition in req_conditions]
    rel_conds_lst = [list(map(lambda c: c.replace("\",", ""), re.findall(
        "{0}___llt[\S]+?|{0}___pt[\S]+?,".format(condition.split(" - ").pop()), medDRA_tree_str))) for condition in req_conditions]

    rel_conds_lst = list(chain.from_iterable(rel_conds_lst))

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


def get_popover_content(request):
    """ Get the content for popover
    :param request: The request from which the popover scenario content is asked
    :return: The popover content
    """
    try:
        sc = Scenario.objects.get(id=request.GET.get("sc_id", None))
        drugs_rows = "\n".join(["<tr><td>{}</td></tr>".format(d.name or d.code) for d in sc.drugs.all()])
        conditions_rows = "\n".join(["<tr><td>{}</td></tr>".format(c.name or c.code) for c in sc.conditions.all()])
        data = """<table class ='table table-striped table-bordered dt-responsive dt-multilingual nowrap' cellspacing='0' width='100%'>
        <thead><tr><th>{}</th><th>{}</th></tr></thead>
        <tbody>
            <tr><td><table>{}</table></td>
                <td><table>{}</table></td>
            </tr>
        </tbody></table>""".format(_("Φάρμακο/Φάρμακα"), _("Πάθηση/Παθήσεις"), drugs_rows, conditions_rows)

    except Notes.DoesNotExist:
        data = ""
    return HttpResponse(data)


def get_updated_scenarios_ids(request):
    """ Get updated list of scenarios' ids
    :param request:
    :return: the scenarios' ids
    """
    data = {}
    try:
        data["scenarios_ids"] = list(map(lambda el: str(el.id), Scenario.objects.filter(owner=request.user)))
    except Scenario.DoesNotExist:
        data = {}
    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def index(request):

    scenarios = []
    for sc in Scenario.objects.filter(owner=request.user).order_by('-timestamp').all():
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
                              instance=scenario, label_suffix="")

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
        scform = ScenarioForm(label_suffix="",  instance=scenario)

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
                                                              [drugs_cohort] + [conditions_cohort])),
                                                     domain="ir", owner=sc.owner, sid=sc.id)
        ir_ent = ohdsi_wrappers.get_entity_by_name("ir", ir_name)

        if ir_ent:
            ir_id = ir_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_ir(sc.owner, sc.id, [drugs_cohort], [conditions_cohort])
            ir_id = res_json.get("id")

        cp_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name"),
                                                              [drugs_cohort] + conditions_distinct_cohorts)),
                                                     domain="cp", owner=sc.owner, sid=sc.id)
        cp_ent = ohdsi_wrappers.get_entity_by_name("pathway-analysis", cp_name)

        if cp_ent:
            cp_id = cp_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_cp(sc.owner, sc.id, [drugs_cohort], conditions_distinct_cohorts)
            cp_id = res_json.get("id")

    if drugs_cohort or conditions_cohort:
        char_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name", ""),
                                                                filter(None,[drugs_cohort, conditions_cohort]))),
                                                       domain="char", owner=sc.owner, sid=sc.id)

        char_ent = ohdsi_wrappers.get_entity_by_name("cohort-characterization", char_name)

        if char_ent:
            char_id = char_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_char(sc.owner, sc.id,
                                                          list(filter(None, [drugs_cohort, conditions_cohort])))
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
def incidence_rates(request, sc_id, ir_id, view_type="", read_only=1):
    """ Add or edit incidence rates (ir) view. Retrieve the specific ir that ir_id refers to
    :param request: request
    :param ir_id: the specific ir record's id
    :param sc_id: the specific scenario's id
    :param view_type: quickview for quick view or "" for detailed view
    :param read_only: 0 if False 1 if True
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    try:
        scenario = Scenario.objects.get(id=sc_id)
    except Scenario.DoesNotExist:
        scenario = None

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
        irform = IRForm(request.POST, label_suffix="", ir_options=ir_options, read_only=read_only)

        if irform.is_valid():

            ir_options["age"] = irform.cleaned_data.get("age")
            ir_options["ext_age"] = irform.cleaned_data.get("ext_age")
            ir_options["age_crit"] = irform.cleaned_data.get("age_crit")

            ir_options["genders"] = irform.cleaned_data.get("genders")
            ir_options["study_start_date"] = str(irform.cleaned_data.get("study_start_date"))
            ir_options["study_end_date"] = str(irform.cleaned_data.get("study_end_date"))

            rstatus, rjson = ohdsi_wrappers.update_ir(ir_id, **ir_options)

            if rstatus == 200:
                messages.success(
                    request,
                    _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))
                return HttpResponseRedirect(reverse('edit_ir', args=(sc_id, ir_id, )))
            else:
                messages.error(
                    request,
                    _("Συνέβη κάποιο σφάλμα. Παρακαλώ προσπαθήστε ξανά!"))
                results_url = "{}/#/iranalysis/{}/{}".format(settings.OHDSI_ATLAS, ir_id, view_type)

                context = {
                    # "delete_switch": delete_switch,
                    "sc_id": sc_id,
                    "scenario": scenario,
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
            results_url = "{}/#/iranalysis/{}?{}".format(settings.OHDSI_ATLAS, ir_id, view_type)

            context = {
                # "delete_switch": delete_switch,
                "sc_id": sc_id,
                "scenario": scenario,
                "ir_id": ir_id,
                "results_url": results_url,
                "read_only": read_only,
                "form": irform,
                "title": _("Ανάλυση Ρυθμού Επίπτωσης")
            }
            return render(request, 'app/ir.html', context, status=400)

    # GET request method
    else:
        irform = IRForm(label_suffix="", ir_options=ir_options, read_only=read_only)


    results_url = "{}/#/iranalysis/{}?{}".format(settings.OHDSI_ATLAS, ir_id, view_type)

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
        " {} ".format(_("και")).join([str(ir_options.get("age")), str(ir_options.get("ext_age"))]
                                     ) if ir_options.get("age_crit") in ["bt", "!bt"] else str(ir_options.get("age")))\
        if ir_options.get("age_crit") else _("Δεν έχει οριστεί συγκεκριμένο ηλικιακό κριτήριο!")

    genders_dict = dict([("MALE", _("Άρρεν")), ("FEMALE", _("Θήλυ"))])
    additional_info["gender_crit_info"] = "{} {}".format(
        _("Κριτήριο φύλου:"), " {} ".format(_("και")).join([str(genders_dict.get(k)) for k in ir_options.get("genders")])) \
        if ir_options.get("genders") else _("Δεν έχει οριστεί συγκεκριμένο κριτήριο για το φύλο!")



    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "scenario": scenario,
        "ir_id": ir_id,
        "results_url": results_url,
        "read_only": read_only,
        "form": irform,
        "add_info": additional_info,
        "ohdsi_endpoint": settings.OHDSI_ENDPOINT,
        "ohdsi_cdm_name": settings.OHDSI_CDM_NAME,
        "title": _("Ανάλυση Ρυθμού Επίπτωσης")
    }

    return render(request, 'app/ir.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def characterizations(request, sc_id, char_id, view_type="", read_only=1):
    """ Add or edit characterizations view. Retrieve the specific characterization analysis
     that char_id refers to
    :param request: request
    :param char_id: the specific characterization record's id
    :param sc_id: the specific scenario's id
    :param view_type: quickview for quick view or "" for detailed view
    :param read_only: 0 if False 1 if True
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    try:
        scenario = Scenario.objects.get(id=sc_id)
    except Scenario.DoesNotExist:
        scenario = None

    char_url = "{}/cohort-characterization/{}".format(settings.OHDSI_ENDPOINT, char_id)

    char_exists = ohdsi_wrappers.url_exists(char_url)
    char_options = {}
    if char_exists:
        char_options = ohdsi_wrappers.get_char_options(char_id)
    elif char_id:
        messages.error(
            request,
            _("Δεν βρέθηκε χαρακτηρισμός πληθυσμού με το συγκεκριμένο αναγνωριστικο!"))

    if view_type == "quickview":
        char_options["features"] = char_options.get("features", []) + list(map(lambda el: el.get("id"), filter(
            lambda f: f.get("name") == "Drug Group Era Long Term", ohdsi_wrappers.get_char_analysis_features())))
        rstatus, rjson = ohdsi_wrappers.update_char(char_id, **char_options)

    if request.method == 'POST':
        # sc_id = sc_id or request.POST.get("sc_id")
        char_form = CharForm(request.POST, label_suffix="", char_options=char_options, read_only=read_only)

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


        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            status_code = 400

    # GET request method
    else:
        char_form = CharForm(label_suffix="", char_options=char_options, read_only=read_only)
        status_code = 200

    results_url = "{}/#/cc/characterizations/{}?{}".format(settings.OHDSI_ATLAS, char_id, view_type)

    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "scenario": scenario,
        "char_id": char_id,
        "results_url": results_url,
        "view_type": view_type,
        "read_only": read_only,
        "form": char_form,
        "title": _("Χαρακτηρισμός Ομάδας Ασθενών")
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
        "title": _("Έκθεση σε Φάρμακα"),
        "ohdsi_atlas": settings.OHDSI_ATLAS
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
        "title": _("Εκδήλωση Κατάστασης")
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

    try:
        scenario = Scenario.objects.get(id=sc_id)
    except Scenario.DoesNotExist:
        scenario = None

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
        cp_form = PathwaysForm(request.POST, label_suffix="", cp_options=cp_options, read_only=read_only)

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
        cp_form = PathwaysForm(label_suffix="", cp_options=cp_options, read_only=read_only)
        status_code = 200

    results_url = "{}/#/pathways/{}/executions".format(settings.OHDSI_ATLAS, cp_id)

    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "scenario": scenario,
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

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    sc = Scenario.objects.get(id=scenario_id)
    drugs = [d for d in sc.drugs.all()]

    conditions = [c for c in sc.conditions.all()]

    # ac_token = requests.get('access_token')

    all_combs = list(product([d.name.upper() for d in drugs] or [""],
                             [c.name.upper() for c in conditions] or [""]))

    #Create query string for PubMed with all combinations
    if len(all_combs) >= 1 and drugs and conditions:
        string_list = [' AND '.join(item) for item in all_combs]
        final_string = ') OR ('.join(map(str, string_list))
        query = '(' + final_string + ')'
    elif drugs and not conditions:
        ldrugs = [d.name.upper() for d in drugs]
        query = ' AND '.join(map(str, ldrugs))
    elif conditions and not drugs:
        lconditions = [c.name.upper() for c in conditions]
        query = ' OR '.join(map(str, lconditions))
    else:
        query = all_combs[0]

    scenario = {"id": scenario_id,
                "drugs": drugs,
                "conditions": conditions,
                "all_combs": all_combs,
                "owner": sc.owner.username,
                "status": sc.status.status,
                "title": sc.title,
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
            access_token = mend_cookies[0]

            if page_id == None:
                page_id = 1


                results = pubmed_search(query, 0, 10, access_token, begin, last, request.user)
                if results != {}:
                    records.update(results[0])
                    total_results = total_results + results[1]

            else:

                start = 10*page_id - 10

                results = pubmed_search(query, start, 10, access_token, begin, last, request.user)
                if results != {}:
                    records.update(results[0])
                    total_results = total_results + results[1]

            pages_no = ceil(total_results/10) + 1
            # pages_no = (total_results / 10) + 1
            pages = list(range(1, pages_no))
            if first != None and end != None:
                dates = [str(first), str(end)]
            else:
                dates = ['1900', '2022']

            if records == {}:
                return render(request, 'app/LiteratureWorkspace.html', {"scenario": scenario})

            return render(request, 'app/LiteratureWorkspace.html', {"scenario": scenario, 'records': records, 'pages': pages, 'page_id': page_id, 'results': total_results, 'dates':dates})

        except Exception as e:
            print(e)

            url = '/'
            return redirect(url)

    else:
        url = '/'

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



def pubmed_search(query, begin, max, access_token, start, end, user):
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

    w = conduit.Conduit(email= settings.PUBMED_EMAIL, apikey = settings.PUBMED_KEY)
    fetch_pubmed = w.new_pipeline()
    q = query
    if start==None and end==None:
        fetch_pubmed.add_search(
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released',
             'datetype': 'pdat'})

        s = w.run(fetch_pubmed)
        qres = s.get_result()

        total_results = qres.size()
        sid = fetch_pubmed.add_search(
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released', 'retstart': begin, 'retmax': max,
             'datetype': 'pdat'})
        fetch_pubmed.add_fetch({'retmode': 'xml', 'rettype': 'fasta',  'retmax' : 10, 'retstart': begin}, dependency=sid,
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
            {'db': 'pubmed', 'term': q, 'sort': 'Date Released', 'retstart': begin, 'retmax': max, 'mindate': start, 'maxdate':end,
             'datetype': 'pdat'})
        fetch_pubmed.add_fetch({'retmode': 'xml', 'rettype': 'fasta', 'retstart': begin}, dependency=sid,
                               analyzer=PubmedAnalyzer())
        a = w.run(fetch_pubmed)

        res = a.get_result()

    if res == 500:
        url = 'app/errors/500.html'
        return render( url, status=500)


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
            res.pubmed_records[i].authors = ';'.join(str(x['lname'] + "," + x['fname'].replace(' ', "")) if x['fname'] else str(x['lname']) for x in res.pubmed_records[i].authors )


            Entrez.email = settings.ENTREZ_EMAIL
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

                if PubMed.objects.get(pid=res.pubmed_records[i].pmid, user=user):
                    pubmed = PubMed.objects.get(pid=res.pubmed_records[i].pmid, user=user)
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
    pid = request.GET.get("pmid", None)
    title = request.GET.get("title", None)
    abstract = request.GET.get("abstract", None)
    pubdate = request.GET.get("pubmeddate", None)
    authors = request.GET.get("authors", None)
    url = request.GET.get("url", None)
    user = request.user

    scenario = Scenario.objects.get(id=scenario_id)

    req_notes = request.GET.get("notes", None)
    notes, _ = Notes.objects.update_or_create(user=user, scenario=scenario, workspace=settings.WORKSPACES.get("PubMed"),
                                              wsview=title) if req_notes else (None, None)

    try:
        pm = PubMed.objects.get(scenario_id=scenario, user=user, pid=pid)
        pm.notes = notes
        if relevance:
            pm.relevance = relevance
    except PubMed.DoesNotExist:
        pm = PubMed(user=user, pid=pid, title=title, abstract=abstract, pubdate=pubdate, authors=authors,
                    url=url, relevance=relevance, notes=notes, scenario_id =scenario)

    try:
        if notes:
            notes.content = req_notes
            notes.note_datetime = datetime.datetime.now()
            notes.save()
        pm.save()
        data = {
            'message': 'Success'
        }
    except Exception as e:
        print(e)
        data = {
            'message': 'Failure'
        }
    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def paper_notes_view(request, scenario_id=None, first=None, end=None, page_id=None):
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
        metainfo['relevance'] = request.POST.get("relevance")
        metainfo['notes'] = request.POST.get("notes")
        metainfo['med'] = request.POST.get("med")
        metainfo['pubdate'] = request.POST.get("pubdate")
        metainfo['scenario_id'] = request.POST.get("scenarioid")
        metainfo['user'] = request.user


    return render(request, 'app/paper_notes.html', {'metainfo': metainfo})


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def keep_notes(request, ws_id, wsview_id, sc_id=None):
    """ Add or edit notes as a user for a specific view in a workspace of a scenario
    :param request: request
    :param ws_id:  the workspace's id
    :param wsview_id: the workspace's view id
    :param sc_id: the specific scenario's id.
    Can be None in the cases of drug exposure and condition occurence views in OHDSI workspace
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
        notes_form = NotesForm(request.POST, instance=nobj, label_suffix="")
        # sc_id = sc_id or request.POST.get("sc_id")

        if notes_form.is_valid():
            nf = notes_form.save(commit=False)
            nf.user = tmp_user
            nf.workspace = tmp_workspace
            nf.scenario = tmp_scenario
            nf.wsview = wsview_id

            nf.save()

            messages.success(
                request,
                _("Επιτυχής αποθήκευση!"))
            return HttpResponseRedirect(reverse('keep_notes', args=tuple(filter(None,(sc_id, ws_id, wsview_id)))))

        else:
            messages.error(
                request,
                _("Αποτυχία αποθήκευσης, λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            status_code = 400

    # GET request method
    else:
        notes_form = NotesForm(instance=nobj, label_suffix="")
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

def delete_note_obj(request):
    """ Delete note object
    :param request: request
    :param note_id: the id of the note to be deleted
    :return: httpResponse of the deletion attempt
    """
    try:
        note_id = request.GET.get("note_id", None)
        nobj = Notes.objects.get(id=note_id)
        return delete_db_rec(nobj)
    except Notes.DoesNotExist:
        resp_status = 400
        resp_message = _("Δυστυχώς η διαγραφή αυτή, δεν ήταν δυνατόν να ολοκληρωθεί!")

        return HttpResponse(content=resp_message,
                            status=resp_status)


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
        views_dict = {"ir": _("Ρυθμός Επίπτωσης"), "char": _("Χαρακτηρισμός Ομάδας Ασθενών"),
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
    """ Add, edit or view aggregated the notes kept for user's scenarios (version in use)
    :param request: request
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    tmp_user = User.objects.get(username=request.user)

    rev_workspaces = {v: k for k, v in settings.WORKSPACES.items()}

    user_notes = [{
        "id": unote.id, "scenario": unote.scenario, "note_datetime": unote.note_datetime,
        "workspace": rev_workspaces.get(unote.workspace), "wsview": unote.wsview, "content": unote.content
    } for unote in Notes.objects.filter(user=tmp_user).order_by('-note_datetime')]

    context = {"user_notes": user_notes, "abbrv_views": settings.ABBRV_VIEWS}
    return render(request, 'app/all_notes.html', context)


def openfda_screenshots_exist(request):
    """ An ajax callback checking if there is at least one screenshot for the specific user, scenario pair (hashes
    parameter corresponds to that drug-condition combinations' hashes for that pair) on the server hosting the
    screenshots for openfda workspace
    :param request: The request from which hashes are retrieved and this function is called
    :return: true or false, depending on whether the specific screenshot files were found or not on server
    """
    # r = requests.get(settings.SHINY_SCREENSHOTS_ENDPOINT)
    # soup = BeautifulSoup(r.text, 'html.parser')
    # existing_files = filter(lambda lnk: "." in lnk, map(lambda link: link['href'], soup.find_all('a', href=True)))

    ls_resp = requests.get("{}list-media-files".format(settings.SHINY_SCREENSHOTS_ENDPOINT.replace("media/", "")),
        auth=HTTPBasicAuth(settings.SHINY_SHOTS_SERVICES_USER, settings.SHINY_SHOTS_SERVICES_PASS))
    existing_files = ls_resp.json() if ls_resp.status_code == 200 else []

    hashes = ast.literal_eval(html.unescape(request.GET.get("hashes", None)))

    found_files = list(filter(lambda fname: re.match("^[a-z0-9]*", fname).group() in hashes, existing_files))
    ret = {}
    ret["exist"] = (len(found_files) != 0)

    return JsonResponse(ret)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def final_report(request, scenario_id=None):
    """ Create a final report that contains every information that you
    select from OHDSI and OpedFDA workspace
    :param scenario_id: the specific scenario, new scenario or None
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    request.session["twitter_shots_checked"] = (request.POST.get("twitter_shots_checked", "false") != "false")\
        if list(filter(lambda p: p in request.META.get('HTTP_REFERER'), ["final_report", "report_pdf"])) else False

    ohdsi_tmp_img_path = os.path.join(settings.MEDIA_ROOT, 'ohdsi_img_print')
    try:
        os.mkdir(ohdsi_tmp_img_path, mode=0o770)
    except FileExistsError as e:
        pass

    try:
        sc = Scenario.objects.get(id=scenario_id)
    except Exception as e:
        error_response = HttpResponse(content=str(e), status=500)
        return error_response

    drugs = sc.drugs.all()
    conditions = sc.conditions.all()

    all_combs = list(product([d for d in drugs] or [None],
                             [c for c in conditions] or [None]))

    scenario_open = sc.id

    drug_condition_hash = []

    for i in range(len(all_combs)):
        p = sc.title+str(sc.owner)+str(i)
        h = hashlib.md5(repr(p).encode('utf-8'))
        hash = h.hexdigest()

        drug_condition_hash.append(list(all_combs[i])+[hash])

    hashes = list(map(lambda dch: dch[2], drug_condition_hash))

    # if request.build_absolute_uri(request.get_full_path()) == request.META.get('HTTP_REFERER'):
    # Delete all files containing any of the hashes in their filename (to make sure new ones will be created)
    requests.delete("{}delete-media-files".format(
        settings.SHINY_SCREENSHOTS_ENDPOINT.replace("media/", "")),
        auth=HTTPBasicAuth(settings.SHINY_SHOTS_SERVICES_USER, settings.SHINY_SHOTS_SERVICES_PASS),
        params={"hashes": hashes})

    user = sc.owner

    pub_objs = PubMed.objects.filter(scenario_id=scenario_open, relevance=True)

    notes_openfda1 = {}
    if Notes.objects.filter(user=user, scenario=scenario_open) != "":
        user_notes = Notes.objects.filter(user=user).order_by("scenario", "workspace", "wsview")
        notes_wsview_openfda = list(map(lambda el: el.wsview, filter(lambda elm: elm.workspace == 2, user_notes)))
        dict_openfda_notes = {}
        for i in notes_wsview_openfda:
            notes_content_openfda = list(map(lambda el: el.content, filter(lambda elm: elm.wsview == i, user_notes)))
            dict_openfda_notes[i] = notes_content_openfda[0]

        notes_openfda1 = dict([(k, dict_openfda_notes.get(" - ".join(list(filter(None, [i and i.name, j and j.name]))))
                                ) for i,j,k in drug_condition_hash])

    sc_drugs = sc.drugs.all()
    sc_conditions = sc.conditions.all()

    # Get drugs concept set id
    drugs_names = ohdsi_wrappers.name_entities_group([d.name for d in sc_drugs], domain="Drug") if len(sc_drugs) != 1 \
        else "Drug - {}".format(sc_drugs[0].name)
    condition_names = ohdsi_wrappers.name_entities_group([c.name for c in sc_conditions], domain="Condition"
                                                         ) if len(sc_conditions) != 1 \
        else "Condition - {}".format(sc_conditions[0].name)


    ir_name = ohdsi_wrappers.name_entities_group([drugs_names] + [condition_names], domain="ir",
                                                 owner=sc.owner, sid=sc.id)

    ir_ent = ohdsi_wrappers.get_entity_by_name("ir", ir_name)
    if ir_ent:
        ir_id = ir_ent.get("id")
    else:
        ir_id = None

    char_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c, filter(None, [drugs_names, condition_names]))),
                                                   domain="char", owner=sc.owner, sid=sc.id)
    char_ent = ohdsi_wrappers.get_entity_by_name("cohort-characterization", char_name)
    if char_ent:
        char_id = char_ent.get("id")
    else:
        char_id = None

    conditions_distinct_names = list(map(lambda c: "Condition - {}".format(c.name), sc_conditions))
    cp_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c, [drugs_names] + conditions_distinct_names)),
                                                 domain="cp", owner=sc.owner, sid=sc.id)
    cp_ent = ohdsi_wrappers.get_entity_by_name("pathway-analysis", cp_name)
    if cp_ent:
        cp_id = cp_ent.get("id")
    else:
        cp_id = None

    try:
        files = glob.glob(os.path.join(ohdsi_tmp_img_path, "*_{}_{}.png".format(sc.owner_id, sc.id)))
        for f in files:
            os.remove(f)
    except:
        pass

    try:
        ir_notes = Notes.objects.get(user=sc.owner, scenario=sc.id, workspace=1, wsview="ir")
        ir_notes = ir_notes.content
    except:
        ir_notes = ""

    try:
        char_notes = Notes.objects.get(user=sc.owner, scenario=sc.id, workspace=1, wsview="char")
        char_notes = char_notes.content
    except:
        char_notes = ""

    try:
        pathways_notes = Notes.objects.get(user=sc.owner, scenario=sc.id, workspace=1, wsview="pathways")
        pathways_notes = pathways_notes.content
    except:
        pathways_notes = ""

    ohdsi_sh = ohdsi_shot.OHDSIShot()
    char_generate = "no"
    cp_generate = "no"
    ir_generate = "no"
    img_path = os.path.join(settings.MEDIA_ROOT, "ohdsi_img")

    try:
        os.mkdir(img_path, mode=0o770)
    except FileExistsError as e:
        pass

    intro = os.path.join(settings.MEDIA_URL, "ohdsi_img")  # img_path  # "/static/images/ohdsi_img/"

    # Prepare lists for threading functions, parameters and results
    threads_funcs = []
    threads_shot_urls = []
    threads_fnames = []
    threads_shoot_elms = []
    threads_tbls_len = []
    threads_store_path = []
    threads_results = []

    if char_id != None:
        response = requests.get('{}/cohort-characterization/{}/generation'.format(settings.OHDSI_ENDPOINT, char_id))
        resp_number = response.json()

        if resp_number != []:
            resp_num_id = resp_number[0]['id']
            if resp_num_id == [] or resp_number[0]['status'] != "COMPLETED":
                char_generate = "no"
            else:
                char_generate = "yes"
                # if "pre_table_{}_{}.png".format(sc.owner_id, sc.id) not in entries:
                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["pre_table_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("All prevalence covariates", "table")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("pre_table",
                                       os.path.join(intro, "pre_table_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["pre_chart_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("All prevalence covariates", "chart")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("pre_chart",
                                        os.path.join(intro, "pre_chart_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["drug_table_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("DRUG / Drug Group Era Long Term", "table")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("drug_table",
                                        os.path.join(intro, "drug_table_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["drug_chart_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("DRUG / Drug Group Era Long Term", "chart")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("drug_chart",
                                        os.path.join(intro, "drug_chart_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["demograph_table_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("DEMOGRAPHICS / Demographics Age Group", "table")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("demograph_table",
                                        os.path.join(intro, "demograph_table_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["demograph_chart_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("DEMOGRAPHICS / Demographics Age Group", "chart")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("demograph_chart",
                                        os.path.join(intro, "demograph_chart_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["charlson_table_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("CONDITION / Charlson Index", "table")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("charlson_table",
                                        os.path.join(intro, "charlson_table_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["charlson_chart_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("CONDITION / Charlson Index", "chart")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("charlson_chart",
                                        os.path.join(intro, "charlson_chart_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["gen_table_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("DEMOGRAPHICS / Demographics Gender", "table")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("gen_table",
                                        os.path.join(intro, "gen_table_{}_{}.png".format(sc.owner_id, sc.id))))

                threads_funcs.append(ohdsi_sh.cc_shot)
                threads_shot_urls.append("{}/#/cc/characterizations/{}/results/{}".format(
                    settings.OHDSI_ATLAS, char_id, resp_num_id))
                threads_fnames.append(["gen_chart_{}_{}.png".format(sc.owner_id, sc.id)])
                threads_shoot_elms.append([("DEMOGRAPHICS / Demographics Gender", "chart")])
                threads_tbls_len.append(10)
                threads_store_path.append(img_path)
                threads_results.append(("gen_chart",
                                        os.path.join(intro, "gen_chart_{}_{}.png".format(sc.owner_id, sc.id))))

    if cp_id != None:
        response = requests.get('{}/pathway-analysis/{}/generation'.format(settings.OHDSI_ENDPOINT, cp_id))
        resp_number_cp = response.json()
        if resp_number_cp != []:
            resp_num_id_cp = resp_number_cp[0]['id']

            if resp_num_id_cp == [] or resp_number_cp[0]['status'] != "COMPLETED":
                cp_generate = "no"
            else:
                cp_generate = "yes"
                # if "pw_{}_{}.png".format(sc.owner_id, sc.id) not in entries:
                threads_funcs.append(ohdsi_sh.pathways_shot)
                threads_shot_urls.append("{}/#/pathways/{}/results/{}".format(
                    settings.OHDSI_ATLAS, cp_id, resp_num_id_cp))
                threads_fnames.append("pw_{}_{}.png".format(sc.owner_id, sc.id))
                threads_shoot_elms.append("all")
                threads_tbls_len.append(None)
                threads_store_path.append(img_path)
                threads_results.append(("path_all",
                                        os.path.join(intro, "pw_{}_{}.png".format(sc.owner_id, sc.id))))

    try:
        if ir_id != None:
            ir_generate = "yes"

            threads_funcs.append(ohdsi_sh.ir_shot)
            threads_shot_urls.append("{}/#/iranalysis/{}".format(settings.OHDSI_ATLAS, ir_id))
            threads_fnames.append("irtable_{}_{}.png".format(sc.owner_id, sc.id))
            threads_shoot_elms.append("table")
            threads_tbls_len.append(None)
            threads_store_path.append(img_path)
            threads_results.append(("ir_table",
                                    os.path.join(intro, "irtable_{}_{}.png".format(sc.owner_id, sc.id))))

            threads_funcs.append(ohdsi_sh.ir_shot)
            threads_shot_urls.append("{}/#/iranalysis/{}".format(settings.OHDSI_ATLAS, ir_id))
            threads_fnames.append("irall_{}_{}.png".format(sc.owner_id, sc.id))
            threads_shoot_elms.append("all")
            threads_tbls_len.append(None)
            threads_store_path.append(img_path)
            threads_results.append(("ir_all",
                                    os.path.join(intro, "irall_{}_{}.png".format(sc.owner_id, sc.id))))

    except:
        ir_generate = "no"

    str_to_var = {}
    with concurrent.futures.ThreadPoolExecutor(13) as executor:
        futures = []
        for i in range(len(threads_funcs)):
            args = [arg for arg in [threads_shot_urls[i], threads_fnames[i], threads_shoot_elms[i],
                                    threads_tbls_len[i], threads_store_path[i]] if arg]
            futures.append(
                executor.submit(
                    threads_funcs[i], *args
                )
            )

        for future in concurrent.futures.as_completed(futures):
            try:
                for res in future.result():
                    if res[0]:
                        str_to_var.update(dict(filter(lambda el: el[1] in res[1], threads_results)))
            except (requests.ConnectTimeout, TimeoutException):
                pass

    cc_shots_labels = {"pre_table": _("Πίνακας όλων των συμμεταβλητών επικράτησης"),
                       "pre_chart": _("Διάγραμμα όλων των συμμεταβλητών επικράτησης"),
                       "drug_table": _("Πίνακας Μακροχρόνιας Λήψης Κατηγορίας Φαρμάκων"),
                       "drug_chart": _("Διάγραμμα Μακροχρόνιας Λήψης Κατηγορίας Φαρμάκων"),
                       "demograph_table": _("Πίνακας Δημογραφικών Ηλικιακών Κατηγοριών"),
                       "demograph_chart": _("Διάγραμμα Δημογραφικών Ηλικιακών Κατηγοριών"),
                       "charlson_table": _("Πίνακας Δείκτη Συννοσηρότητας Charlson"),
                       "charlson_chart": _("Διάγραμμα Δείκτη Συννοσηρότητας Charlson"),
                       "gen_table": _("Πίνακας Δημογραφικού Φύλου"),
                       "gen_chart": _("Διάγραμμα Δημογραφικού Φύλου")
                       }

    cc_shots_paths_labels = [(cc_shot, str_to_var.get(cc_shot), cc_shots_labels.get(cc_shot)
                              ) for cc_shot in cc_shots_labels.keys() if str_to_var.get(cc_shot)]


    all_combs_names = list(product(sorted(set([d.name for d in drugs])) or [""],
                             sorted(set([c.name for c in conditions])) or [""]))

    all_combs_names = list(map(lambda el: " ".join(filter(None, el)), all_combs_names))
    p = "twitter" + sc.title + str(sc.owner)
    h = hashlib.md5(repr(p).encode('utf-8'))
    twitter_hash = h.hexdigest()
    twitter_query_url = "{}?twitterQuery={}".format(
        settings.SM_SHINY_ENDPOINT, urllib.parse.quote(" OR ".join(all_combs_names)))

    # if request.build_absolute_uri(request.get_full_path()) == request.META.get('HTTP_REFERER'):
    # Delete all files containing twitter hash in their filename (to make sure new ones will be created)
    requests.delete("{}delete-media-files".format(
        settings.SHINY_SCREENSHOTS_ENDPOINT.replace("media/", "")),
        auth=HTTPBasicAuth(settings.SHINY_SHOTS_SERVICES_USER, settings.SHINY_SHOTS_SERVICES_PASS),
        params={"hashes": [twitter_hash]})

    chrome_options = webdriver.ChromeOptions()
    chrome_options.headless = True
    driver = webdriver.Chrome(options=chrome_options)
    driver.get("{}&hash={}".format(twitter_query_url, twitter_hash))
    try:
        WebDriverWait(driver, 70).until(
            EC.invisibility_of_element_located(
                (By.XPATH, '//div[@class="shiny-loader-output-container"]/div[@class="load-container"]')))
    except TimeoutException:
        return timeout_redirect(request)

    driver.quit()

    ls_resp = requests.get("{}list-media-files".format(settings.SHINY_SCREENSHOTS_ENDPOINT.replace("media/", "")),
                           auth=HTTPBasicAuth(settings.SHINY_SHOTS_SERVICES_USER,
                                              settings.SHINY_SHOTS_SERVICES_PASS))

    existing_files = ls_resp.json() if ls_resp.status_code == 200 else []

    found_files = list(filter(lambda fname: fname.startswith(twitter_hash), existing_files))
    twitter_data_exist = (len(found_files) != 0)

    try:
        twitter_notes = Notes.objects.get(user=sc.owner, scenario=sc.id, workspace=4, wsview="sm")
        twitter_notes = twitter_notes.content
    except:
        twitter_notes = None

    context = {"scenario": sc, "OPENFDA_SHINY_ENDPOINT": settings.OPENFDA_SHINY_ENDPOINT,
               "drug_condition_hash": drug_condition_hash, "notes_openfda1": notes_openfda1, "ir_id": ir_id,
               "char_id": char_id, "cp_id": cp_id, "ir_notes": ir_notes, "char_notes": char_notes,
               "pathways_notes": pathways_notes, "char_generate": char_generate, "cp_generate": cp_generate,
               "ir_generate": ir_generate, "pub_objs": pub_objs, "cc_shots_paths_labels": cc_shots_paths_labels,
               "hashes": hashes, "twitter_query_url": twitter_query_url, "twitter_data_exist": twitter_data_exist,
               "twitter_notes": twitter_notes, "twitter_hash": twitter_hash}

    # Passing all "variables" (i.e. ir_table, ir_all, pre_table etc.) to context
    context.update(str_to_var)

    return render(request, "app/final_report.html", context)


def check_twitter_shots(request):
    """ Turn twitter_shots_checked session variable to true
    :param request: request
    """
    if not request.is_ajax() or not request.method == "POST":
        return HttpResponseNotAllowed(["POST"])

    request.session["twitter_shots_checked"] = (request.POST.get("twitter_shots_checked", "false") != "false")
    return HttpResponse("OK")


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def report_pdf(request, scenario_id=None, report_notes=None, pub_titles=None, pub_notes=None, extra_notes=None):
    """ Generate the preview of final report that contains every information that you
    have chosen from OHDSI and OpedFDA workspace and give you the opportunity to
    return to the final report and change your options and add some extra notes
    to your final report
    :param scenario_id: the specific scenario, new scenario or None
    :param report_notes: notes for every view
    :param pub_titles: selected article titles from pubmed
    :param pub_notes: selected notes from pubmed
    :param extra_notes: last notes in final report
    :return: the form view
    """

    scenario_id = scenario_id or request.GET.get("scenario_id", None)
    sc = Scenario.objects.get(id=scenario_id)

    sc_drugs = sc.drugs.all()
    sc_conditions = sc.conditions.all()

    # Get drugs concept set id
    drugs_names = ohdsi_wrappers.name_entities_group([d.name for d in sc_drugs], domain="Drug",
                                                     owner=sc.owner, sid=sc.id) if len(sc_drugs) != 1 \
        else "Drug - {}".format(sc_drugs[0].name)
    condition_names = ohdsi_wrappers.name_entities_group([c.name for c in sc_conditions], domain="Condition",
                                                         owner=sc.owner, sid=sc.id) if len(sc_conditions) != 1 \
        else "Condition - {}".format(sc_conditions[0].name)

    ir_name = ohdsi_wrappers.name_entities_group([drugs_names] + [condition_names], domain="ir",
                                                 owner=sc.owner, sid=sc.id)

    ir_ent = ohdsi_wrappers.get_entity_by_name("ir", ir_name)
    if ir_ent:
        ir_id = ir_ent.get("id")
    else:
        ir_id = None

    char_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c, filter(None, [drugs_names, condition_names]))),
                                                   domain="char", owner=sc.owner, sid=sc.id)
    char_ent = ohdsi_wrappers.get_entity_by_name("cohort-characterization", char_name)
    if char_ent:
        char_id = char_ent.get("id")
    else:
        char_id = None

    conditions_distinct_names = list(map(lambda c: "Condition - {}".format(c.name), sc_conditions))
    cp_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c, [drugs_names] + conditions_distinct_names)),
                                                 domain="cp", owner=sc.owner, sid=sc.id)
    cp_ent = ohdsi_wrappers.get_entity_by_name("pathway-analysis", cp_name)
    if cp_ent:
        cp_id = cp_ent.get("id")
    else:
        cp_id = None

    kin = 0
    lin = 0

    img_path = os.path.join(settings.MEDIA_ROOT, "ohdsi_img")

    # ir_table_rep=0 if not selected or 1 if user selected
    ir_table_rep = request.GET.get("ir_table_rep", None)
    ir_all_rep = request.GET.get("ir_all_rep", None)
    pre_table_rep = request.GET.get("pre_table_rep", None)
    pre_chart_rep = request.GET.get("pre_chart_rep", None)
    drug_table_rep = request.GET.get("drug_table_rep", None)
    drug_chart_rep = request.GET.get("drug_chart_rep", None)
    demograph_chart_rep = request.GET.get("demograph_chart_rep", None)
    demograph_table_rep = request.GET.get("demograph_table_rep", None)
    charlson_table_rep = request.GET.get("charlson_table_rep", None)
    charlson_chart_rep = request.GET.get("charlson_chart_rep", None)
    gen_table_rep = request.GET.get("gen_table_rep", None)
    gen_chart_rep = request.GET.get("gen_chart_rep", None)
    cp_all_rep = request.GET.get("cp_all_rep", None)

    pub_notes = dict(urllib.parse.parse_qsl(pub_notes)) or json.loads(request.GET.get("allPubNotes", "{}"))
    pub_titles = dict(urllib.parse.parse_qsl(pub_titles)) or json.loads(request.GET.get("allPubTitles", "{}"))
    report_notes = dict(urllib.parse.parse_qsl(report_notes)) or json.loads(request.GET.get("all_notes", "{}"))

    pub_tobjs = PubMed.objects.filter(id__in=pub_titles.values())
    pub_nobjs = PubMed.objects.filter(id__in=pub_notes.values())

    pub_exist = len(pub_tobjs) + len(pub_nobjs)

    if char_id != None:
        response = requests.get('{}/cohort-characterization/{}/generation'.format(settings.OHDSI_ENDPOINT, char_id))
        resp_number = response.json()
        if resp_number != []:
            resp_num_id = resp_number[0]['id']
    if cp_id != None:
        response = requests.get('{}/pathway-analysis/{}/generation'.format(settings.OHDSI_ENDPOINT, cp_id))
        resp_number_cp = response.json()

    ir_dict_t = {}
    ir_dict_a = {}
    coh_dict = {}
    cp_dict = {}
    ind = 0

    ohdsi_tmp_img_path = os.path.join(settings.MEDIA_ROOT, 'ohdsi_img_print')
    try:
        os.mkdir(ohdsi_tmp_img_path, mode=0o770)
    except FileExistsError as e:
        pass
    # print_intro = "/static/images/ohdsi_img_print/"
    image_print = os.listdir(ohdsi_tmp_img_path)

    if cp_all_rep == "1":
        shutil.copy(os.path.join(img_path, "pw_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif cp_all_rep == "0" and "pw_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*pw_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if ir_table_rep == "1":
        shutil.copy(os.path.join(img_path, "irtable_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif ir_table_rep == "0" and "irtable_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*irtable_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if ir_all_rep == "1":
        shutil.copy(os.path.join(img_path, "irall_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif ir_all_rep == "0" and "irall_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*irall_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if pre_table_rep == "1":
        shutil.copy(os.path.join(img_path, "pre_table_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif pre_table_rep == "0" and "pre_table_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*pre_table_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if pre_chart_rep == "1":
        shutil.copy(os.path.join(img_path, "pre_chart_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif pre_chart_rep == "0" and "pre_chart_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*pre_chart_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if drug_table_rep == "1":
        shutil.copy(os.path.join(img_path, "drug_table_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif drug_table_rep == "0" and "drug_table_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*drug_table_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if drug_chart_rep == "1":
        shutil.copy(os.path.join(img_path, "drug_chart_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif drug_chart_rep == "0" and "drug_chart_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*drug_chart_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if demograph_table_rep == "1":
        shutil.copy(os.path.join(img_path, "demograph_table_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif demograph_table_rep == "0" and "demograph_table_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*demograph_table_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if demograph_chart_rep == "1":
        shutil.copy(os.path.join(img_path, "demograph_chart_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif demograph_chart_rep == "0" and "demograph_chart_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*demograph_chart_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if charlson_table_rep == "1":
        shutil.copy(os.path.join(img_path, "charlson_table_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif charlson_table_rep == "0" and "charlson_table_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*charlson_table_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if charlson_chart_rep == "1":
        shutil.copy(os.path.join(img_path, "charlson_chart_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif charlson_chart_rep == "0" and "charlson_chart_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*charlson_chart_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if gen_table_rep == "1":
        shutil.copy(os.path.join(img_path, "gen_table_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif gen_table_rep == "0" and "gen_table_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*gen_table_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    if gen_chart_rep == "1":
        shutil.copy(os.path.join(img_path, "gen_chart_{}_{}.png".format(sc.owner_id, sc.id)), ohdsi_tmp_img_path)
    elif gen_chart_rep == "0" and "gen_chart_{}_{}.png".format(sc.owner_id, sc.id) in image_print:
        dok = glob.glob(os.path.join(ohdsi_tmp_img_path, "*gen_chart_{}_{}.png".format(sc.owner_id, sc.id)))
        os.remove(dok[0])

    image_print = sort_report_screenshots(os.listdir(ohdsi_tmp_img_path))

    for i in image_print:
        ind = ind + 1
        kin = kin + 1
        lin = lin + 1

        # Check if there is any element selected for ir analysis
        if i == "irtable_{}_{}.png".format(sc.owner_id, sc.id):
            ir_dict_t["{} {} - {}".format(_("Πίνακας"), ind, _(
                "Πίνακας Ρυθμού Επίπτωσης"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "irall_{}_{}.png".format(sc.owner_id, sc.id):
            ir_dict_a["{} {} - {}".format(_("Πίνακας και διάγραμμα θερμικού χάρτη"), ind, _(
                "Πίνακας και διάγραμμα θερμικού χάρτη Ρυθμού Επίπτωσης"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        # Check if there is any element selected for char analysis
        if i == "charlson_table_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Πίνακας"), ind, _("Πίνακας ΚΑΤΑΣΤΑΣΗΣ / Δείκτη Συννοσηρότητας Charlson"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "charlson_chart_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Διάγραμμα"), ind, _(
                "Διάγραμμα ΚΑΤΑΣΤΑΣΗΣ / Δείκτη Συννοσηρότητας Charlson"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "demograph_table_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Πίνακας"), ind, _(
                "Πίνακας ΔΗΜΟΓΡΑΦΙΚΩΝ ΣΤΟΙΧΕΙΩΝ / Δημογραφικών Ηλικιακών Κατηγοριών"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "demograph_chart_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Διάγραμμα"), ind, _(
                "Διάγραμμα ΔΗΜΟΓΡΑΦΙΚΩΝ ΣΤΟΙΧΕΙΩΝ / Δημογραφικών Ηλικιακών Κατηγοριών"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "drug_table_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Πίνακας"), ind, _(
                "Πίνακας ΦΑΡΜΑΚΩΝ / Μακροχρόνιας Λήψης Κατηγορίας Φαρμάκων"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "drug_chart_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Διάγραμμα"), ind, _(
                "Διάγραμμα ΦΑΡΜΑΚΩΝ / Μακροχρόνιας Λήψης Κατηγορίας Φαρμάκων"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "gen_table_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Πίνακας"), ind, _(
                "Πίνακας ΔΗΜΟΓΡΑΦΙΚΩΝ ΣΤΟΙΧΕΙΩΝ / Δημογραφικού Φύλου"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "gen_chart_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Διάγραμμα"), ind, _(
                "Διάγραμμα ΔΗΜΟΓΡΑΦΙΚΩΝ ΣΤΟΙΧΕΙΩΝ / Δημογραφικού Φύλου"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "pre_table_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Πίνακας"), ind, _(
                "Πίνακας όλων των συμμεταβλητών επικράτησης"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        if i == "pre_chart_{}_{}.png".format(sc.owner_id, sc.id):
            coh_dict["{} {} - {}".format(_("Διάγραμμα"), ind, _(
                "Διάγραμμα όλων των συμμεταβλητών επικράτησης"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

        # Check if there is any element selected for pathways analysis
        if i == "pw_{}_{}.png".format(sc.owner_id, sc.id):
            cp_dict["{} {} - {}".format(_("Διάγραμμα"), ind, _(
                "Διάγραμμα Ανάλυσης Μονοπατιού"))
            ] = os.path.join(settings.MEDIA_URL, 'ohdsi_img_print', i)

    scenario = sc.title
    drugs = [d for d in sc.drugs.all()]
    conditions = [c for c in sc.conditions.all()]
    all_combs = list(product([d.name for d in drugs] or [""],
                             [c.name for c in conditions] or [""]))

    drug_condition_hash = []

    for i in range(len(all_combs)):
        p = sc.title+str(sc.owner)+str(i)
        h = hashlib.md5(repr(p).encode('utf-8'))
        hash = h.hexdigest()

        drug_condition_hash.append(list(all_combs[i])+[hash])

    r = requests.get(settings.SHINY_SCREENSHOTS_ENDPOINT)
    soup = BeautifulSoup(r.text, 'html.parser')

    dict_quickview = {}
    dictpng = {}
    dictcsv = {}
    dict_dash_csv = {}
    dict_rr_d = {}
    dict_rr_e = {}
    dict_lr = {}
    dict_lre = {}
    dict_dashboard_png = {}
    dict_lrTest_png = {}
    dict_lreTest_png = {}
    dict1 = {}
    dict2 = {}
    dict3 = {}
    dict_hash_combination = {}

    for i, j, k in drug_condition_hash:

        if i != "" and j != "":
            no_comb = 'combination'

            dict_hash_combination[k] = i + ' - ' + j
            files_png = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_timeseries".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))

            files_csv = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_timeseries_prr".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            if files_png:
                dict1.setdefault(k, []).append(files_png[0])
                kin = kin + 1
                dict1.setdefault(k, []).append("{} {}".format(_("Εικόνα"), kin))

            else:
                dict1.setdefault(k, []).append("")
                dict1.setdefault(k, []).append("")

            if files_csv:
                df1 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, files_csv[0])))
                styler1 = df1.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict1.setdefault(k, []).append(styler1.render())
                kin = kin + 1
                dict1.setdefault(k, []).append("{} {}".format(_("Πίνακας"), kin))
            else:
                dict1.setdefault(k, []).append("")
                dict1.setdefault(k, []).append("")

            dynprr_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_prrplot".format(k) in elm,
                                     map(lambda el: el.get_text(), soup.find_all('a'))))
            dynprr_csv = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_prrcounts".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            dynprr_csv1 = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_concocounts".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            dynprr_csv2 = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_eventcounts".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            if dynprr_png:
                dict2.setdefault(k, []).append(dynprr_png[0])
                kin = kin + 1
                dict2.setdefault(k, []).append("{} {}".format(_("Εικόνα"), kin))
            else:
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")

            if dynprr_csv:
                dict2.setdefault(k, []).append(" - {}".format(_("Πλήθος αναφορών και PRR")))
                df1 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dynprr_csv[0])))
                styler1 = df1.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict2.setdefault(k, []).append(styler1.render())
                kin = kin + 1
                dict2.setdefault(k, []).append("{} {}".format(_("Πίνακας"), kin))

            else:
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")

            if dynprr_csv1:
                dict2.setdefault(k, []).append(" - {}".format(_("Φάρμακα στις επιλεγμένες αναφορές")))
                df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dynprr_csv1[0])))
                styler2 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict2.setdefault(k, []).append(styler2.render())
                kin = kin + 1
                dict2.setdefault(k, []).append("{} {}".format(_("Πίνακας"), kin))
            else:
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")

            if dynprr_csv2:
                dict2.setdefault(k, []).append(" - {}".format(_("Συμβάντα στις επιλεγμένες αναφορές")))
                df3 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dynprr_csv2[0])))
                styler3 = df3.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict2.setdefault(k, []).append(styler3.render())
                kin = kin + 1
                dict2.setdefault(k, []).append("{} {}".format(_("Πίνακας"), kin))
            else:
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")
                dict2.setdefault(k, []).append("")

            changep_png = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_cpmeanplot".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_png1 = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_cpvarplot".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_png2 = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_cpbayesplot".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_png3 = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_yearplot".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_csv = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_codrugs".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            changep_csv1 = list(
                filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_qevents".format(k) in elm,
                       map(lambda el: el.get_text(), soup.find_all('a'))))
            if changep_png:
                dict3.setdefault(k, []).append(" - {}".format(_("Ανάλυση μεταβολής μέσου")))
                dict3.setdefault(k, []).append(changep_png[0])
                kin = kin + 1
                dict3.setdefault(k, []).append("{} {}".format(_("Εικόνα"), kin))

            else:
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")

            if changep_png1:
                dict3.setdefault(k, []).append(" - {}".format(_("Ανάλυση μεταβολής διακύμανσης")))
                dict3.setdefault(k, []).append(changep_png1[0])
                kin = kin + 1
                dict3.setdefault(k, []).append("{} {}".format(_("Εικόνα"), kin))

            else:
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")

            if changep_png2:
                dict3.setdefault(k, []).append(" - {}".format(_("Μπεϋζιανή ανάλυση σημείου αλλαγής")))
                dict3.setdefault(k, []).append(changep_png2[0])
                kin = kin + 1
                dict3.setdefault(k, []).append("{} {}".format(_("Εικόνα"), kin))
            else:
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")

            if changep_png3:
                dict3.setdefault(k, []).append(" - {}".format(_("Πλήθος αναφορών ανά ημερομηνία")))
                dict3.setdefault(k, []).append(changep_png3[0])
                kin = kin + 1
                dict3.setdefault(k, []).append("{} {}".format(_("Εικόνα"), kin))
            else:
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")

            if changep_csv:
                dict3.setdefault(k, []).append(" - {}".format(_("Φάρμακα στις επιλεγμένες αναφορές")))
                df3 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, changep_csv[0])))
                styler3 = df3.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict3.setdefault(k, []).append(styler3.render())
                kin = kin + 1
                dict3.setdefault(k, []).append("{} {}".format(_("Πίνακας"), kin))
            else:
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")

            if changep_csv1:
                dict3.setdefault(k, []).append(" - {}".format(_("Συμβάντα στις επιλεγμένες αναφορές")))
                df3 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, changep_csv1[0])))
                styler3 = df3.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
                dict3.setdefault(k, []).append(styler3.render())
                kin = kin + 1
                dict3.setdefault(k, []).append("{} {}".format(_("Πίνακας"), kin))
            else:
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")
                dict3.setdefault(k, []).append("")

    if i == "" or j == "":
        no_comb = ""
        files_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_timeseries".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
        files_csv = list(
            filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_timeseries_prr".format(k) in elm,
                   map(lambda el: el.get_text(), soup.find_all('a'))))
        if files_png:
            dictpng[k] = files_png[0]
            dict_quickview.setdefault(i, []).append(files_png[0])
            lin = lin + 1
            dict_quickview.setdefault(k, []).append("{} {}".format(_("Εικόνα"), lin))
        else:
            dict_quickview.setdefault(i, []).append("")
            dict_quickview.setdefault(i, []).append("")

        if files_csv:
            dictcsv[k] = files_csv[0]
            df1 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dictcsv[k])))
            styler1 = df1.loc[:9].style.hide_columns(['Unnamed: 0', 'Definition']).hide_index()
            dict_quickview.setdefault(i, []).append(styler1.render())
            lin = lin + 1
            dict_quickview.setdefault(k, []).append("{} {}".format(_("Πίνακας"), lin))

    #for drug only
    if j == "":
        dash_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_primary".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
        dash_png1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_serious".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
        dash_png2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_sexplot".format(k) in elm,
                                  map(lambda el: el.get_text(), soup.find_all('a'))))
        if dash_png:
            lin = lin + 1
            dict_dashboard_png[dash_png[0]] = "Figure {}".format(lin)

        if dash_png1:
            lin = lin + 1
            dict_dashboard_png[dash_png1[0]] = "Figure {}".format(lin)

        if dash_png2:
            lin = lin + 1
            dict_dashboard_png[dash_png2[0]] = "Figure {}".format(lin)

        dash_csv = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_event".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
        dash_csv1 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_concomitant".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))
        dash_csv2 = list(filter(lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_indication".format(k) in elm,
                                map(lambda el: el.get_text(), soup.find_all('a'))))

        if dash_csv:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dash_csv[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_dash_csv.setdefault(" {}".format(_("Συμβάντα")), []).append(styler1.render())
            lin = lin+1
            dict_dash_csv.setdefault(" {}".format(_("Συμβάντα")), []).append("{} {}".format(_("Πίνακας"), lin))
        if dash_csv1:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dash_csv1[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_dash_csv.setdefault(" {}".format(_("Συγχορηγούμενα Φάρμακα")), []).append(styler1.render())
            lin = lin + 1
            dict_dash_csv.setdefault(" {}".format(_("Συγχορηγούμενα Φάρμακα")), []).append("{} {}".format(_("Πίνακας"), lin))

        if dash_csv2:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, dash_csv2[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_dash_csv.setdefault(" {}".format(_("Ενδείξεις")), []).append(styler1.render())
            lin = lin + 1
            dict_dash_csv.setdefault(" {}".format(_("Ενδείξεις")), []).append("{} {}".format(_("Πίνακας"), lin))

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
        if rr_d_csv4:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_d_csv4[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_d.setdefault(" {}".format(_("Αποτελέσματα PRR και ROR")), []).append(styler1.render())
            lin = lin + 1
            dict_rr_d.setdefault(" {}".format(_("Αποτελέσματα PRR και ROR")), []).append(
                "{} {}".format(_("Πίνακας"), lin))
        if rr_d_csv5:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_d_csv5[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_d.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για συγκεκριμένο φάρμακο")),
                                 []).append(styler1.render())
            lin = lin + 1
            dict_rr_d.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για συγκεκριμένο φάρμακο")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))
        if rr_d_csv2:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_d_csv2[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_d.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για όλα τα φάρμακα")),
                                 []).append(styler1.render())
            lin = lin + 1
            dict_rr_d.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για όλα τα φάρμακα")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))

        if rr_d_csv1:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_d_csv1[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_d.setdefault(" {}".format(_("Ταξινομημένες μετρήσεις συμβάντων για φάρμακο")),
                                 []).append(styler1.render())
            lin = lin + 1
            dict_rr_d.setdefault(" {}".format(_("Ταξινομημένες μετρήσεις συμβάντων για φάρμακο")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))

        if rr_d_csv:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_d_csv[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_d.setdefault(" {}".format(_("Φάρμακα στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_rr_d.setdefault(" {}".format(_("Φάρμακα στις αναφορές σεναρίου")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))

        if rr_d_csv3:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_d_csv3[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_d.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_rr_d.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))

        lr_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_histogram".format(k) in elm,
                             map(lambda el: el.get_text(), soup.find_all('a'))))
        if lr_png:
            lin = lin + 1
            dict_lrTest_png[lr_png[0]] = "Figure {}".format(lin)

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
        if lr_csv6:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lr_csv6[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Αποτελέσματα LRT βάσει των συνολικών συμβάντων")),
                               []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Αποτελέσματα LRT βάσει των συνολικών συμβάντων")),
                               []).append("{} {}".format(_("Πίνακας"), lin))
        if lr_csv2:
            df2 = pd.read_csv(r'{}'.format(
                lr_csv2[0]))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για φάρμακο")),
                               []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για φάρμακο")),
                               []).append("{} {}".format(_("Πίνακας"), lin))
        if lr_csv:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lr_csv[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για όλα τα φάρμακα")),
                               []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις συμβάντων για όλα τα φάρμακα")),
                               []).append("{} {}".format(_("Πίνακας"), lin))
        if lr_csv4:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lr_csv4[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Φάρμακα στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Φάρμακα στις αναφορές σεναρίου")),
                               []).append("{} {}".format(_("Πίνακας"), lin))
        if lr_csv5:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lr_csv5[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Πλήθος συμβάντων για φάρμακο")), []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Πλήθος συμβάντων για φάρμακο")),
                               []).append("{} {}".format(_("Πίνακας"), lin))
        if lr_csv1:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lr_csv1[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Πλήθος για όλα τα συμβάντα")), []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Πλήθος για όλα τα συμβάντα")),
                               []).append("{} {}".format(_("Πίνακας"), lin))
        if lr_csv3:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lr_csv3[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lr.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_lr.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")),
                               []).append("{} {}".format(_("Πίνακας"), lin))

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
        rr_e_csv5 = list(filter(
            lambda elm: os.path.splitext(elm)[1] in [".csv"] and "{}_specifieddrug".format(k) in elm,
            map(lambda el: el.get_text(), soup.find_all('a'))))
        if rr_e_csv4:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_e_csv4[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_e.setdefault(' PRR and ROR Results', []).append(styler1.render())
            lin = lin + 1
            dict_rr_e.setdefault(" {}".format(_("Αποτελέσματα PRR και ROR")), []).append("{} {}".format(_("Πίνακας"), lin))
        if rr_e_csv5:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_e_csv5[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_e.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για συγκεκριμένο συμβάν")),
                                 []).append(styler1.render())
            lin = lin + 1
            dict_rr_e.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για συγκεκριμένο συμβάν")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))
        if rr_e_csv2:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_e_csv2[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_e.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για όλα τα συμβάντα")),
                                 []).append(styler1.render())
            lin = lin + 1
            dict_rr_e.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για όλα τα συμβάντα")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))
        if rr_e_csv1:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_e_csv1[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_e.setdefault(" {}".format(_("Ταξινομημένες μετρήσεις φαρμάκων για συμβάν")),
                                 []).append(styler1.render())
            lin = lin + 1
            dict_rr_e.setdefault(" {}".format(_("Ταξινομημένες μετρήσεις φαρμάκων για συμβάν")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))
        if rr_e_csv:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_e_csv[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_e.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_rr_e.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))
        if rr_e_csv3:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, rr_e_csv3[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_rr_e.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_rr_e.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")),
                                 []).append("{} {}".format(_("Πίνακας"), lin))

        lre_png = list(filter(lambda elm: os.path.splitext(elm)[1] in [".png"] and "{}_Ehistogram".format(k) in elm,
                              map(lambda el: el.get_text(), soup.find_all('a'))))
        if lre_png:
            lin = lin + 1
            dict_lreTest_png[lre_png[0]] = "Figure {}".format(lin)

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
        if lre_csv6:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv6[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Αποτελέσματα LRT βάσει των συνολικών φαρμάκων")),
                                []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Αποτελέσματα LRT βάσει των συνολικών φαρμάκων")),
                                []).append("{} {}".format(_("Πίνακας"), lin))
        if lre_csv2:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv2[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για συμβάν")),
                                []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για συμβάν")),
                                []).append("{} {}".format(_("Πίνακας"), lin))
        if lre_csv:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για όλα τα συμβάντα")),
                                []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Αναλυθείσες μετρήσεις φαρμάκων για όλα τα συμβάντα")),
                                []).append("{} {}".format(_("Πίνακας"), lin))
        if lre_csv4:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv4[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")),
                                []).append("{} {}".format(_("Πίνακας"), lin))
        if lre_csv5:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv5[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Πλήθος φαρμάκων για συμβάν")), []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Πλήθος φαρμάκων για συμβάν")),
                                []).append("{} {}".format(_("Πίνακας"), lin))
        if lre_csv1:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv1[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Πλήθος όλων των φαρμάκων")), []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Πλήθος όλων των φαρμάκων")),
                                []).append("{} {}".format(_("Πίνακας"), lin))
        if lre_csv3:
            df2 = pd.read_csv(r'{}'.format(os.path.join(settings.SHINY_SCREENSHOTS_ENDPOINT, lre_csv3[0])))
            styler1 = df2.loc[:9].style.hide_index().hide_columns(['Unnamed: 0'])
            dict_lre.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")), []).append(styler1.render())
            lin = lin + 1
            dict_lre.setdefault(" {}".format(_("Ενδείξεις στις αναφορές σεναρίου")),
                                []).append("{} {}".format(_("Πίνακας"), lin))

    dicts123_vals = list(dict1.values()) + list(dict2.values()) + list(dict3.values())

    # Add twitter screenshots into dicts for final report
    p = "twitter" + sc.title + str(sc.owner)
    h = hashlib.md5(repr(p).encode('utf-8'))
    twitter_hash = h.hexdigest()

    # If twitter shots' checkbox checked in final report, find files else delete them
    if not request.session.get("twitter_shots_checked"):
        # Clear again
        requests.delete("{}delete-media-files".format(
            settings.SHINY_SCREENSHOTS_ENDPOINT.replace("media/", "")),
            auth=HTTPBasicAuth(settings.SHINY_SHOTS_SERVICES_USER, settings.SHINY_SHOTS_SERVICES_PASS),
            params={"hashes": [twitter_hash]})
        twitter_shots = {}
    else:
        ls_resp = requests.get("{}list-media-files".format(settings.SHINY_SCREENSHOTS_ENDPOINT.replace("media/", "")),
                               auth=HTTPBasicAuth(settings.SHINY_SHOTS_SERVICES_USER,
                                                  settings.SHINY_SHOTS_SERVICES_PASS))

        existing_files = ls_resp.json() if ls_resp.status_code == 200 else []

        found_files = list(filter(lambda fname: fname.startswith(twitter_hash), existing_files))

        len_image_print = len(image_print)

        # Most active users in the selected twitter discourse
        twitter_shots = dict([("{} {} - {}".format(
            _("Διάγραμμα"), i+1+len_image_print, _("Χρονοδιάγραμμα σχετικών δημοσιεύσεων στο Twitter"
                                                   ) if "twitter_timeline" in f else _(
                "Δραστήριοι χρήστες στη σχετική θεματολογία στο Twitter")), f) for i, f in enumerate(found_files)])

    # Keep only report notes that have to do with openFDA
    openFDA_notes = {k: v for k, v in report_notes.items() if k not in ["ir", "char", "pathways", twitter_hash]}
    lst_of_all = dicts123_vals + list(openFDA_notes.values())
    empty_dicts123 = False if any(el != "" for el in chain.from_iterable(dicts123_vals)) else True
    empty_OpenFDA = False if any(el != "" for el in chain.from_iterable(lst_of_all)) else True

    context = {"SHINY_SCREENSHOTS_ENDPOINT": settings.SHINY_SCREENSHOTS_ENDPOINT, "all_combs": all_combs,
               "scenario": scenario, "dict_quickview": dict_quickview, "dict_dashboard_png": dict_dashboard_png,
               "dict_dash_csv": dict_dash_csv, "dict_rr_d": dict_rr_d, "dict_lr": dict_lr,
               "dict_lrTest_png": dict_lrTest_png, "dict_rr_e": dict_rr_e,
               "dict_lre": dict_lre, "dict_lreTest_png": dict_lreTest_png, "dict1": dict1,
               "dict2": dict2, "dict3": dict3, "dict_hash_combination": dict_hash_combination,
               "empty_OpenFDA": empty_OpenFDA, "report_notes": report_notes, "no_comb": no_comb,
               "extra_notes": extra_notes, "image_print": image_print, "ir_dict_t": ir_dict_t, "ir_dict_a": ir_dict_a,
               "coh_dict": coh_dict, "cp_dict": cp_dict, "pub_notes": pub_notes, "pub_exist": pub_exist,
               "pub_tobjs": pub_tobjs, "pub_nobjs": pub_nobjs, "empty_dicts123": empty_dicts123,
               "twitter_shots": twitter_shots, "twitter_hash": twitter_hash}

    return render(request, 'app/report_pdf.html', context)


def print_report(request, scenario_id=None):
    """ Generate and open in a browser the final report
    :param request: request
    :param scenario_id: the specific scenario, new scenario or None
    :return: the form view
    """

    scenario_id = scenario_id or json.loads(request.GET.get("scenario_id", None))
    report_notes = request.GET.get("all_notes", None)
    # report_notes = urllib.parse.quote_plus(str(json.loads(report_notes)))
    pub_titles = request.GET.get("allPubTitles", None)
    # pub_titles = urllib.parse.urlencode(json.loads(pub_titles))
    pub_notes = request.GET.get("allPubNotes", None)
    # pub_notes = urllib.parse.urlencode(json.loads(pub_notes))

    extra_notes = json.loads(request.GET.get("extra_notes", ""))

    cookies_dict = request.COOKIES

    options = {
        "cookie": [
            ("csrftoken", cookies_dict.get("csrftoken")),
            ("sessionid", cookies_dict.get("sessionid")),
            ("django_language", cookies_dict.get("django_language", "en")),
        ],
        "page-size": "A4",
        "encoding": "UTF-8",
        "footer-right": "[page]",
        "enable-local-file-access": None,
        # 'disable-smart-shrinking': None,
    }

    fname = "{}.pdf".format(str(uuid.uuid4()))
    file_path = os.path.join(tempfile.gettempdir(), fname)

    url = "{}/ajax/report_pdf".format(settings.PDFKIT_ENDPOINT)

    req_params = {"scenario_id": scenario_id, "all_notes": report_notes or "", "extra_notes": extra_notes or "",
                  "allPubTitles": pub_titles or "", "allPubNotes": pub_notes or ""}

    resp = requests.get(url, params=req_params, cookies=cookies_dict, verify=False)
    pdfkit.from_url(resp.url, file_path, options=options)

    try:
        return FileResponse(open(file_path, "rb"), content_type="application/pdf", as_attachment=True)
    except FileNotFoundError:
        raise Http404()


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def ic_management_workspace(request):
    """ Table of individual cases for scenarios selected on the possibility of adverse drug reactions
    Contains ic_id,creation date,scenario title, drugs, diseases, questionnaire's result,
    case's history and delete options
    :param request: request
    :return: the form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    request.session['quest_id'] = None
    request.session['scen_id'] = None
    request.session['ic_id'] = None  # Individual case

    individual_cases = []

    for case in IndividualCase.objects.filter(user=request.user).order_by('-timestamp').all():
        for scs in case.scenarios.all():
            for quests in case.questionnaires.all():

                individual_cases.append({
                        "id": case.id,
                        "indiv_case_id": case.indiv_case_id,
                        "timestamp": case.timestamp,
                        # "scenario_id": scs.id,
                        "scenario": scs,
                        "questionnaire_id": quests.id
                    })

    if request.method == 'DELETE':
        indiv_case_id = QueryDict(request.body).get("indiv_case_id")
        indiv_case = None
        if indiv_case_id:
            try:
                indiv_case = IndividualCase.objects.get(id=int(indiv_case_id))
            except:
                pass
        return delete_db_rec(indiv_case)

    context = {"individual_cases": individual_cases}

    return render(request, 'app/ic_management_workspace.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def new_ic_cor(request):
    """ Create a new indiv_case and set indiv_case's id, select from existing scenarios or create a new one and
    complete the questionnaire.
    :param request: request
    :return: the form view
    """
    if not request.META.get("HTTP_REFERER"):
        return forbidden_redirect(request)

    quest_id = request.GET.get("quest_id", None)
    indiv_case_id = request.GET.get("indiv_case_id", None)
    sc_id = request.GET.get("sc_id", None)

    tmp_user = User.objects.get(username=request.user)

    quest_btn_disable = True

    if request.method == "POST":
        form = IndividualCaseForm(request.POST, user=request.user, label_suffix="")

        if form.is_valid() and request.POST.get("saveCtrl") == "1":
            case = form.save(commit=False)
            case.user = tmp_user
            case = form.save(commit=False)
            case.save()
            form.save_m2m()

            return redirect("ic_management_workspace")
        else:
            form_errors = form.errors.as_data()
            # If there is an error in at least one of the indiv_case_id and scenarios fields, disable button
            if not list(filter(lambda el: el in form_errors, ["indiv_case_id", "scenarios"])):
                quest_btn_disable = False
            else:
                quest_btn_disable = True

    else:
        form = IndividualCaseForm(user=request.user, label_suffix="")

    return render(request, "app/new_ic_cor.html", {"form": form, "quest_id":quest_id,  # "scenarios": scenarios,
                                                   "questbtn_disable": quest_btn_disable})


def retr_del_session_pmcvars(request):
    """ Retrieve and delete all the necessary for new pmcase, session variables
    :param request: request
    :return: the session variables (i.e. scenario id, indiv_case id, questionnaire id
    """
    ic_id = request.session.get("ic_id")
    sc_id = request.session.get("scen_id")
    quest_id = request.session.get("quest_id")

    data = {"sc_id": sc_id, "ic_id": ic_id, "quest_id": quest_id}

    if ic_id:
        del request.session["ic_id"]
    if sc_id:
        del request.session["scen_id"]
    if quest_id:
        del request.session["quest_id"]

    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def questionnaire(request, indiv_case_id=None, sc_id=None):
    """ Questionnaire based on liverpool algorithm for determining the likelihood of whether an ADR
    is actually due to the drug rather than the result of other factors.
    :param request: request
    :param indiv_case_id: the specific indiv_case's id or None
    :param sc_id: scenario ids that are correlated with this indiv_case or None
    :return: the form view
    """
    if request.method == "POST":

        form = QuestionnaireForm(request.POST, label_suffix="")
        ic_id = request.session.get('ic_id')
        scen_id = request.session.get('scen_id')

        if form.is_valid():
            answers = form.save(commit=False)

            if Questionnaire.objects.filter(q1=answers.q1, q2=answers.q2, q3=answers.q3, q4=answers.q4,
                                            q5=answers.q5, q6=answers.q6, q7=answers.q7, q8=answers.q8, q9=answers.q9,
                                            q10=answers.q10).exists():
                existing_quest = Questionnaire.objects.get(q1=answers.q1, q2=answers.q2, q3=answers.q3, q4=answers.q4,
                                                           q5=answers.q5, q6=answers.q6, q7=answers.q7, q8=answers.q8,
                                                           q9=answers.q9, q10=answers.q10)
                existing_pk = existing_quest.pk

            else:

                answers.save()
                Questionnaire.objects.filter(q1=False, q2=None, q3=None, q4=None, q5=None, q6=None, q7=None,
                                             q8=None, q9=None, q10=None).update(result="Unlikely")
                Questionnaire.objects.filter(q3=False, q4=None, q5=None, q6=None, q7=None,
                                             q8=None, q9=None, q10=None).update(result="Unlikely")
                Questionnaire.objects.filter(q5=False, q6=None, q7=None, q8=None, q9=None,
                                             q10=None).update(result="Possible")
                Questionnaire.objects.filter(q7=False, q8=None, q9=None,
                                             q10=None).update(result="Possible")
                Questionnaire.objects.filter(q10=False).update(result="Possible")
                Questionnaire.objects.filter(q8=True, q9=None, q10=None).update(result="Definite")
                Questionnaire.objects.filter(q9=True, q10=None).update(result="Definite")
                Questionnaire.objects.filter(q10=True).update(result="Probable")

                existing_pk = answers.pk

            request.session['quest_id'] = existing_pk
            request.session['scen_id'] = scen_id
            request.session['ic_id'] = ic_id

            return redirect('answers_detail', pk=existing_pk, scen_id=scen_id, ic_id=ic_id)

    else:
        # indiv_case_id = indiv_case_id #or request.GET.get("indiv_case_id", None)
        # sc_id = sc_id #or request.GET.getlist("sc_id")

        form = QuestionnaireForm(initial={"indiv_case_id": indiv_case_id, "sc_id": sc_id}, label_suffix="")
        request.session['quest_id'] = None
        request.session['scen_id'] = sc_id
        request.session['ic_id'] = indiv_case_id

    return render(request, 'app/questionnaire.html', {'form': form, 'indiv_case_id': indiv_case_id, "sc_id": sc_id})


def answers_detail(request, pk, scen_id, ic_id):
    """ Questionnaire's answers for a specific indiv_case(unique pk)
    :param request: request
    :param pk: unique questionnaire's id
    :param scen_id: scenario's id that is correlated with this indiv_case
    :param ic_id: indiv_case's id for this indiv_case
    :return: the form view
    """

    scen_title = Scenario.objects.get(id=scen_id).title
    quest = model_to_dict(Questionnaire.objects.get(id=pk))

    # The table containing tuples of the questions and answers of Liverpool algorithm
    algo_tbl = [(_("Υποψιάζεστε κάποια ανεπιθύμητη δράση φαρμάκου;"), _("Όχι"), _("Ναι")),
                (_("Το συμβάν εμφανίστηκε μετά τη χορήγηση του φαρμάκου ή την αύξηση της δόσης;"), _("Όχι"), _("Ναι")),
                (_("Τα προϋπάρχοντα συμπτώματα επιδεινώθηκαν από το φάρμακο;"), _("Όχι"), _("Ναι")),
                (_("Βελτιώθηκε το συμβάν (± θεραπεία) όταν διακόπηκε το φάρμακο ή μειώθηκε η δόση;"),
                 _("Όχι"), _("Ναι ή Μη προσδιορίσιμο")),
                (_("Σχετίστηκε το συμβάν με μακροχρόνια αναπηρία ή βλάβη;"), _("Όχι"), _("Ναι")),
                (_("Ποια είναι η πιθανότητα το συμβάν να οφείλεται σε υποκείμενο νόσημα;"),
                 _("Υψηλή ή Αβέβαιο"), _("Χαμηλή")),
                (_("Υπάρχουν αντικειμενικά στοιχεία που να υποστηρίζουν την ύπαρξη αιτιολογικού μηχανισμού της "
                   "ανεπιθύμητης ενέργειας φαρμάκου (ΑΕΦ);"),
                 _("Όχι"), _("Ναι")),
                (_("Υπήρξε εκ νέου εμφάνιση της ΑΕΦ μετά την επαναχορήγηση του φαρμακου (θετική επαναπρόκληση);"),
                 _("Όχι"), _("Ναι")),
                (_("Υπάρχει ιστορικό του ίδιου συμβάντος με αυτό το φάρμακο στον συγκεκριμένο ασθενή;"),
                 _("Όχι"), _("Ναι")),
                (_("Έχει υπάρξει προηγούμενη αναφορά του συγκεκριμένου συμβάντος με αυτό το φάρμακο;"),
                 _("Όχι"), _("Ναι")),
                ]

    return render(request, "app/answers_detail.html", {"quest": quest, "scen_id": scen_id, "ic_id": ic_id,
                                                       "scen_title": scen_title, "algo_tbl": algo_tbl})


def indiv_case_history(request, indiv_case_pk=None):
    """ Keep the history(answers of questionnaires) for every indiv_case that you create for "indiv_case_pk"
    :param request: request
    :param indiv_case_pk: indiv_case's id
    :return: the form view
    """
    individual_cases = []

    for case in IndividualCase.objects.order_by('-timestamp').all():
        if case.indiv_case_id == indiv_case_pk:
            for scs in case.scenarios.all():
                for quests in case.questionnaires.all():

                    individual_cases.append({
                            "id": case.id,
                            "indiv_case_id": case.indiv_case_id,
                            "timestamp": case.timestamp,
                            "scenario_id": scs.id,
                            "scenario_title": scs.title,
                            "drugs": scs.drugs.all(),
                            "conditions": scs.conditions.all(),
                            "questionnaire_id": quests.id
                        })

    context = {"individual_cases": individual_cases, "indiv_case_pk": indiv_case_pk}

    return render(request, 'app/indiv_case_history.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def social_media(request, sc_id):
    """ Social media view for a scenario (and specific user)
    :param request: request
    :param sc_id: the specific scenario's id.
    :return: the social media form view
    """

    if not request.META.get('HTTP_REFERER'):
        return forbidden_redirect(request)

    tmp_user = User.objects.get(username=request.user)

    try:
        sc = Scenario.objects.get(id=sc_id)

        # Retrieve scenario drugs
        drugs = sc.drugs.all()

        # Retrieve scenario conditions
        conditions = sc.conditions.all()

        all_combs = list(product(sorted(set([d.name for d in drugs])) or [""],
                                 sorted(set([c.name for c in conditions])) or [""]))

        all_combs = list(map(lambda el: " ".join(filter(None, el)), all_combs))
        twitter_query = " OR ".join(all_combs)

    except Scenario.DoesNotExist:
        sc = None
        twitter_query = ""

    context = {
        "scenario": sc,
        "sm_shiny_endpoint": settings.SM_SHINY_ENDPOINT,
        "twitter_query": twitter_query,
        "title": _("Περιβάλλον Εργασίας Μέσων Κοινωνικής Δικτύωσης")
    }

    return render(request, 'app/social_media_workspace.html', context)

