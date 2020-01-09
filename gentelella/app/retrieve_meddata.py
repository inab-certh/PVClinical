from collections import namedtuple

from SPARQLWrapper import SPARQLWrapper2
from SPARQLWrapper import JSON

from django.conf import settings


class KnowledgeGraphWrapper:
    def __init__(self):
        self.sparql = SPARQLWrapper2(settings.SPARQL_ENDPOINT)
        self.sparql.setCredentials(user=settings.SPARQL_USERNAME,
                                   passwd=settings.SPARQL_PASSWORD,
                                   realm=settings.SPARQL_REALM)
        self.sparql.setHTTPAuth(settings.SPARQL_AUTH)
        self.sparql.setReturnFormat(JSON)

    def get_drugs(self):
        whole_query = """
        SELECT ?name, ?code WHERE {
        ?s <http://purl.bioontology.org/ontology/UATC/ATC_LEVEL> "5"^^<http://www.w3.org/2001/XMLSchema#string>.
        ?s skos:prefLabel ?name.
        ?s skos:notation ?code.
        }
        """

        # print(whole_query)
        self.sparql.setQuery(whole_query)
        results = sorted(list(
            map(lambda r: tuple(
                map(lambda el: el.value, r.values())), self.sparql.query().bindings)))

        # Turn drugs into objects with name and code
        DrugStruct = namedtuple("DrugStruct", "name, code")
        results = [DrugStruct(name=r[0].lower(), code=r[1]) for r in results]

        return results

    def get_conditions(self):
        # Change with real service
        conditions = sorted([("Pain", "10033371"), ("Stinging", "10033371"),
                             ("Rhinitis", "10039083"), ("Allergic rhinitis", "10039085"),
                             ("Partial visual loss", "10047571"), ("Dry mouth", "10013781"),
                             ("Sprue-like enteropathy", "10079622"), ])

        # Turn conditions into objects with name and code
        ConditionStruct = namedtuple("ConditionStruct", "name, code")
        conditions = [ConditionStruct(name=c[0], code=c[1]) for c in conditions]

        return conditions

# def get_drugs():
#
#     # Change with real service
#     drugs = sorted([("Omeprazole", "A02BC01"), ("Esomeprazole", "A02BC05"),
#              ("Etybenzatropine", "N04AC30"), ("Benzatropine", "N04AC01"),
#              ("Phenytoin", "N03AB02"), ("Olmesartan", "C09CA08")])
#
#     # Turn drugs into objects with name and code
#     DrugStruct = namedtuple("DrugStruct", "name, code")
#     drugs = [DrugStruct(name=d[0], code=d[1]) for d in drugs]
#
#     return drugs
#
#
# def get_conditions():
#
#     # Change with real service
#     conditions = sorted([("Pain","10033371"), ("Stinging", "10033371"),
#                   ("Rhinitis", "10039083"), ("Allergic rhinitis", "10039085"),
#                   ("Partial visual loss", "10047571"), ("Dry mouth", "10013781"),
#                          ("Sprue-like enteropathy", "10079622"),])
#
#     # Turn conditions into objects with name and code
#     ConditionStruct = namedtuple("ConditionStruct", "name, code")
#     conditions = [ConditionStruct(name=c[0], code=c[1]) for c in conditions]
#
#     return conditions
