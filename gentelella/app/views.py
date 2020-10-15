import json
import re
import requests
import os
import requests

from math import ceil

from itertools import chain
from itertools import product

from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.contrib.auth.decorators import user_passes_test
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

from app.helper_modules import atc_hierarchy_tree
from app.helper_modules import is_doctor
from app.helper_modules import is_nurse
from app.helper_modules import is_pv_expert
from app.helper_modules import delete_db_rec
from app.helper_modules import getPMCID
from app.helper_modules import mendeley_cookies
from app.helper_modules import mendeley_pdf


from app.models import PubMed
from app.models import Scenario
from app.models import OHDSIWorkspace
from app.ohdsi_wrappers import update_ir
from app.ohdsi_wrappers import create_ir
from app.retrieve_meddata import KnowledgeGraphWrapper


from app.pubmed import PubmedAnalyzer

from mendeley import Mendeley
from app.mendeley_expand import AutoRefreshMendeleySession
from oauthlib.oauth2 import TokenExpiredError
import requests
from urllib.parse import urlparse

from django.shortcuts import render, redirect

from Bio import Entrez

import entrezpy.conduit
import entrezpy.base.result
import entrezpy.base.analyzer
import time
import sys

from importlib import reload

from django.core.paginator import Paginator




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
                "timestamp": sc.timestamp
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
        ds_name = ohdsi_wrappers.name_entities_group(drugs_names)

        # Check if concept set already exists
        # ds_id = ohdsi_wrappers.get_concept_set_id(ds_name)
        # Create concept set if it does not already exist
        if ohdsi_wrappers.exists(ds_name, "conceptset") != (200, True):
            st_code, resp_json = ohdsi_wrappers.create_concept_set(drugs_names, "Drug")
            if not (st_code == 200 and resp_json):
                # context = {
                #     "reason": _("Σφάλμα δημιουργίας concept set φαρμάκων")
                # }
                # error_response = render(request, "page_500.html", context)
                # error_response.status_code = 500

                error_response = HttpResponse(
                    content=_("Σφάλμα δημιουργίας concept set φαρμάκων"),
                    status=500)

                return error_response

        drugs_cohort_name = ohdsi_wrappers.name_entities_group([ds_name])

        if ohdsi_wrappers.exists(drugs_cohort_name, "cohortdefinition") != (200, True):
            st_code, resp_json = ohdsi_wrappers.create_cohort({"Drug": [ds_name]})
            if not (st_code == 200 and resp_json):
                # context = {
                #     "reason": _("Σφάλμα δημιουργίας πληθυσμού ασθενών που λαμβάνουν τα συγκεκριμένα φάρμακα")
                # }
                # error_response = render(request, "page_500.html", context)
                # error_response.status_code = 500

                error_response = HttpResponse(
                    content=_("Σφάλμα δημιουργίας πληθυσμού ασθενών που λαμβάνουν τα συγκεκριμένα φάρμακα"),
                    status=500)

                return error_response

    # Get conditions concept set id
    sc_conditions = sc.conditions.all()
    if sc_conditions:
        conditions_names = [c.name for c in sc_conditions]
        cs_name = ohdsi_wrappers.name_entities_group(conditions_names)

        # Check if concept set already exists
        # cs_id = ohdsi_wrappers.get_concept_set_id(cs_name)
        # Create concept set if it does not already exist
        if ohdsi_wrappers.exists(cs_name, "conceptset") != (200, True):
            st_code, resp_json = ohdsi_wrappers.create_concept_set(conditions_names, "Condition")
            if not (st_code == 200 and resp_json):
                # context = {
                #     "reason": _("Σφάλμα δημιουργίας concept set ανεπιθύμητων ενεργειών")
                # }
                # error_response = render(request, "page_500.html", context)
                # error_response.status_code = 500
                error_response = HttpResponse(
                    content=_("Σφάλμα δημιουργίας concept set ανεπιθύμητων ενεργειών"),
                    status=500)

                return error_response


        conditions_cohort_name = ohdsi_wrappers.name_entities_group([cs_name])

        if ohdsi_wrappers.exists(conditions_cohort_name, "cohortdefinition") != (200, True):
            st_code, resp_json = ohdsi_wrappers.create_cohort({"Condition": [cs_name]})
            if not (st_code == 200 and resp_json):
                # context = {
                #     "reason":
                #         _("Σφάλμα δημιουργίας πληθυσμού ασθενών που παρουσιάζουν τις επιλεγμένες ανεπιθύμητες ενέργειες"
                #           )
                # }
                # error_response = render(request, "page_500.html", context)
                # error_response.status_code = 500

                error_response = HttpResponse(
                    content=_("Σφάλμα δημιουργίας πληθυσμού ασθενών που παρουσιάζουν τις επιλεγμένες ανεπιθύμητες ενέργειες"),
                    status=500)

                return error_response

    coh_gen_errors = [_("Σφάλμα τροφοδότησης πληθυσμού ασθενών που λαμβάνουν τα συγκεκριμένα φάρμακα"),
                      _("Σφάλμα τροφοδότησης πληθυσμού ασθενών που παρουσιάζουν τις επιλεγμένες ανεπιθύμητες ενέργειες")
                      ]
    drugs_cohort = ohdsi_wrappers.get_entity_by_name("cohortdefinition", drugs_cohort_name) or {}
    conditions_cohort = ohdsi_wrappers.get_entity_by_name("cohortdefinition", conditions_cohort_name) or {}

    # Generate cohorts
    for indx, coh in enumerate(list(filter(None, [drugs_cohort, conditions_cohort]))):
        recent_gen_exists = ohdsi_wrappers.cohort_generated_recently(coh, recent=True, days_before=10)
        coh_id = coh.get("id")
        if coh_id and not recent_gen_exists:
            status = ohdsi_wrappers.generate_cohort(coh_id)
            if status == "FAILED":
                error_response = HttpResponse(
                    content= coh_gen_errors[indx], status=500)
                return error_response

    ir_id = None
    char_id = None

    if drugs_cohort and conditions_cohort:
        ir_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name"),
                                                              [drugs_cohort] + [conditions_cohort])))
        ir_ent = ohdsi_wrappers.get_entity_by_name("ir", ir_name)

        if ir_ent:
            ir_id = ir_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_ir([drugs_cohort], [conditions_cohort])
            ir_id = res_json.get("id")

    if drugs_cohort or conditions_cohort:
        char_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name", ""),
                                                                filter(None,[drugs_cohort, conditions_cohort]))))
        char_ent = ohdsi_wrappers.get_entity_by_name("cohort-characterization", char_name)

        if char_ent:
            char_id = char_ent.get("id")
        #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
        else:
            res_st, res_json = ohdsi_wrappers.create_char(list(filter(None, [drugs_cohort, conditions_cohort])))
            char_id = res_json.get("id")
    context = {
        "title": _("Περιβάλλον εργασίας OHDSI"),
        "ir_id": ir_id,
        "char_id": char_id,
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

    context = {
        # "delete_switch": delete_switch,
        "sc_id": sc_id,
        "ir_id": ir_id,
        "results_url": results_url,
        "read_only": read_only,
        "form": irform,
        "title": _("Ανάλυση Ρυθμού Επίπτωσης")
    }

    return render(request, 'app/ir.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def characterizations(request, sc_id, char_id, read_only=1):
    """ Add or edit characterizations view. Retrieve the specific characterization analysis
     that ir_id refers to
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
        print("POST")

        if char_form.is_valid():
            print("POST2")
            print("Cleaned data: ", char_form.cleaned_data.get("features"))
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
def pubMed_view(request, scenario_id=None, page_id=None):
    """ Load papers that are relevant to scenario that user creates and check user's Mendeley library for papers that
    get from the results.
    :param request: request
    :param scenario_id: the specific scenario, None for new scenario
    :param page_id: the specific result page that user searching for, None for first page
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

    mend_cookies = mendeley_cookies()


    if mend_cookies != []:

        try:

            access_token = mend_cookies[0].value
            # print(access_token)

            if page_id == None:
                page_id = 1

                for j in all_combs:
                    if j[1]:
                        query = j[0] +' AND '+ j[1]

                        results = pubmed_search(query, 0, 10, access_token)
                        if results != {}:
                            records.update(results[0])
                            total_results = total_results + results[1]
                    else:
                        query = j[0]
                        results = pubmed_search(query, 0, 10, access_token)
                        if results != {}:
                            records.update(results[0])
                            total_results = total_results + results[1]
            else:

                start = 10*page_id - 10

                for j in all_combs:
                    if j[1]:
                        query = j[0] +' AND '+ j[1]
                        results = pubmed_search(query, start, 10, access_token)
                        records.update(results[0])
                        total_results = results[1]
                    else:
                        query = j[0]
                        results = pubmed_search(query, start, 10, access_token)
                        records.update(results[0])
                        total_results = results[1]

            pages_no = ceil(total_results/10)
            pages = list(range(1, pages_no))

            if records == {}:
                return render(request, 'app/LiteratureWorkspace.html', {"scenario": scenario})

            return render(request, 'app/LiteratureWorkspace.html', {"scenario": scenario, 'records': records, 'pages': pages, 'page_id': page_id})

        except Exception as e:
            print(e)
            # previous_url = request.META.get('HTTP_REFERER')

            url = "http://127.0.0.1:8000/"


            return redirect(url)


    else:

        client_id = 8886
        redirect_uri = "http://127.0.0.1:8000/"
        client_secret = "75nLSO6SJtSD8um3"
        mendeley = Mendeley(client_id, redirect_uri=redirect_uri)

        auth = mendeley.start_implicit_grant_flow()

        login_url = auth.get_login_url()

        url = "http://127.0.0.1:8000/"

        return redirect(url)


def is_logged_in(request):
    """ Checks if the user is logged in Mendeley platform.
    :param request: request
    :return: Json response
    """
    data = {
        'logged_in': (mendeley_cookies() != [])
    }

    return JsonResponse(data)

def pubmed_search(query, begin, max, access_token):
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

    print(begin)
    w = entrezpy.conduit.Conduit(email='pvclinical.project@gmail.com', apikey='40987f0b48b279c32047b1386f249d8cb308')
    fetch_pubmed = w.new_pipeline()
    q = query

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


            Entrez.email = 'sdimitsaki@gmail.com'
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

    print(r.status_code)
    return r.status_code





@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def save_pubmed_input(request):
    """ Save the notes and the relevance of a paper that user chose.
    :param request: request
    :return: Json response
    """

    relevance = request.GET.get('relevance', None)
    notes = request.GET.get('notes', None)
    pid = request.GET.get("pmid", None)
    title = request.GET.get("title", None)
    abstract = request.GET.get("abstract", None)
    pubdate = request.GET.get("pubmeddate", None)
    authors = request.GET.get("authors", None)
    url = request.GET.get("url", None)
    user = request.user


    pm = PubMed(user=user, pid=pid, title=title, abstract=abstract, pubdate=pubdate, authors=authors,
                url=url, relevance=relevance, notes=notes)
    pm.save()

    data = {
        'message': 'Ok'

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