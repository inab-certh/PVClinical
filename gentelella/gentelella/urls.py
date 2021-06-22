"""gentella URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.10/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.conf.urls import url, include
from django.urls import path
from django.contrib import admin
from django.views.i18n import JavaScriptCatalog

from django.conf.urls.i18n import i18n_patterns
from app.views import index

js_info_dict = {
    'domain': 'djangojs',
    'packages': ('gentelella',),
}
# urlpatterns = [
#     url(r'^(?P<filename>(robots.txt)|(humans.txt))$',
#         index, name='home-files'),
# ]

urlpatterns = [
    path('i18n/', include('django_translation_flags.urls')),
    path('jsi18n/', JavaScriptCatalog.as_view(), name='javascript-catalog'),
    url(r'^select2/', include('django_select2.urls')),
    url(r'^admin/', admin.site.urls),
    path('accounts/', include('django.contrib.auth.urls')),


    # app/ -> Genetelella UI and resources
    # url(r'^app/', include('app.urls')),
    url(r'^', include('app.urls')),

]
