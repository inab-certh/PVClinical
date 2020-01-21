import datetime

from functools import reduce
from itertools import chain

from django import forms
from django.core.exceptions import ValidationError
from django.db.models import Sum
from django.utils.safestring import mark_safe
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


# class CustomForm(forms.Form):
#
#     def __init__(self, *args, **kwargs):
#         super(CustomForm, self).__init__(*args, **kwargs)
#
#         for field in self.fields:
#             help_text = self.fields[field].help_text
#             self.fields[field].help_text = None
#             if help_text != '':
#                 self.fields[field].widget.attrs.update({
#                     'class': 'has-popover',
#                     'data-content': help_text,
#                     'data-placement': 'right',
#                     'data-container': 'body'})


#
#
# class ListTextWidget(forms.TextInput):
#     def __init__(self, data_list, name, *args, **kwargs):
#         super(ListTextWidget, self).__init__(*args, **kwargs)
#         self._name = name
#         self._list = data_list
#         self.attrs.update({'list':'list__%s' % self._name})
#
#     def render(self, name, value, attrs=None):
#         text_html = super(ListTextWidget, self).render(name, value, attrs=attrs)
#         data_list = '<datalist id="list__%s">' % self._name
#         for item in self._list:
#             data_list += '<option value="%s">' % item
#         data_list += '</datalist>'
#
#         return (text_html + data_list)
#
#
# class FormForm(forms.Form):
#     char_field_with_list = forms.CharField(required=True)
#
#     def __init__(self, *args, **kwargs):
#         _country_list = kwargs.pop('data_list', None)
#         super(FormForm, self).__init__(*args, **kwargs)
#
#         # the "name" parameter will allow you to use the same widget more than once in the same
#         # form, not setting this parameter differently will cuse all inputs display the
#         # same list.
#         self.fields['char_field_with_list'].widget = ListTextWidget(data_list=_data_list, name='country-list')


class ScenarioForm(forms.Form):
    # class Meta:
    #     model = Scenario
    #     fields = ['drugs',
    #               'conditions',]
    #
    #     labels = {
    #         'drugs': _('Φάρμακα:'),
    #         'conditions': _('Παθήσεις:'),
    #     }
    #
    #     widgets = {
    #         'drugs': Select2TagWidget(
    #             attrs={
    #             }
    #         ),
    #         'conditions': Select2TagWidget(
    #             attrs={
    #             }
    #         )
    #     }

    # pass
    knw = KnowledgeGraphWrapper()
    all_drugs = knw.get_drugs()

    all_conditions = knw.get_conditions()

    # all_drugs = get_drugs()
    # all_conditions = get_conditions()
    # all_synonyms = list(chain(get_synonyms(all_drugs)))

    # all_synonyms = reduce(lambda syns1, syns2: syns1+syns2, map(lambda d: d.synonyms.all(), all_drugs))

    title = forms.CharField(label=_("Τίτλος σεναρίου:"), required=True)

    drugs_fld = forms.MultipleChoiceField(choices=[("{}{}".format(
        d.name, " - {}".format(d.code) if d.code else ""),)*2 for d in all_drugs],
                                              required=False,
                                              label=_("Φάρμακο/Φάρμακα:"),
                                              widget=CustomSelect2TagWidget)
    conditions_fld = forms.MultipleChoiceField(choices=[("{}{}".format(
        c.name, " - {}".format(c.code) if c.code else ""),)*2 for c in all_conditions],
                                                   required=False,
                                                   label=_("Πάθηση/Παθήσεις:"),
                                                   widget=CustomSelect2TagWidget)



    # drugs_by_name = forms.MultipleChoiceField(choices=[(d.name, "{}{}".format(
    #     d.name, " - {}".format(d.code) if d.code else "")) for d in all_drugs],
    #                                           required=False,
    #                                           label=_("Φάρμακα:"),
    #                                           widget=CustomSelect2TagWidget)
    # conditions_by_name = forms.MultipleChoiceField(choices=[(c.name, "{}{}".format(
    #     c.name, " - {}".format(c.code) if c.code else "")) for c in all_conditions],
    #                                                required=False,
    #                                                label=_("Παθήσεις:"),
    #                                                widget=CustomSelect2TagWidget)

    #
    # drugs_by_code = forms.MultipleChoiceField(choices=[(d.code, "{}{}".format(
    #     d.code, " - {}".format(d.name) if d.name else "")) for d in all_drugs],
    #                                           required=False,
    #                                           label=_("Κωδικοί φαρμάκων:"),
    #                                           widget=Select2TagWidget)
    #
    # conditions_by_code = forms.MultipleChoiceField(choices=[(c.code, "{}{}".format(
    #     c.code, " - {}".format(c.name) if c.name else "")) for c in all_conditions],
    #                                                required=False,
    #                                                label=_("Κωδικοί παθήσεων:"),
    #                                                widget=Select2TagWidget)

    # drug_synonyms = forms.ChoiceField(choices=[("","")]+all_synonyms, required=False, label=_("Συνώνυμα:"))

    status = forms.ChoiceField(choices=Status.status_choices, required=False, label=_("Κατάσταση σεναρίου:"))


    # drugs_hidden = forms.CharField(required=False, max_length=0, widget=forms.HiddenInput())
    # conditions_hidden = forms.CharField(required=False, max_length=0, widget=forms.HiddenInput())

    def __init__(self, *args, **kwargs):
        self.instance = kwargs.pop("instance")
        super(ScenarioForm, self).__init__(*args, **kwargs)

        # If instance exists in database
        if Scenario.objects.filter(title=self.instance.title, owner=self.instance.owner).exists():
            self.fields["title"].initial = self.instance.title
            self.fields["status"].initial = self.instance.status
            init_drugs = ["{}{}".format(
                d.name, " - {}".format(d.code) if d.code else "") for d in self.instance.drugs.all()]
            self.fields["drugs_fld"].initial = init_drugs

            init_conditions = ["{}{}".format(
                c.name, " - {}".format(c.code) if c.code else "") for c in self.instance.conditions.all()]
            self.fields["conditions_fld"].initial = init_conditions

    def is_valid(self):
        """ Overriding-extending is_valid module
        """

        # At least one of drugs_by_code or drugs_by_name has to be filled in
        # if (not self.cleaned_data.get("drugs_by_name")) and not self.cleaned_data.get("drugs_by_code"):
        #     self.add_error(None, _("Τουλάχιστον ένα από τα πεδία που αφορούν είτε φάρμακα βάσει ονόματος\
        #                                       είτε φάρμακα βάσει κωδικού, πρέπει να συμπληρωθεί!"))
        #
        # # At least one of drugs_by_code or drugs_by_name has to be filled in
        # if (not self.cleaned_data.get("conditions_by_name")) and not self.cleaned_data.get("conditions_by_code"):
        #     self.add_error(None,
        #                    _("Τουλάχιστον ένα από τα πεδία που αφορούν είτε παθήσεις βάσει ονόματος\
        #                      είτε παθήσεις βάσει κωδικού, πρέπει να συμπληρωθεί!"))

        super(ScenarioForm, self).is_valid()

        if (not self.cleaned_data.get("drugs_fld")) and not self.cleaned_data.get("conditions_fld"):
            self.add_error(None, _("Τουλάχιστον ένα από τα πεδία που αφορούν τα φάρμακα και τις παθήσεις\
                                   του σεναρίου, πρέπει να συμπληρωθεί"))


        return not self._errors


    def clean(self):
        super(ScenarioForm, self).clean()

        selected_drugs = dict(self.data).get("drugs_fld")
        drugs_names = list(map(lambda el: el.name, self.all_drugs))
        drugs_codes = list(map(lambda el: el.code, self.all_drugs))

        if selected_drugs:
            # If not found index is -1, max is used to assure that in case one of the two splitted parts
            # was found, then this part was chosen to find suspected drug
            drugs_indexes = [(max(list(map(lambda el: drugs_names.index(el) if el in drugs_names \
                else drugs_codes.index(el) if el in drugs_codes else -1, sd.split(" - "))))) for sd in selected_drugs]

            valid_drugs = list(filter(lambda d: d is not None,
                                      (map(lambda indx: self.all_drugs[indx]\
                                          if (indx>-1 and indx<len(self.all_drugs)) else None, drugs_indexes))))
            valid_drugs = list(map(lambda d: "{} - {}".format(d.name, d.code), valid_drugs))

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
                                      (map(lambda indx: self.all_conditions[indx]\
                                          if (indx>-1 and indx<len(self.all_conditions)) else None,
                                           conditions_indexes))))

            valid_conditions = list(map(lambda c: "{} - {}".format(c.name, c.code), valid_conditions))

            if 'conditions_fld' in self._errors:
                del self._errors['conditions_fld']

        # return valid_conditions
            self.cleaned_data["conditions_fld"] = valid_conditions
        return self.cleaned_data


    def save(self, commit=True):
        """ Overriding-extending save module
        """
        self.instance.save(checks=False)
        drugs = []
        conditions = []

        for drug in self.cleaned_data.get("drugs_fld"):
            dname, dcode = drug.split(" - ")
            drugs.append(Drug.objects.get_or_create(name=dname, code=dcode)[0])
        self.instance.drugs.set(drugs)

        for condition in self.cleaned_data.get("conditions_fld"):
            cname, ccode = condition.split(" - ")
            conditions.append(Condition.objects.get_or_create(name=cname, code=ccode)[0])
        self.instance.conditions.set(conditions)

        self.instance.status = Status.objects.get(status=self.cleaned_data.get("status"))
        self.instance.title = self.cleaned_data.get("title")

        self.instance.save()
        return self.instance
