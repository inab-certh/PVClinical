from __future__ import unicode_literals
from datetime import datetime
from decimal import Decimal

from django.db import models
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
        default=None,)

    def __str__(self):
        return dict(self.status_choices)[self.status]

    class Meta:
        ordering = ['id',]


class Scenario(models.Model):
    """ Scenario consisting of a drug-disease pair
    """

    # ATC
    drug = models.CharField(max_length=7,
                            validators=[
                                RegexValidator(
                                    regex='^[a-zA-Z]{1}[0-9]{2}[a-zA-Z]{2}[0-9]{2}$',
                                    message=_('Όνομα φαρμάκου ή κωδικοποίηση ATC'),
                                    code='invalid_drug',
                                ),
                            ])

    # MedDRA
    condition = models.CharField(max_length=9,
                                 validators=[
                                     RegexValidator(
                                         regex='^[a-zA-Z]{2,4}-[0-9]{2,5}$',
                                         message=_("Όνομα πάθησης ή κωδικοποίηση MedDRA"),
                                         code='invalid_disease',
                                     ),
                                 ])

    status = models.ForeignKey(Status, on_delete=models.CASCADE)

    timestampt =  models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = (("drug", "condition"),)

