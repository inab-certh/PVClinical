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

from app.retrieve_meddata import get_drugs
from app.retrieve_meddata import get_conditions


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
    all_drugs = get_drugs()
    all_conditions = get_conditions()
    # all_synonyms = list(chain(get_synonyms(all_drugs)))

    # all_synonyms = reduce(lambda syns1, syns2: syns1+syns2, map(lambda d: d.synonyms.all(), all_drugs))

    title = forms.CharField(label=_("Τίτλος Σεναρίου"), required=True)

    drugs_fld = forms.MultipleChoiceField(choices=[("{}{}".format(
        d.name, " - {}".format(d.code) if d.code else ""),)*2 for d in all_drugs],
                                              required=False,
                                              label=_("Φάρμακα:"),
                                              widget=CustomSelect2TagWidget)
    conditions_fld = forms.MultipleChoiceField(choices=[("{}{}".format(
        c.name, " - {}".format(c.code) if c.code else ""),)*2 for c in all_conditions],
                                                   required=False,
                                                   label=_("Παθήσεις:"),
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

    #
    def is_valid(self):
        """ Overriding-extending is_valid module
        """
        super(ScenarioForm, self).is_valid()

        # At least one of drugs_by_code or drugs_by_name has to be filled in
        if (not self.cleaned_data.get("drugs_by_name")) and not self.cleaned_data.get("drugs_by_code"):
            self.add_error(None, _("Τουλάχιστον ένα από τα πεδία που αφορούν είτε φάρμακα βάσει ονόματος\
                                              είτε φάρμακα βάσει κωδικού, πρέπει να συμπληρωθεί!"))

        # At least one of drugs_by_code or drugs_by_name has to be filled in
        if (not self.cleaned_data.get("conditions_by_name")) and not self.cleaned_data.get("conditions_by_code"):
            self.add_error(None,
                           _("Τουλάχιστον ένα από τα πεδία που αφορούν είτε παθήσεις βάσει ονόματος\
                             είτε παθήσεις βάσει κωδικού, πρέπει να συμπληρωθεί!"))

        return not self._errors
    # #

    def clean(self):
        print("By code:")
        print(self.data.get("drugs_by_code"))
        print("By name:")
        print(self.data.get("drugs_by_name"))
        return self.cleaned_data


    def save(self, commit=True):
        """ Overriding-extending save module
        """
        print("Save")
        # drugs = [Drug.objects.get_or_create() for d in self.drugs_by_name+self.drugs_by_code]
        # conditions = [Condition.objects.get_or_create(name=c) for c in self.drugs_by_name] + [Condition.objects.get_or_create(code=c) for c in self.drugs_by_code]
        # d_n, created =
        # d_c, created = Drug.objects.get_or_create()
        #
        # self.instance.title = self.title
        # self.instance.drugs = self.drugs_by_name + self.drugs_by_code
        # self.instance.conditions = self.conditions_by_name + self.conditions_by_code