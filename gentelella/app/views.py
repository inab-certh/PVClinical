import datetime
import json
import os
import re
import requests

from math import ceil
from itertools import chain
from itertools import product

from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
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
from app.entrezpy import conduit
from app.retrieve_meddata import KnowledgeGraphWrapper
from app.pubmed import PubmedAnalyzer

from Bio import Entrez
from mendeley import Mendeley


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

    return HttpResponse(template.render({"scenario": scenario, "shiny_endpoint": settings.OPENFDA_SHINY_ENDPOINT}, request))


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
    data["results"] = [{"id":elm, "text":elm} for elm in subset]

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


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def index(request):
    # print(request.META.get('HTTP_REFERER'))

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
        irform = IRForm(request.POST, label_suffix='', ir_options=ir_options, read_only=read_only)

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


    # elif request.method == 'DELETE':
    #     return delete_db_rec(ohdsi_workspace)

    # GET request method
    else:
        # if "ohdsi-workspace" in http_referer:
        #     sc_id = http_referer.rsplit('/', 1)[-1]
        irform = IRForm(label_suffix='', ir_options=ir_options, read_only=read_only)
        # irform["sc_id"].initial = sc_id
        # update_ir(ir_id)

    results_url = "{}/#/iranalysis/{}?{}".format(settings.OHDSI_ATLAS, ir_id, view_type)
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

        # if rstatus == 200:
        #     messages.success(
        #         request,
        #         _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))
        #     return HttpResponseRedirect(reverse('edit_char', args=(sc_id, char_id,)))
        # else:
        #     messages.error(
        #         request,
        #         _("Συνέβη κάποιο σφάλμα. Παρακαλώ προσπαθήστε ξανά!"))
        #     status_code = 500

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


        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))
            status_code = 400

    # elif request.method == 'DELETE':
    #     return delete_db_rec(ohdsi_workspace)

    # GET request method
    else:
        char_form = CharForm(label_suffix='', char_options=char_options, read_only=read_only)
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
        "title": _("Έκθεση σε φάρμακα"),
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
    if len(all_combs) > 1 and drugs and conditions:
        string_list = [' AND '.join(item) for item in all_combs]
        final_string = ') OR ('.join(map(str, string_list))
        query = '(' + final_string + ')'
    elif drugs and not conditions:
        query = ' AND '.join(map(str, drugs))
    elif conditions and not drugs:
        query = ' OR '.join(map(str, conditions))
    else:
        query = all_combs[0]

    # print(all_combs)

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
            # print(access_token)
            access_token = mend_cookies[0]

            if page_id == None:
                page_id = 1

                # for j in all_combs:
                #     if j[1]:
                #         query = j[0] +' AND '+ j[1]
                #         results = pubmed_search(query, 0, 10, access_token, begin, last)
                #         if results != {}:
                #             records.update(results[0])
                #             total_results = total_results + results[1]
                #     else:
                #         query = j[0]
                #         results = pubmed_search(query, 0, 10, access_token, begin, last)
                #         if results != {}:
                #             records.update(results[0])
                #             total_results = total_results + results[1]
                results = pubmed_search(query, 0, 10, access_token, begin, last)
                if results != {}:
                    records.update(results[0])
                    total_results = total_results + results[1]
                # print(results[1])
                # print(records)
            else:

                start = 10*page_id - 10

                # for j in all_combs:
                #     if j[1]:
                #         query = j[0] +' AND '+ j[1]
                #         results = pubmed_search(query, start, 10, access_token, begin, last)
                #         records.update(results[0])
                #         total_results = results[1]
                #     else:
                #         query = j[0]
                #         results = pubmed_search(query, start, 10, access_token, begin, last)
                #         records.update(results[0])
                #         total_results = results[1]
                results = pubmed_search(query, start, 10, access_token, begin, last)
                if results != {}:
                    records.update(results[0])
                    total_results = total_results + results[1]

            pages_no = ceil(total_results/10) + 1
            # pages_no = (total_results / 10) + 1
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
    pid = request.GET.get("pmid", None)
    title = request.GET.get("title", None)
    abstract = request.GET.get("abstract", None)
    pubdate = request.GET.get("pubmeddate", None)
    authors = request.GET.get("authors", None)
    url = request.GET.get("url", None)
    user = request.user

    scenario = Scenario.objects.get(id=scenario_id)

    notes, created = Notes.objects.update_or_create(
        content=request.GET.get('notes', None), user=user, scenario=scenario,
        workspace=settings.WORKSPACES.get('PubMed'), wsview=title, note_datetime=datetime.datetime.now())

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


# @login_required()
# @user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
# def allnotes(request):
#     """ Add, edit or view aggregated the notes kept for user's scenarios (version in use)
#     :param request: request
#     :return: the form view
#     """
#
#     if not request.META.get('HTTP_REFERER'):
#         return forbidden_redirect(request)
#
#     tmp_user = User.objects.get(username=request.user)
#
#     lista_scenarios=[]
#     scenarios = {'id': 14}
#     try:
#         for scenario in scenarios:
#             scenarios[scenario] = Scenario.objects.filter(owner_id=tmp_user)
#             lista_scenarios = list(scenarios['id'])
#     except Scenario.DoesNotExist:
#         lista_scenarios = None
#
#     list_pub_scenarios = []
#     pub_scenarios = {'id': 14}
#     try:
#         for sc in pub_scenarios:
#             pub_scenarios[sc] = PubMed.objects.filter(user=tmp_user)
#             list_pub_scenarios = list(pub_scenarios['id'])
#     except PubMed.DoesNotExist:
#         list_pub_scenarios = None
#
#
#     lista_id_scenarios = []
#     lista_title_scenarios = []
#     for i in range(len(lista_scenarios)):
#         lista_id_scenarios.append(lista_scenarios[i].id)
#         lista_title_scenarios.append(lista_scenarios[i].title)
#
#     list_pubscen_title = []
#     list_pubscen_sc = []
#     for i in range(len(list_pub_scenarios)):
#         for j in range(len(lista_scenarios)):
#             if list_pub_scenarios[i].scenario_id_id == lista_scenarios[j].id:
#                 list_pubscen_title.append(lista_scenarios[j].title)
#                 list_pubscen_sc.append(lista_scenarios[j].id)
#
#     dictpub_sc_id_title = {}
#     dictpub_sc_id_title = dict(zip(list_pubscen_sc, list_pubscen_title))
#
#     notesforexample1 = []
#     notesforexample = []
#     pubmedexample = []
#
#     if Notes.objects.filter(user=tmp_user) != "":
#
#         lista_notes = []
#         notes = {'id': 14}
#         for note in notes:
#             notes[note] = Notes.objects.filter(user=tmp_user)
#             lista_notes = list(notes['id'])
#
#         lista_notes_scid = []
#         lista_notes_workspace = []
#         lista_notes_view = []
#
#         for i in range(len(lista_notes)):
#             lista_notes_scid.append(lista_notes[i].scenario_id)
#
#         lista_notes_scid_without = []
#         lista_title_scenarios_without = []
#         lista_notes_content_without = []
#
#         for i in range(len(lista_id_scenarios)):
#             for j in range(len(lista_notes_scid)):
#                 if lista_id_scenarios[i] == lista_notes_scid[j]:
#                     lista_notes_view.append(lista_notes[j].wsview)
#                     lista_notes_content_without.append(lista_notes[j].content)
#                     lista_notes_scid_without.append(lista_notes[j].scenario_id)
#                     lista_title_scenarios_without.append(lista_scenarios[i].title)
#                     lista_notes_workspace.append(lista_notes[j].workspace)
#
#         dict_sc_id_title = dict(zip(lista_notes_scid_without, lista_title_scenarios_without))
#
#         notesforexample = []
#         work = ""
#         wsview_title = ""
#         scenario_title = ""
#
#         for n in Notes.objects.filter(user=tmp_user).order_by('-note_datetime'):
#             if n.scenario_id != None:
#                 work = {v: k for k, v in settings.WORKSPACES.items()}.get(n.workspace)
#                 # if n.workspace == 1:
#                 #     work = 'OHDSI'
#                 # if n.workspace == 2:
#                 #     work = 'OpenFDA'
#                 # if n.workspace == 3:
#                 #     work = 'PubMed'
#                 if n.wsview == 'ir':
#                     wsview_title = 'Incidence Rate'
#                 elif n.wsview == 'char':
#                     wsview_title = 'Cohort Caracterization'
#                 elif n.wsview == 'pathways':
#                     wsview_title = 'Cohort Pathways'
#                     # edw prepei na mpoun kai ta onomata twn wsview tou OpenFDA analoga me to pws apofasisoume na ta emfanizoume
#                 else:
#                     wsview_title = n.wsview
#
#
#                 for key in dict_sc_id_title:
#                     if n.scenario_id == key:
#
#                         scenario_title = dict_sc_id_title[key]
#
#                 notesforexample.append({
#                     "workspace": work,
#                     "content": n.content,
#                     "wsview": n.wsview,
#                     "wsview_title": wsview_title,
#                     "scenario": n.scenario_id,
#                     "scenario_title": scenario_title,
#                     "note_datetime": n.note_datetime,
#                 })
#                 pubmedexample = []
#                 if PubMed.objects.filter(user=tmp_user) != "":
#                     for p in PubMed.objects.filter(user=tmp_user).order_by('-pubdate'):
#                         for key in dictpub_sc_id_title:
#                              if p.scenario_id_id == key:
#                                 scenario_title = dictpub_sc_id_title[key]
#                         pubmedexample.append({
#                             "workspace": 'PubMed',
#                             "notes": p.notes,
#                             "wsview": p.title,
#                             "title": p.title,
#                             "scenario_id": p.scenario_id_id,
#                             "scenario_title": scenario_title,
#                             "pubmeddate": p.pubdate,
#                             "abstract": p.abstract,
#                             "pmid": p.pid,
#                             "authors": p.authors,
#                             "created": p.created
#                         })
#
#                 notesforexample1 = []
#                 for n in Notes.objects.order_by('-note_datetime').all():
#                     if n.scenario_id == None:
#                         if n.workspace == 1:
#                             work = 'OHDSI'
#                         if n.workspace == 2:
#                             work = 'OpenFDA'
#                         if n.workspace == 3:
#                             work = 'PubMed'
#                         if n.wsview == 'de':
#                             wsview_title = 'Drug Exposure'
#                         elif n.wsview == 'co':
#                             wsview_title = 'Condition Occurence'
#
#                         notesforexample1.append({
#                             "scenario": None,
#                             "note_datetime": n.note_datetime,
#                             "workspace": work,
#                             "content": n.content,
#                             "wsview": n.wsview,
#                             "wsview_title": wsview_title
#
#                         })
#
#         # context = {'notesforexample1': notesforexample1, 'notesforexample': notesforexample , 'pubmedexample': pubmedexample}
#         # return render(request, 'app/all_notes_OLD.html', context)
#
#     context = {'notesforexample1': notesforexample1, 'notesforexample': notesforexample, 'pubmedexample':pubmedexample}
#     return render(request, 'app/all_notes_OLD.html', context)

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
        "scenario": unote.scenario, "note_datetime": unote.note_datetime,
        "workspace": rev_workspaces.get(unote.workspace),
        "wsview": unote.wsview, "content": unote.content
    } for unote in Notes.objects.filter(user=tmp_user).order_by('-note_datetime')]



    # for n in user_notes:


    #             notesforexample.append({
    #                 "workspace": work,
    #                 "content": n.content,
    #                 "wsview": n.wsview,
    #                 "wsview_title": wsview_title,
    #                 "scenario": n.scenario_id,
    #                 "scenario_title": scenario_title,
    #                 "note_datetime": n.note_datetime,
    #             })
    #             pubmedexample = []
    #             if PubMed.objects.filter(user=tmp_user) != "":
    #                 for p in PubMed.objects.filter(user=tmp_user).order_by('-pubdate'):
    #                     for key in dictpub_sc_id_title:
    #                          if p.scenario_id_id == key:
    #                             scenario_title = dictpub_sc_id_title[key]
    #                     pubmedexample.append({
    #                         "workspace": 'PubMed',
    #                         "notes": p.notes,
    #                         "wsview": p.title,
    #                         "title": p.title,
    #                         "scenario_id": p.scenario_id_id,
    #                         "scenario_title": scenario_title,
    #                         "pubmeddate": p.pubdate,
    #                         "abstract": p.abstract,
    #                         "pmid": p.pid,
    #                         "authors": p.authors,
    #                         "created": p.created
    #                     })
    #
    #             notesforexample1 = []
    #             for n in Notes.objects.order_by('-note_datetime').all():
    #                 if n.scenario_id == None:
    #                     if n.workspace == 1:
    #                         work = 'OHDSI'
    #                     if n.workspace == 2:
    #                         work = 'OpenFDA'
    #                     if n.workspace == 3:
    #                         work = 'PubMed'
    #                     if n.wsview == 'de':
    #                         wsview_title = 'Drug Exposure'
    #                     elif n.wsview == 'co':
    #                         wsview_title = 'Condition Occurence'
    #
    #                     notesforexample1.append({
    #                         "scenario": None,
    #                         "note_datetime": n.note_datetime,
    #                         "workspace": work,
    #                         "content": n.content,
    #                         "wsview": n.wsview,
    #                         "wsview_title": wsview_title
    #
    #                     })
    #
    #     # context = {'notesforexample1': notesforexample1, 'notesforexample': notesforexample , 'pubmedexample': pubmedexample}
    #     # return render(request, 'app/all_notes_OLD.html', context)
    #
    # context = {'notesforexample1': notesforexample1, 'notesforexample': notesforexample, 'pubmedexample':pubmedexample}

    context = {"user_notes": user_notes, "abbrv_views": settings.ABBRV_VIEWS}
    return render(request, 'app/all_notes.html', context)


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
