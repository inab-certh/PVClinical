from django.http import HttpResponseRedirect

import re

class PasswordChangeMiddleware(object):
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        next = '/accounts/password_change/'
        if request.user.is_authenticated and request.path != next:
            if not re.match(r'^/admin/?', request.path) \
                    and request.user.cuser.force_password_change:
                return HttpResponseRedirect(next)
        return response
