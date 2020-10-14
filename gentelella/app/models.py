from __future__ import unicode_literals
from datetime import datetime
from decimal import Decimal

from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator
from django.core.validators import MinValueValidator
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _

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

class OHDSIWorkspace(models.Model):
    """ OHDSI workspace correlating with scenario
    """

    sc_id = models.ForeignKey(Status, null=True, default=None, on_delete=models.PROTECT)  # Scenario id
    ir_id = models.IntegerField(blank=True, null=True, default=-1)  # incidence rates record id
    ch_id = models.IntegerField(blank=True, null=True, default=-1)  # characterizations record id
    cp_id = models.IntegerField(blank=True, null=True, default=-1)  # cohort pathways record id

class PubMed(models.Model):
    """
        PubMed articles and user notes
    """
    CHOICES = [(True,'Relevant'), (False, 'Irrelevant'), ('Not sure', 'Not sure')]
    user = models.ForeignKey(User, on_delete=models.CASCADE, default=1)
    pid = models.CharField(max_length=70, blank=False, default='', primary_key=True)
    title = models.CharField(max_length=500, blank=False, default='')
    pubdate = models.CharField(max_length=400, blank=False, default='')
    abstract = models.TextField(null=True, blank=True)
    authors = models.CharField(max_length=400, blank=False, default='')
    url = models.CharField(max_length=100, blank=False, default='')
    relevance = models.CharField(max_length=20, choices=CHOICES, null=True, default='')
    notes = models.TextField(null=True, blank=True)
    # created = models.DateTimeField(auto_now_add=True)