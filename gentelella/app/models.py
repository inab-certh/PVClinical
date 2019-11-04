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
                      ("RUNNING", _("Τρέχει")),
                      ("COMPLETED", _("Ολοκληρώθηκε")),]

    status = models.CharField(
        _("Κατάσταση: "),
        unique=True,
        max_length=choices_max_length(status_choices),
        choices=status_choices,
        default=status_choices[0][0])

    def __str__(self):
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

    def clean(self):
        super().clean()
        if not self.name and not self.code:
            raise ValidationError(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))

    def save(self, *args, **kwargs):
        if not self.name and not self.code:
            raise Exception(_('Δεν μπορούν και τα δύο πεδία να είναι κενά'))
        super(Drug, self).save(*args, **kwargs)

    def __str__(self):
        return "{}".format(self.name or self.code)

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

    def __str__(self):
        return "{}".format(self.name or self.code)


    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["name", "code"], name="unique_condition")
        ]


class Scenario(models.Model):
    """ Scenario consisting of a drug-disease pair
    """

    # Drug name or code
    drugs = models.ManyToManyField(Drug, default=None, related_name="drugs")

    # MedDRA name or code
    conditions = models.ManyToManyField(Condition, default=None, related_name="conditions")

    status = models.ForeignKey(Status, on_delete=models.PROTECT)

    owner = models.ForeignKey(User, on_delete=models.CASCADE)

    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["drugs", "conditions", "owner"], name="unique_scenario")
        ]


