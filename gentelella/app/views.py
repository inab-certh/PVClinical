import json
import re
import requests
import os

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

from app.helper_modules import atc_hierarchy_tree
from app.helper_modules import is_doctor
from app.helper_modules import is_nurse
from app.helper_modules import is_pv_expert
from app.helper_modules import delete_db_rec

from app.models import Scenario
from app.models import OHDSIWorkspace
from app.ohdsi_wrappers import update_ir
from app.ohdsi_wrappers import create_ir
from app.retrieve_meddata import KnowledgeGraphWrapper


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
                      _("Σφάλμα τροφοδότησης πληθυσμού ασθενών που παρουσιάζουν τις επιλεγμένες ανεπιθύμητες ενέργειες")]
    drugs_cohort = ohdsi_wrappers.get_entity_by_name("cohortdefinition", drugs_cohort_name)
    conditions_cohort = ohdsi_wrappers.get_entity_by_name("cohortdefinition", conditions_cohort_name)

    # Generate cohorts
    for indx, coh in enumerate([drugs_cohort, conditions_cohort]):
        coh_id = coh.get("id")
        if coh_id:
            status = ohdsi_wrappers.generate_cohort(coh_id)
            if status == "FAILED":
                error_response = HttpResponse(
                    content= coh_gen_errors[indx], status=500)
                return error_response


    ir_name = ohdsi_wrappers.name_entities_group(list(map(lambda c: c.get("name"),
                                                          [drugs_cohort] + [conditions_cohort])))
    ir_ent = ohdsi_wrappers.get_entity_by_name("ir", ir_name)

    if ir_ent:
        ir_id = ir_ent.get("id")
    #     ohdsi_wrappers.update_ir(ir_ent.get("id"))
    else:
        res_st, res_json = ohdsi_wrappers.create_ir([drugs_cohort], [conditions_cohort])
        ir_id = res_json.get("id")

    context = {
        "title": _("Περιβάλλον εργασίας OHDSI"),
        "ir_id": ir_id,
        "sc_id": scenario_id
    }

    return render(request, 'app/ohdsi_workspace.html', context)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_pv_expert(u))
def incidence_rates(request, sc_id, ir_id, read_only=1):
    """ Add or edit incidence rates (ir) view. Retrieve the specific ir that ir_id refers to
    :param request: request
    :param ir_id: the specific ir record's id
    :param sc_id: the specific scenario's id (optional)
    :param read_only: 0 if False 1 if True
    :return: the form view
    """
    http_referer = request.META.get('HTTP_REFERER')

    if not http_referer:
        return forbidden_redirect(request)

    ir_url = "{}/ir/{}".format(settings.OHDSI_ENDPOINT, ir_id)

    ir_exists = ohdsi_wrappers.url_exists(ir_url)
    ir_options = {}
    if ir_exists:
        ir_options = ohdsi_wrappers.get_ir_options(ir_id)
    else:
        messages.error(
            request,
            _("Δεν βρέθηκε ανάλυση ποσοστών επίπτωσης με το συγκεκριμένο αναγνωριστικο!"))

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
                    "title": _("Ανάλυση Ποσοστών Επίπτωσης")
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
                "title": _("Ανάλυση Ποσοστών Επίπτωσης")
            }
            return render(request, 'app/ir.html', context,status=400)


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
        "title": _("Ανάλυση Ποσοστών Επίπτωσης")
    }

    return render(request, 'app/ir.html', context)


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
