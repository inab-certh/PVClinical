import datetime

from django import forms
from django.core.exceptions import ValidationError
from django.db.models import Sum
from django.utils.safestring import mark_safe

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



class ScenarioForm(CustomModelForm):

    class Meta:
        model = Scenario
        fields = ['drugs', 'conditions']

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
    def __init__(self, *args, **kwargs):
        super(ScenarioForm, self).__init__(*args, **kwargs)
        self.instance = kwargs.pop('instance', None)
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
