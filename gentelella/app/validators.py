'''
Created on Sep 24, 2018

@author: b.dimitriadis
'''

from django.core.validators import RegexValidator
from django.utils.text import format_lazy
from django.utils.translation import gettext_lazy as _

ic_id_validator = RegexValidator(
    # r"\d{4}[A-Z]{3}\d{7}",
    r"^\d+$",
    format_lazy("{} 10029250", _("Παράδειγμα ορθού αναγνωριστικού:")))

prof_validator = RegexValidator(
    r"^[a-zA-Zα-ωΑ-Ω]+(" "[a-zA-Zα-ωΑ-Ω]+)*$",
    _("Τα δεδομένα εισαγωγής σας μπορούν να περιέχουν μόνο αλφαβητικούς χαρακτήρες και κενά"))


address_validator = RegexValidator(
    r"^[^\W\d_ ]+([-, ]{1,3}[^\W\d_ ]+)*$",
    _("Τα δεδομένα εισαγωγής σας μπορούν να περιέχουν μόνο αλφαβητικούς χαρακτήρες κενά, κόμματα και παύλες"))

# address_validator = RegexValidator(
#     r"^[^\W\d_ ]+([-, ]{1,3}[\w^_]+)*$",
#     "Τα δεδομένα εισαγωγής σας μπορούν να περιέχουν μόνο \
#      αλφαριθμητικούς χαρακτήρες, κενά, κόμματα και παύλες")

sn_validator = RegexValidator(
    r"^[A-Za-z\d -]*$",
    _("Τα δεδομένα εισαγωγής σας μπορούν να περιέχουν μόνο αλφαριθμητικούς χαρακτήρες, κενά και παύλες"))
