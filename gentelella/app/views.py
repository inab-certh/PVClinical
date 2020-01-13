import json

from itertools import chain

from django.contrib.auth.decorators import login_required
from django.contrib.auth.decorators import user_passes_test

from django.contrib import messages
from django.shortcuts import get_object_or_404
from django.shortcuts import render
from django.shortcuts import redirect
from django.template import loader
from django.http import HttpResponse
from django.http import HttpResponseForbidden
from django.http import QueryDict
from django.shortcuts import HttpResponseRedirect
from django.http import JsonResponse

from django.shortcuts import redirect
from django.utils.translation import gettext_lazy as _
from django.urls import reverse

from app.errors_redirects import forbidden_redirect

from app.helper_modules import atc_hierarchy_tree
from app.helper_modules import is_doctor
from app.helper_modules import is_nurse
from app.helper_modules import is_pv_expert
from app.helper_modules import delete_db_rec

from app.models import Drug
from app.models import Condition
from app.models import Scenario
from app.models import Status

from app.forms import ScenarioForm


def OpenFDAWorkspace_detailedView(request, scenario_id=None):
    template = loader.get_template('app/OpenFDAWorkspace_detailedView.html')
    scenario = {}
    sc = Scenario.objects.get(id=scenario_id)
    drugs = [d for d in sc.drugs.all()]
    conditions = [c for c in sc.conditions.all()]
    scenario = {"drugs": drugs,
                "conditions": conditions,
                "owner": sc.owner.username,
                "status": sc.status.status,
                "timestamp": sc.timestamp
                }

    return HttpResponse(template.render({"scenario": scenario}, request))

def get_synonyms(request):
    """ Get all the synonyms for a list of drugs
    :param request: The request from which the list of drugs to search for synonyms will be retrieved
    :return: The list of synonyms for the drugs' list
    """

    drugs = json.loads(request.GET.get("drugs", None))

    # Replace with real service
    all_synonyms = {"omeprazole":["esomeprazole"], "esomeprazole": ["omeprazole"],
                    "etybenzatropine": ["benzatropine"], "benzatropine": ["etybenzatropine"]}
    synonyms = list(chain.from_iterable([all_synonyms[d.lower()] for d in drugs
                                         if d.lower() in all_synonyms.keys()])) if drugs else []
    data={}
    data["synonyms"] = synonyms
    return JsonResponse(data)


@login_required()
@user_passes_test(lambda u: is_doctor(u) or is_nurse(u) or is_pv_expert(u))
def index(request):
    # sc = Scenario.objects.create(title="Test title 1", owner=request.user, status=Status.objects.get(status="CREATING"))
    # tdrugs = [Drug.objects.create(name="Omeprazole"),
    #           Drug.objects.create(code="A24AB12"),
    #           Drug.objects.create(name="Omeprazol"),
    #           Drug.objects.create(code="A24AB11"),
    #           Drug.objects.create(code="N02BE01"),
    #           Drug.objects.create(name="Etybenzatropine", code="N04AC30"),
    #           Drug.objects.create(name="Benzatropine", code="N04AC01")]
    #
    # d1 = Drug.objects.get(code="N04AC30")
    # d2 = Drug.objects.get(code="N04AC01")
    #
    # d1.synonyms.add(d2)
    # d2.synonyms.add(d1)
    #
    # sc.drugs.add(*tdrugs)
    #
    # tconditions = [Condition.objects.create(code="12345678"),
    #                Condition.objects.create(name="gastrointestinal tract")]
    # sc.conditions.add(*tconditions)
    # sc.save()

    # "drug": ["Omeprazole", "A24AB12", "Omeprazol", "A24AB11"],
    # "condition": ["12345678", "gastrointestinal tract"],
    # "owner": request.user.username
    # }


    scenarios = []
    for sc in Scenario.objects.all():
        # drugs = [d for d in sc.drugs.all()]
        # conditions = [c for c in sc.conditions.all()]
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
