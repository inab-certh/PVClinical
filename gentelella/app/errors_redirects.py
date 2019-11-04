'''
Created on Nov 21, 2018

@author: b.dimitriadis
'''

from django.http import HttpResponseForbidden
from django.shortcuts import render
from django.utils.translation import gettext_lazy as _


def forbidden_redirect(request):
    return HttpResponseForbidden(
            render(request, "app/app_errors.html", context={
                'window_title': "Δεν επιτρέπεται η πρόσβαση!",
                'exception':
                _('Δεν επιτρέπεται η απευθείας πρόσβαση σε αυτήν τη σελίδα')})
            )
