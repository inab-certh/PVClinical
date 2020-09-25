import re

from django import forms
from django_select2.forms import Select2TagWidget
from django.utils.translation import gettext_lazy as _

from app.models import Drug
from app.models import Condition
from app.models import Scenario
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
    # time_at_risk = forms.CharField(label=_("Διάστημα ανάλυσης:"), required=True)
    #
    # study_window = forms.MultipleChoiceField(choices=[0, 1, 7, 14, 21, 30, 60, 90,
    #                                                   120, 180, 365, 548, 730, 1095],
    #                                       required=False,
    #                                       label=_("Διάστημα ανάλυσης:"),
    #                                       widget=CustomSelect2TagWidget)

    add_study_window = forms.BooleanField(initial=False)
    study_start_date = forms.DateField(label=_("Ημερομηνία έναρξης για το παράθυρο της μελέτης"),
                                       initial=None,
                                       required=False,
                                       widget=forms.DateInput())
    study_end_date = forms.DateField(label=_("Ημερομηνία λήξης για το παράθυρο της μελέτης"),
                                     initial=None,
                                     required=False,
                                     widget=forms.DateInput())

    age_crit = forms.ChoiceField(choices=(("lt", _("Μικρότερη από")), ("lte", _("Μικρότερη ή ίση με")),
                                          ("eq", _("Ίση")), ("gt", _("Μεγαλύτερη από")),
                                          ("gte", _("Μεγαλύτερη ή ίση με")), ("bt", _("Ανάμεσα σε")),
                                          ("!bt", _("Όχι ανάμεσα σε"))),
                                 required=False,
                                 initial=None,
                                 label=_("Με ηλικία:"),
                                 widget=forms.Select())


    age = forms.IntegerField(required=False, initial=0)
    ext_age = forms.IntegerField(label=_("και"), required=False, initial=0)

    genders = forms.MultipleChoiceField(widget=forms.CheckboxSelectMultiple,
                                        initial=None,
                                        required=False,
                                        choices=sorted((("Μ", _("Άρρεν")), ("F", _("Θήλυ"))), key = lambda x: x[1]))

    def __init__(self, *args, **kwargs):
        self.options = kwargs.pop("ir_options")
        super(IRForm, self).__init__(*args, **kwargs)
        self.fields['study_start_date'].widget.attrs['placeholder'] = _("YYYY-MM-DD")
        self.fields['study_end_date'].widget.attrs['placeholder'] = _("YYYY-MM-DD")

        for k in self.fields.keys():
            if k != "add_study_window":
                print(k)
                self.fields[k] = self.options.get(k)
    #
    #     # If instance exists in database
    #     if Scenario.objects.filter(title=self.instance.title, owner=self.instance.owner).exists():
    #         self.fields["title"].initial = self.instance.title
    #         self.fields["status"].initial = self.instance.status
    #         init_drugs = ["{}{}".format(
    #             d.name, " - {}".format(d.code) if d.code else "") for d in self.instance.drugs.all()]
    #         self.fields["drugs_fld"].choices = list(zip(*[init_drugs]*2))
    #         self.fields["drugs_fld"].initial = init_drugs
    #
    #         init_conditions = ["{}{}".format(
    #             c.name, " - {}".format(c.code) if c.code else "") for c in self.instance.conditions.all()]
    #         self.fields["conditions_fld"].choices = list(zip(*[init_conditions] * 2))
    #         self.fields["conditions_fld"].initial = init_conditions
