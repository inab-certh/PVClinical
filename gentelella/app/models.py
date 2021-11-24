from __future__ import unicode_literals
from datetime import datetime
from decimal import Decimal

from bs4 import BeautifulSoup
from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator
from django.core.validators import MinValueValidator
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _

from ckeditor.fields import RichTextField
# from tinymce.models import HTMLField

from app.helper_modules import choices_max_length


# Create your models here.
class Status(models.Model):
    """ Scenario's status
    """

    status_choices = [("CREATING", _("Υπό δημιουργία")),
                      ("RUNNING", _("Σε εξέλιξη")),
                      ("COMPLETED", _("Ολοκληρώθηκε")),]

    status = models.CharField(
        _("Κατάσταση: "),
        unique=True,
        max_length=choices_max_length(status_choices),
        choices=status_choices,
        default=status_choices[0][0])

    def __unicode__(self):
        return dict(self.status_choices)[self.status]

    class Meta:
        ordering = ['id',]


class Drug(models.Model):
    """ Drug (name or code)
    """
    name = models.CharField(max_length=50,
                            null=True,
                            blank=True,
                            default="",
                            validators=[
                                RegexValidator(
                                    regex='^[\w\-,\(\) ]*$',
                                    message=_('Όνομα φαρμάκου'),
                                    code='invalid_drug',
                                ),
                            ])
    code = models.CharField(max_length=7,
                            null=True,
                            blank=True,
                            default="",
                            validators=[
                                RegexValidator(
                                    regex='^[a-zA-Z]{1}[0-9]{2}[a-zA-Z]{2}[0-9]{2}$',
                                    message=_('Κωδικοποίηση φαρμάκου'),
                                    code='invalid_drug',
                                ),
                            ])

    # synonyms = models.ManyToManyField("self", default=None, blank=True, related_name="drugs")

    def clean(self):
        super().clean()
        if not self.name and not self.code:
            raise ValidationError(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))

    def save(self, *args, **kwargs):
        if not self.name and not self.code:
            raise Exception(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))
        super(Drug, self).save(*args, **kwargs)

    # def __str__(self):
    #     return "{}".format(self.name or self.code)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["name", "code"], name="unique_drug")
        ]


class Condition(models.Model):
    """ Condition (name or code)
    """
    name = models.CharField(max_length=50,
                            null=True,
                            blank=True,
                            default="",
                            validators=[
                                RegexValidator(
                                    regex='^[\w\-,\(\) ]*$',
                                    message=_('Όνομα πάθησης'),
                                    code='invalid_disease',
                                ),
                            ])
    code = models.CharField(max_length=8,
                            null=True,
                            blank=True,
                            default="",
                            validators=[
                                RegexValidator(
                                    regex='^\d{8}$',
                                    message=_("Κωδικοποίηση πάθησης"),
                                    code='invalid_disease',
                                ),
                            ])

    def clean(self):
        super().clean()
        if not self.name and not self.code:
            raise ValidationError(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))

    def save(self, *args, **kwargs):
        if not self.name and not self.code:
            raise Exception(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))
        super(Condition, self).save(*args, **kwargs)

    # def __str__(self):
    #     return "{}".format(self.name or self.code)


    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["name", "code"], name="unique_condition")
        ]


class Scenario(models.Model):
    """ Scenario consisting of a drug-disease pair
    """

    title = models.CharField(max_length=50, null=True, blank=True, default="",
                             validators=[RegexValidator(
                                 regex='^[\w\-,\(\) ]*$',
                                 message=_('Τίτλος Σεναρίου'),
                                 code='invalid_title',),])

    # Drug name or code
    drugs = models.ManyToManyField(Drug, default=None, blank=True,
                                   verbose_name="drugs", related_name="drugs")

    # MedDRA name or code
    conditions = models.ManyToManyField(Condition, default=None, blank=True,
                                        verbose_name="conditions", related_name="conditions")

    status = models.ForeignKey(Status, default=1, on_delete=models.PROTECT)

    owner = models.ForeignKey(User, on_delete=models.CASCADE)

    timestamp = models.DateTimeField(auto_now_add=True)

    # def clean(self):
    #     super().clean()
    #     if not self.drugs and not self.conditions:
    #         raise ValidationError(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))

    def save(self, *args, checks=True, **kwargs):
        if checks and not self.drugs and not self.conditions:
            raise Exception(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))
        super(Scenario, self).save(*args, **kwargs)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["title", "owner"], name="unique_scenario")
        ]


class PubMed(models.Model):
    """
        PubMed articles and user notes
    """
    CHOICES = [(True, 'Relevant'), (False, 'Irrelevant'), ('Not sure', 'Not sure')]
    user = models.ForeignKey(User, on_delete=models.CASCADE, default=1)
    pid = models.CharField(max_length=70, blank=False, default='')
    title = models.CharField(max_length=500, blank=False, default='')
    pubdate = models.CharField(max_length=400, blank=False, default='')
    abstract = models.TextField(null=True, blank=True)
    authors = models.CharField(max_length=400, blank=False, default='')
    url = models.CharField(max_length=100, blank=False, default='')
    relevance = models.CharField(max_length=20, choices=CHOICES, null=True, default='')
    notes = models.TextField(null=True, blank=True)

    scenario_id = models.ForeignKey(Scenario, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["pid", "user", "scenario_id"], name="unique_article")
        ]

    # created = models.DateTimeField(auto_now_add=True)


class Notes(models.Model):
    """ Notes for users for the various workspaces of a scenario
    """
    # content = HTMLField(blank=True, default="")
    content = RichTextField(blank=True, default="")

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    scenario = models.ForeignKey(Scenario, null=True, on_delete=models.CASCADE)
    workspace = models.PositiveSmallIntegerField(validators=[MinValueValidator(1),
                                                             MaxValueValidator(5)])
    wsview = models.CharField(max_length=32, default='')  # Workspace specific view
    note_datetime = models.DateTimeField(auto_now_add=True, blank=True)

    def save(self, *args, **kwargs):
        if not BeautifulSoup(self.content, "lxml").text.strip():
            if self.pk is None:
                # creating a new instance - just don't save anything
                return
            else:
                # updating an existing instance - delete self
                self.delete()
        else:
            super().save(*args, **kwargs)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "scenario", "workspace", "wsview"],
                                    name="unique_note")
        ]


class Questionnaire(models.Model):

    q1= models.BooleanField(null=True,default=None)
    q2= models.BooleanField(null=True,default=None)
    q3= models.BooleanField(null=True,default=None)
    q4= models.BooleanField(null=True,default=None)
    q5= models.BooleanField(null=True,default=None)
    q6= models.BooleanField(null=True,default=None)
    q7= models.BooleanField(null=True,default=None)
    q8= models.BooleanField(null=True,default=None)
    q9= models.BooleanField(null=True,default=None)
    q10= models.BooleanField(null=True,default=None)

    result= models.CharField(max_length=200)


    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["q1", "q2", "q3", "q4", "q5",
                                            "q6", "q7", "q8", "q9", "q10"],
                                    name="unique_questionnaire")
        ]


class PatientCase(models.Model):
    """ PatientCase for user's patients for Patient Management Workspace
    """
    patient_id = models.CharField(max_length=500, blank=False, default='')
    user = models.ForeignKey(User, on_delete=models.CASCADE)

    #ena scenario mporei na to exoun polloi astheneis, alla kai 1 asthenis mporei na exei polla senaria
    scenarios = models.ManyToManyField(Scenario, through= "CaseToScenario", default=None,
                                        verbose_name="scenarios", related_name="scenarios")

    questionnaires = models.ManyToManyField(Questionnaire, through= "CaseToQuestionnaire", default=None,
                                        verbose_name="questionnaires", related_name="questionnaires")
    #ena questionnaire mporoun na to exoun polloi astheneis, alla kai enas asthenis mporei na exei polla questionnaire,
    #ara h arxiki skepsi tou vlasi mou fainetai swsth, oxi foreignkey, alla pali manytomany
    #me to manytomany na ftiaxw sti vasi allon enan pinaka casetoquestionnaire, opws exw casetoscenario
    timestamp = models.DateTimeField(auto_now_add=True, blank=True)


    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["patient_id", "timestamp"],
                                    name="unique_patientcase")
        ]


class CaseToScenario(models.Model):
    scenario = models.ForeignKey(Scenario, on_delete=models.CASCADE)
    pcase = models.ForeignKey(PatientCase, on_delete=models.CASCADE)
    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["scenario", "pcase"],
                                    name="unique_pcase_scenario")
        ]


class CaseToQuestionnaire(models.Model):
    questionnaire = models.ForeignKey(Questionnaire, on_delete=models.CASCADE)
    pcaseq = models.ForeignKey(PatientCase, on_delete=models.CASCADE)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["questionnaire", "pcaseq"],
                                    name="unique_questionnaire_pcaseq")
        ]

# class Questionnaire(models.Model):
#
#     q1= models.BooleanField(null=True,default=None)
#     q2= models.BooleanField(null=True,default=None)
#     q3= models.BooleanField(null=True,default=None)
#     q4= models.BooleanField(null=True,default=None)
#     q5= models.BooleanField(null=True,default=None)
#     q6= models.BooleanField(null=True,default=None)
#     q7= models.BooleanField(null=True,default=None)
#     q8= models.BooleanField(null=True,default=None)
#     q9= models.BooleanField(null=True,default=None)
#     q10= models.BooleanField(null=True,default=None)
#
#     result= models.CharField(max_length=200)
#
#
#     class Meta:
#         constraints = [
#             models.UniqueConstraint(fields=["q1", "q2", "q3", "q4", "q5",
#                                             "q6", "q7", "q8", "q9", "q10"],
#                                     name="unique_patientcase")
#         ]





