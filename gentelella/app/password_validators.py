from django.core.exceptions import ValidationError
from django.utils.translation import ugettext as _
import re

class ComplexPasswordValidator:
    """
    Validate whether the password contains minimum one uppercase, one digit and one symbol.
    """
    def validate(self, password, user=None):
        if re.search('[A-Z]', password)==None or re.search('[0-9]', password)==None\
                or re.search('[^A-Za-z0-9]', password)==None:
            raise ValidationError(
                _("Αδύναμο συνθηματικό."),
                code='password_is_weak',
            )

    def get_help_text(self):
        return _("Το συνθηματικό σας πρέπει να περιέχει, τουλάχιστον 1 αριθμό, "
                "1 κεφαλαίο γράμμα και 1 μη αλφαριθμητικό χαρακτήρα (σύμβολο)."
            )
