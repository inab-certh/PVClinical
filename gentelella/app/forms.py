import datetime

from django import forms
from django.core.exceptions import ValidationError
from django.db.models import Sum
from django.utils.safestring import mark_safe
from django_select2.forms import Select2TagWidget
from django.utils.translation import gettext_lazy as _


from app.models import Drug
from app.models import Condition
from app.models import Scenario


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
    #         'drugs': Select2MultipleWidget(
    #             attrs={
    #             }
    #         ),
    #         'conditions': Select2MultipleWidget(
    #             attrs={
    #             }
    #         )
    #     }
    # pass
    drugs = forms.ModelMultipleChoiceField(queryset=Drug.objects.all(), widget=Select2TagWidget)
    #
    # drug = forms.CharField(required=True)
    conditions = forms.ModelMultipleChoiceField(queryset=Condition.objects.all(), widget=Select2TagWidget)

    #     labels = {
    #         '': '',
    #     }
    #     widgets = {
    #         'adult': forms.RadioSelect(attrs={
    #             'class': 'list-inline',
    #         },),
    #
    #
    #         'ma_subscription_date': forms.DateInput(attrs={
    #            'min': '-150y',
    #            'max': '+0d',
    #            'placeholder': 'Επιλέξτε ημερομηνία',
    #            'class': 'datepicker',
    #         },)
    #     }
    #
    def __init__(self, instance=None, *args, **kwargs):
        super(ScenarioForm, self).__init__(*args, **kwargs)
        self.instance = instance
        print(instance)
        # self.fields['pat_id'].widget.attrs['readonly'] = True
    #
    # def is_valid(self):
    #     """ Overriding-extending is_valid module
    #     """
    #     super(ScenarioForm, self).is_valid()
    #
    #     # Extend registration validation,
    #     # ma_subscription_date cannot be greater than birth_date
    #     if self.cleaned_data.get('') and 'birth_year'\
    #             in self.cleaned_data and\
    #         self.cleaned_data.get('ma_subscription_date').year <\
    #             self.cleaned_data.get('birth_year'):
    #         self.add_error('ma_subscription_date', "Η ημερομηνία εγγραφής του ασθενούς,\
    #         δεν μπορεί να είναι προγενέστερη της ημερομηνίας γέννησης")
    #
    #     return not self._errors
    # #
    # def save(self, commit=True):
    #     """ Overriding-extending save module
    #     """
    #     tmp_pat = super(RegisterForm, self).save(commit)
    #     if tmp_pat:
    #         initial_care_center = self.instance.pat_id[:3]
    #         filtered_centers = Center.objects.filter(code=initial_care_center)
    #         if filtered_centers:
    #             tmp_pat.care_centers.add(filtered_centers[0])
    #
    #         tmp_pat.care_centers.add(self.cleaned_data.get('care_center'))
    #         tmp_pat.save()
