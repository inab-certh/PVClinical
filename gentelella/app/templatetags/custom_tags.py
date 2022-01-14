'''
Created on Dec 14, 2018

@author: b.dimitriadis
'''
import datetime
from django import template
from django.utils.translation import gettext_lazy as _
from django.utils.translation import gettext
from django.utils import translation
from django.template import Node,  Variable, TemplateSyntaxError


register = template.Library()


@register.simple_tag(takes_context=True)
def lang_to_flag(context, lang=None, *args, **kwargs):
    lang_flag_dict = {"el": "gr", "en": "gb"}
    return lang_flag_dict.get(lang)


@register.filter(name='field_type')
def field_type(field):
    return field.field.widget.__class__.__name__

@register.filter
def get_item(dictionary, key):
    return dictionary.get(key)

@register.filter
def remove_char(string, char):
    return string.replace(char, "")

@register.filter
def get_elmnt_by_val(lst, val):
    return (list(filter(lambda el: el.get("id") == val, lst)) + [None])[0]

@register.filter
def get_elmnt_by_index(lst, indx):
    return lst[indx]

@register.filter
def underscore_char(string, char):
    return string.replace(char, "_")

@register.filter()
def is_numeric(value):
    return value.isdigit()

@register.simple_tag(takes_context=True)
def breadcrumb_label(context, name, *args, **kwargs):
    names_to_labels = {"index": _("Αρχική Σελίδα"),
                       "add-scenario": _("Σενάριο"),
                       "edit-scenario": _("Σενάριο"),
                       "drug-exposure": _("Έκθεση σε Φάρμακα"),
                       "condition-occurrence": _("Εκδήλωση Κατάστασης"),
                       "ir": _("Ρυθμός Επίπτωσης"),
                       "char": _("Χαρακτηρισμός Πληθυσμού"),
                       "cp": _("Μονοπάτι Ακολουθίας Συμβάντων"),
                       "OpenFDAWorkspace": _("Περιβάλλον Εργασίας OpenFDA"),
                       "ohdsi-workspace": _("Περιβάλλον Εργασίας OHDSI"),
                       "LiteratureWorkspace": _("Περιβάλλον Εργασίας PubMed"),
                       "paper_notes_view": _("Σημειώσεις Βιβλιογραφίας"),
                       "notes": _("Σημειώσεις"),
                       "aggr-notes": _("Συγκεντρωτικές Σημειώσεις"),
                       "social-media": _("Περιβάλλον Εργασίας Μέσων Κοινωνικής Δικτύωσης"),}

    return names_to_labels.get(name)

@register.filter()
def next(lst, arg):
    try:
        return lst[int(arg)+1]
    except:
        return None


class TransNode(Node):
    def __init__(self, value, lc):
        self.value = Variable(value)
        self.lc = lc

    def render(self, context):
        translation.activate(self.lc)
        val = _(self.value.resolve(context))
        translation.deactivate()
        return val


@register.filter()
def trans_to(token, lang):
    with translation.override(lang):
        val = gettext(token)
    return val

@register.filter
def hexdigest_in_dict(dic):
    import string
    return len(list(filter(lambda el: all(c in string.hexdigits for c in el) and len(el) == 32, dic.keys()))) > 0

@register.filter
def str_to_date(dt):
    return datetime.datetime.strptime(dt.replace(" ", ""), "%Y-%m-%d").date()