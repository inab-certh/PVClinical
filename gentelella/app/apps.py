from __future__ import unicode_literals

from django.apps import AppConfig

from app.retrieve_meddata import KnowledgeGraphWrapper


class AppConfig(AppConfig):
    name = 'app'

    def ready(self):
        knw = KnowledgeGraphWrapper()
        knw.cache_drugs()
        # knw.cache_conditions()

