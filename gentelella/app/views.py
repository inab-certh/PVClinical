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
from django.shortcuts import HttpResponseRedirect
from django.http import JsonResponse

from django.shortcuts import redirect
from django.utils.translation import gettext_lazy as _

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

def shinny_apps(request):
    template = loader.get_template('app/ShinnyTools.html')
    return HttpResponse(template.render({}, request))

def get_synonyms(request):
    """ Get all the synonyms for a list of drugs
    :param request: The request from which the list of drugs to search for synonyms will be retrieved
    :return: The list of synonyms for the drugs' list
    """

    drugs = json.loads(request.GET.get("drugs", None))

    # Replace with real service
    all_synonyms = {"Omeprazole":["Esomeprazole"], "Esomeprazole": ["Omeprazole"],
                    "Etybenzatropine": ["Benzatropine"], "Benzatropine": ["Etybenzatropine"]}
    synonyms = list(chain.from_iterable([all_synonyms[d] for d in drugs if d in all_synonyms.keys()])) if drugs else []
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
        drugs = [d for d in sc.drugs.all()]
        conditions = [c for c in sc.conditions.all()]
        scenarios.append({"drugs": drugs,
                          "conditions": conditions,
                          "owner": sc.owner.username,
                          "status": sc.status.status,
                          "timestamp": sc.timestamp
                          }
                         )

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
    # if not request.META.get('HTTP_REFERER'):
    #     return forbidden_redirect(request)

    if scenario_id:
        scenario = get_object_or_404(Scenario, pk=scenario_id)
    else:
        scenario = Scenario()


    delete_switch = "enabled" if scenario.id else "disabled"


    if request.method == 'POST':
        scform = ScenarioForm(request.POST,
                              instance=scenario, label_suffix='')

        if scform.is_valid():
            print("valid")
            scform.save()
            messages.success(
                request,
                _("Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!"))

            return HttpResponseRedirect(request.path_info)

        else:
            messages.error(
                request,
                _("Η ενημέρωση του συστήματος απέτυχε λόγω λαθών στη φόρμα εισαγωγής. Παρακαλώ προσπαθήστε ξανά!"))

    # elif request.method == 'DELETE':
    #     return delete_db_rec(scenario)

    else:
        scform = ScenarioForm(label_suffix='', instance=scenario)

    all_drug_codes = list(map(lambda d: d.code, scform.all_drugs))

    context = {
        "title": _("Σενάριο"),
        "atc_tree": json.dumps(atc_hierarchy_tree(all_drug_codes)),
        "delete_switch": delete_switch,
        "form": scform,
    }

    # if not request.META.get('HTTP_REFERER'):
    #     return forbidden_redirect(request)
    #
    # scenario = get_object_or_404(Scenario, pk=scenario_id)
    #
    #
    # # If patient is not an adult, there should be a caregiver
    # if not scenario.:
    #     # Get patient's (specific) caregiver
    #     # If no caregiver appointed for non-adult patient
    #     # or caregiver does not exist,  create one
    #     caregiver = patient.caregiver or Caregiver()
    #
    # delete_switch = 'enabled' if all([
    #     patient.adult, patient.residence, patient.profession, patient.education
    # ]) or all([patient.caregiver, patient.residence]) else 'disabled'
    #
    # forms = []
    # if request.method == 'POST':
    #
    #     if caregiver:  # Patient not an adult
    #         cgform = CaregiverForm(request.POST, instance=caregiver,
    #                                label_suffix='')
    #         forms.append(cgform)
    #
    #     pform = DemographicsForm(request.POST, instance=patient,
    #                              label_suffix='')
    #     forms.append(pform)
    #
    #     tmp_objs = []
    #
    #     validity = all(map(lambda f: f.is_valid(), forms))
    #
    #     if validity:  # All forms were valid
    #         for form in forms:
    #             tmp_objs.append(form.save(commit=False))
    #         tmp_objs.reverse()  # Put patient object first in any case
    #
    #         # Update patient's field values and save all changes to database
    #         patient.residence = tmp_objs[0].residence
    #         patient.profession = tmp_objs[0].profession
    #         patient.education = tmp_objs[0].education
    #         patient.comment = tmp_objs[0].comment
    #
    #         if len(tmp_objs) == 2:
    #             # Save profession, in case a new one was added
    #             # (this code should probably be inactive now)
    #             patient.caregiver, _ = Caregiver.objects.get_or_create(
    #                 profession=tmp_objs[1].profession,
    #                 education=tmp_objs[1].education,
    #                 relation_to_patient=tmp_objs[1].relation_to_patient)
    #
    #         patient.save()
    #
    #         messages.success(
    #             request,
    #             "Η ενημέρωση του συστήματος πραγματοποιήθηκε επιτυχώς!")
    #
    #         return HttpResponseRedirect(request.path_info)
    #
    #     else:
    #         messages.error(
    #             request,
    #             "Η ενημέρωση του συστήματος απέτυχε \
    #             λόγω λαθών στη φόρμα εισαγωγής.\
    #             Παρακαλώ προσπαθήστε ξανά!")
    #
    # elif request.method == 'DELETE':
    #     # Special 'delete', since you cannot delete whole patient
    #     # So update proper fields to null and if patient is a child
    #     # delete caregiver
    #
    #     try:
    #         if patient.caregiver:
    #             tmp_caregiver = patient.caregiver
    #             patient.caregiver = None
    #             delete_db_rec(tmp_caregiver)
    #
    #         patient.residence = None
    #         patient.profession = None
    #         patient.education = None
    #         patient.comment = None
    #         patient.save(update_fields=['residence', 'profession',
    #                                     'caregiver', 'education',
    #                                     'comment'])
    #
    #         resp_status = 200
    #         resp_message = "Η διαγραφή ολοκληρώθηκε επιτυχώς!"
    #         resp = HttpResponse(
    #             content=resp_message,
    #             status=resp_status)
    #
    #     except Exception:
    #         resp_status = 500
    #         resp_message = "Δυστυχώς η διαγραφή αυτή, δεν ήταν δυνατόν " \
    #                        "να ολοκληρωθεί!"
    #         resp = HttpResponse(
    #             content=resp_message,
    #             status=resp_status)
    #
    #     return resp
    #
    # # In case of GET method
    # else:
    #     if caregiver:
    #         cgform = CaregiverForm(instance=caregiver, label_suffix='')
    #         forms.append(cgform)
    #
    #     pform = DemographicsForm(instance=patient, label_suffix='')
    #     forms.append(pform)
    #
    # forms.reverse()  # So that they appear in the order we want in template
    # context = {
    #     'title': "Καταγραφή Ασθενών με χρόνια αναπνευστικά νοσήματα",
    #     'subtitle': "και χρήση αναπνευστικών συσκευών στο σπίτι",
    #     'patient_id': patient_id,
    #     'delete_switch': delete_switch,
    #     'forms': forms,
    # }


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
