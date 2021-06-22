import re

from datetime import date

from django import forms
from django_select2.forms import Select2TagWidget
from django.utils.translation import gettext_lazy as _

from ckeditor.widgets import CKEditorWidget
# from tinymce.widgets import TinyMCE

from app import ohdsi_wrappers
from app.models import Drug
from app.models import Condition
from app.models import Notes
from app.models import Scenario
from app.models import PatientCase
from app.models import Questionnaire
from app.models import Status
from app.retrieve_meddata import KnowledgeGraphWrapper


class CustomSelect2TagWidget(Select2TagWidget):
    """ Class allowing data-tokens with spaces"""

    def build_attrs(self, *args, **kwargs):
        self.attrs.setdefault('data-token-separators', [","])
        # self.attrs.setdefault('data-width', '50%')
        self.attrs.setdefault('data-tags', 'true')
        self.attrs.setdefault('data-url', '')
        self.attrs.setdefault('data-minimum-input-length', 2)
        return super().build_attrs(*args, **kwargs)


class CustomModelForm(forms.ModelForm):

    def __init__(self, *args, **kwargs):
        super(CustomModelForm, self).__init__(*args, **kwargs)

        for field in self.fields:
            help_text = self.fields[field].help_text
            self.fields[field].help_text = None
            if help_text != '':
                self.fields[field].widget.attrs.update({
                    'class': 'has-popover',
                    'data-content': help_text,
                    'data-placement': 'right',
                    'data-container': 'body'})


class ScenarioForm(forms.Form):
    knw = KnowledgeGraphWrapper()
    all_drugs = knw.get_drugs()
    all_conditions = knw.get_conditions()

    title = forms.CharField(label=_("Τίτλος σεναρίου:"), required=True)

    drugs_fld = forms.MultipleChoiceField(choices=[],
                                          required=False,
                                          label=_("Φάρμακο/Φάρμακα:"),
                                          widget=CustomSelect2TagWidget)

    conditions_fld = forms.MultipleChoiceField(choices=[],
                                               required=False,
                                               label=_("Πάθηση/Παθήσεις:"),
                                               widget=CustomSelect2TagWidget)

    status = forms.ChoiceField(choices=Status.status_choices, required=False,
                               label=_("Κατάσταση σεναρίου:"), widget=forms.HiddenInput())

    def __init__(self, *args, **kwargs):
        self.instance = kwargs.pop("instance")
        super(ScenarioForm, self).__init__(*args, **kwargs)

        # If instance exists in database
        if Scenario.objects.filter(title=self.instance.title, owner=self.instance.owner).exists():
            self.fields["title"].initial = self.instance.title
            self.fields["status"].initial = self.instance.status
            init_drugs = ["{}{}".format(
                d.name, " - {}".format(d.code) if d.code else "") for d in self.instance.drugs.all()]
            self.fields["drugs_fld"].choices = list(zip(*[init_drugs] * 2))
            self.fields["drugs_fld"].initial = init_drugs

            init_conditions = ["{}{}".format(
                c.name, " - {}".format(c.code) if c.code else "") for c in self.instance.conditions.all()]
            self.fields["conditions_fld"].choices = list(zip(*[init_conditions] * 2))
            self.fields["conditions_fld"].initial = init_conditions

    def is_valid(self):
        """ Overriding-extending is_valid module
        """

        super(ScenarioForm, self).is_valid()

        if (not self.cleaned_data.get("drugs_fld")) and not self.cleaned_data.get("conditions_fld"):
            self.add_error(None, _("Τουλάχιστον ένα από τα πεδία που αφορούν τα φάρμακα και τις παθήσεις\
                                   του σεναρίου, πρέπει να συμπληρωθεί"))

        return not self._errors

    def clean(self):
        super(ScenarioForm, self).clean()

        ################################## Delete when status decided #######
        self.cleaned_data["status"] = "CREATING"
        if 'status' in self._errors:
            del self._errors['status']
        #############################################################

        selected_drugs = dict(self.data).get("drugs_fld")
        drugs_names = list(map(lambda el: el.name, self.all_drugs))
        drugs_codes = list(map(lambda el: el.code, self.all_drugs))

        if selected_drugs:
            # Split each one of selected drugs, find ATC part with Regexp and check if it is in valid ATC codes
            valid_drugs = list(filter(lambda sd: list(filter(
                lambda d: re.findall("[A-Z]\d{2}[A-Z]{2}\d{2}", d),
                sd.split(" - "))).pop() in drugs_codes, selected_drugs))

            if 'drugs_fld' in self._errors:
                del self._errors['drugs_fld']

            self.cleaned_data["drugs_fld"] = valid_drugs

        selected_conditions = dict(self.data).get("conditions_fld")
        conditions_names = list(map(lambda el: el.name, self.all_conditions))
        conditions_codes = list(map(lambda el: el.code, self.all_conditions))

        if selected_conditions:
            # If not found index is -1, max is used to assure that in case one of the two splitted parts
            # was found, then this part was chosen to find suspected drug
            conditions_indexes = [(max(list(map(lambda el: conditions_names.index(el) if el in conditions_names \
                else conditions_codes.index(el) if el in conditions_codes else -1, sd.split(" - ")
                                                )))) for sd in selected_conditions]

            valid_conditions = list(filter(lambda c: c is not None,
                                           (map(lambda indx: self.all_conditions[indx] \
                                               if (indx > -1 and indx < len(self.all_conditions)) else None,
                                                conditions_indexes))))

            valid_conditions = list(map(lambda c: "{} - {}".format(c.name, c.code), valid_conditions))

            if 'conditions_fld' in self._errors:
                del self._errors['conditions_fld']

            self.cleaned_data["conditions_fld"] = valid_conditions
        return self.cleaned_data

    def save(self, commit=True):
        """ Overriding-extending save module
        """
        self.instance.save(checks=False)
        drugs = []
        conditions = []

        for drug in self.cleaned_data.get("drugs_fld"):
            dname, dcode = list(map(lambda part: part.strip(), drug.split(" - ")))
            drugs.append(Drug.objects.get_or_create(name=dname, code=dcode)[0])
        self.instance.drugs.set(drugs)

        for condition in self.cleaned_data.get("conditions_fld"):
            cname, ccode = list(map(lambda part: part.strip(), condition.split(" - ")))
            conditions.append(Condition.objects.get_or_create(name=cname, code=ccode)[0])
        self.instance.conditions.set(conditions)

        self.instance.status = Status.objects.get(status=self.cleaned_data.get("status"))
        self.instance.title = self.cleaned_data.get("title")

        self.instance.save()
        return self.instance


class IRForm(forms.Form):
    age_crit = forms.ChoiceField(choices=(("lt", _("Μικρότερη από")), ("lte", _("Μικρότερη ή ίση με")),
                                          ("eq", _("Ίση με")), ("gt", _("Μεγαλύτερη από")),
                                          ("gte", _("Μεγαλύτερη ή ίση με")), ("bt", _("Ανάμεσα σε")),
                                          ("!bt", _("Όχι ανάμεσα σε"))),
                                 required=False,
                                 initial=None,
                                 label=_("Με ηλικία:"),
                                 widget=forms.Select)


    age = forms.IntegerField(label=_(""), required=False, initial=None, min_value=0, max_value=200)
    ext_age = forms.IntegerField(label=_(""), required=False, initial=None, min_value=0, max_value=200)

    genders = forms.MultipleChoiceField(widget=forms.CheckboxSelectMultiple(attrs={"class": "gender-fld"}),
                                        initial=[],
                                        label=_("Φύλο:"),
                                        required=False,
                                        choices=sorted((("MALE", _("Άρρεν")), ("FEMALE", _("Θήλυ"))), key=lambda x: x[1]))
    add_study_window = forms.BooleanField(label=_("Προσθήκη χρονικού παραθύρου μελέτης"), initial=False, required=False)
    study_start_date = forms.DateField(label=_("Ημερομηνία έναρξης για το χρονικό παράθυρο της μελέτης:"),
                                       initial=None,
                                       required=False,
                                       widget=forms.DateInput)
    study_end_date = forms.DateField(label=_("Ημερομηνία λήξης για το χρονικό παράθυρο της μελέτης:"),
                                     initial=None,
                                     required=False,
                                     widget=forms.DateInput)

    def __init__(self, *args, **kwargs):
        self.options = kwargs.pop("ir_options")
        self.read_only = kwargs.pop("read_only")
        super(IRForm, self).__init__(*args, **kwargs)

        self.fields["study_start_date"].widget = forms.DateInput(attrs={
            'min': date(1917,11,7),
            'max': date.today(),
            'placeholder': _("ΕΕΕΕ-ΜΜ-ΗΗ"),
            'class': 'datepicker',
        }, )

        self.fields["study_end_date"].widget = forms.DateInput(attrs={
            'min': date(1917,11,7),
            'max': date.today(),
            'placeholder': _("ΕΕΕΕ-ΜΜ-ΗΗ"),
            'class': 'datepicker',
        }, )

        for k in self.fields.keys():
            if k == "add_study_window":
                self.initial[k] = self.options.get("study_start_date") and \
                                  self.options.get("study_end_date")
            else:
                self.initial[k] = self.options.get(k)
            self.fields[k].widget.attrs['disabled'] = bool(self.read_only)

    def is_valid(self):
        self.fields.get("study_start_date").required = self.data.get("add_study_window")
        self.fields.get("study_end_date").required = self.data.get("add_study_window")
        return super(IRForm, self).is_valid()

    def clean(self):
        super(IRForm, self).clean()

        if not self.cleaned_data.get("add_study_window"):
            self.cleaned_data["study_start_date"] = None
            self.cleaned_data["study_start_date"] = None

        return self.cleaned_data


class CharForm(forms.Form):

    features = forms.MultipleChoiceField(widget=forms.CheckboxSelectMultiple(attrs={"class": "char-features-fld"}),
                                        initial=[],
                                        label=_("Χαρακτηριστικά ανάλυσης:"),
                                        required=False,
                                        choices=[])

    def __init__(self, *args, **kwargs):
        self.options = kwargs.pop("char_options")
        self.read_only = kwargs.pop("read_only")
        super(CharForm, self).__init__(*args, **kwargs)

        analysis_features = ohdsi_wrappers.get_char_analysis_features()

        self.features_descriptions = dict([(el.get("name"), el.get("description")) for el in analysis_features])
        avail_features = ["Drug Group Era Long Term", "Charlson Index",
                          "Demographics Age Group", "Demographics Gender"]

        self.features_descriptions.update({
            "Charlson Index": _("Ο δείκτης συννοσηρότητας Charlson προβλέπει τη θνησιμότητα ενός έτους για "
                                "κάποιον ασθενή που μπορεί να έχει μια σειρά από συννοσηρές καταστάσεις, όπως "
                                "καρδιακές παθήσεις, AIDS ή καρκίνο (συνολικά 22 καταστάσεις). Σε κάθε "
                                "κατάσταση έχει βαθμολογία 1, 2, 3 ή 6, με τα υψηλότερα βάρη να δείχνουν "
                                "μεγαλύτερη σοβαρότητα κατάστασης και κίνδυνο θανάτου. Ο δείκτης Charlson "
                                "ενός ατόμου είναι το άθροισμα αυτών των βαρών. Στην παρούσα πλατφόρμα, "
                                "χρησιμοποιούμε την προσαρμογή Romano για τον δείκτη Charlson."),
            "Drug Group Era Long Term": _("Ομάδα ασθενών που έχουν εκτεθεί σε φάρμακα, τα οποία ανήκουν στην ίδια "
                                          "κατηγορία δραστικής ουσίας (ATC), για χρονικό παράθυρο μελέτης που εκκινεί "
                                          "365 ημέρες πριν, και φτάνει μέχρι και την ημέρα έναρξης της κοόρτης.")})

        self.fields["features"].choices = sorted([(f.get("id"), f.get("name")) for f in analysis_features
                                                  if f.get("name") in avail_features], key=lambda x: x[1])

        for k in self.fields.keys():
            self.initial[k] = self.options.get(k)  # if self.options else [c[1] for c in self.fields["features"].choices]
            self.fields[k].widget.attrs['disabled'] = bool(self.read_only)

class PathwaysForm(forms.Form):
    combination_window = forms.ChoiceField(choices=[(i,i) for i in [1, 3, 5, 7, 10, 14, 30]], initial=0, required=False,
                                           label=_("Χρονικό παράθυρο σύμπτωσης:"))

    min_cell_count = forms.ChoiceField(choices=[(i,i) for i in range(11)], initial=0, required=False,
                                       label=_("Πλήθος ελάχιστων κελιών:"))

    max_depth = forms.ChoiceField(choices=[(i,i) for i in range(1, 11)], initial=0, required=False,
                                  label=_("Μέγιστο μήκος μονοπατιού:"))

    def __init__(self, *args, **kwargs):
        self.options = kwargs.pop("cp_options")
        self.read_only = kwargs.pop("read_only")
        super(PathwaysForm, self).__init__(*args, **kwargs)

        self.fields_descriptions = {"combination_window": _("Χρονικό παράθυρο κατά το οποίο πρέπει δύο πληθυσμοί "
                                                           "συμβάντων να συμπέσουν, προκειμένου να θεωρηθεί ότι υπάρχει"
                                                           " συνδυασμός συμβάντων."),
                                    "min_cell_count": _("Ελάχιστος αριθμός υποκειμένων του στοχευμένου πληθυσμού της "
                                                        "ανάλυσης για κάθε δεδομένο συμβάν, προκειμένου να προσμετρηθεί"
                                                        " στην ανάλυση μονοπατιού."),
                                    "max_depth": _("Μέγιστος αριθμός βημάτων σε ένα δεδομένο μονοπάτι, που θα "
                                                   "συμπεριληφθεί στο σχετικό γράφημα δακτυλίου.")
                                    }

        for k in self.fields.keys():
            ok = k.replace("_", " ").title().replace(" ", "")
            ok = ok[0].lower() + ok[1:]
            self.initial[k] = self.options.get(ok)
            self.fields[k].widget.attrs['disabled'] = bool(self.read_only)


# class TinyMCEWidget(TinyMCE):
#     def use_required_attribute(self, *args):
#         return False


class NotesForm(forms.ModelForm):
    content = forms.CharField(label="", required=False,
                              widget=CKEditorWidget(attrs={'required': False,}))

    # content = forms.CharField(
    #     label="",
    #     required=False,
    #     widget=TinyMCE(
    #         attrs={'required': False, 'cols': 30, 'rows': 10}
    #     )
    # )


    class Meta:
        model = Notes
        fields = ['content']

class PatientForm(forms.ModelForm):
    scenarios = forms.ModelMultipleChoiceField(
        queryset=Scenario.objects.all(),
        widget=forms.CheckboxSelectMultiple, label=''
    )

    questionnaires = forms.ModelMultipleChoiceField(
        queryset=Questionnaire.objects.all(),
        widget=forms.CheckboxSelectMultiple, label=''
    )
    class Meta:
        model = PatientCase
        fields = ['patient_id', 'scenarios', 'questionnaires']

    def __init__(self, *args, **kwargs):
        super(PatientForm, self).__init__(*args, **kwargs)
        scenarios = Scenario.objects.all()
        self.fields['patient_id'].label = _('Ταυτότητα Ασθενούς')

        self.fields['scenarios'].choices = [(sc.pk, sc.title) for sc in scenarios]
        questionnaires = Questionnaire.objects.all()
        self.fields['questionnaires'].choices = [(sc.pk, sc.pk) for sc in questionnaires]




class QuestionnaireForm(forms.ModelForm):
    q1 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="1. Do you suspect an adverse drug reaction?"
    )
    q2 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="2. Did the event appear after the drug was administered or dose increased?"
    )
    q3 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="3. Were pre-existing symptoms exacerbated by the drug?"
    )
    q4 = forms.ChoiceField(
        choices=((True, 'Yes or Unassessable'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="4. Did the event improve( ± treatment ) when the drug was stopped or dose reduced?"
    )
    q5 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="5. Was the event associated with long-lasting disability or impairment?"
    )
    q6 = forms.ChoiceField(
        choices=((True, 'Low'), (False, 'High or Unsure')),
        widget=forms.RadioSelect(), required=False,
        label="6. What is the probability that the event was due to an underlying disease?"
    )
    q7 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="7. Is there any objective evidence supportive of the casual ADR mechanism?"
    )
    q8 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="8. Was there a positive rechallenge?"
    )
    q9 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="9. Is there a past history of the same event with this drug in this patient?"
    )
    q10 = forms.ChoiceField(
        choices=((True, 'Yes'), (False, 'No')),
        widget=forms.RadioSelect(), required=False,
        label="10. Has the event previously been reported with this drug?"
    )
    patient_id = forms.CharField(widget=forms.HiddenInput(), required=False)
    sc_id = forms.IntegerField(widget=forms.HiddenInput(), required=False)


    class Meta:
        model = Questionnaire

        fields = ('q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10')


    def save(self, commit=True):
        # print(self.cleaned_data)
        # self.cleaned_data['patient_id']=""
        return super(QuestionnaireForm, self).save(commit=commit)


