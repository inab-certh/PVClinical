from __future__ import unicode_literals

from django.apps import AppConfig
from django.conf import settings
from django.utils.translation import gettext_lazy as _

from app.retrieve_meddata import KnowledgeGraphWrapper
from app.ohdsi_wrappers import cohort_generated_recently
from app.ohdsi_wrappers import create_domain_conceptset
from app.ohdsi_wrappers import create_cohort
from app.ohdsi_wrappers import exists
from app.ohdsi_wrappers import generate_cohort
from app.ohdsi_wrappers import get_entity_by_name


class AppConfig(AppConfig):
    name = 'app'

    def ready(self):
        knw = KnowledgeGraphWrapper()
        knw.cache_drugs()
        # knw.cache_conditions()
    """
        domains = ["drug", "condition"]

        # Create concept sets and cohorts for all drugs and all conditions if not already created
        for domain in domains:
            # Check if concept set already exists else create it
            concept_set_name = "All {}s cs".format(domain)

            if not get_entity_by_name("conceptset", concept_set_name):
                create_domain_conceptset(domain)

            if get_entity_by_name("conceptset", concept_set_name):
                # Check if cohort already exists, else create and generate it
                cohort_name = "All {}s cohort".format(domain)
                if not get_entity_by_name("cohortdefinition", cohort_name):
                    create_cohort({domain.capitalize(): [concept_set_name]}, cohort_name)

                coh = get_entity_by_name("cohortdefinition", cohort_name) or {}
                recent_gen_exists = cohort_generated_recently(coh, recent=True,
                                                              days_before=settings.COHORT_RECENT_DAYS_LIMIT)
                coh_id = coh.get("id")
                if coh_id and not recent_gen_exists:
                    errors = {"condition": _("Η τροφοδότηση του πληθυσμού που εκδηλώνει τις επιλεγμένες ανεπιθύμητες ενέργειες δεν ήταν εφικτή"),
                              "drug": _("Η τροφοδότηση του πληθυσμού που λαμβάνουν τα επιλεγμένα φάρμακα δεν ήταν εφικτή")}
                    status = generate_cohort(coh_id)
                    if status == "FAILED":
                        error_response = HttpResponse(
                            content=errors.get(domain), status=500)
                        return error_response


    """