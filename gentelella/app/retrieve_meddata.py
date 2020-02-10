import json
import os
import time

from collections import namedtuple

from SPARQLWrapper import SPARQLWrapper2
from SPARQLWrapper import JSON

from django.conf import settings
from django.core.cache import cache


class NCObject(object):
    def __init__(self, name, code):
        self.name = name
        self.code = code

    def __eq__(self, other):
        return "{}{}".format(self.name, self.code).__eq__(
            "{}{}".format(other.name, other.code))

    def __lt__(self, other):
        return "{}{}".format(self.name, self.code).__lt__(
            "{}{}".format(other.name, other.code))


    def __gt__(self, other):
        return "{}{}".format(self.name, self.code).__gt__(
            "{}{}".format(other.name, other.code))


class KnowledgeGraphWrapper:

    def __init__(self):
        self.sparql = SPARQLWrapper2(settings.SPARQL_ENDPOINT)
        self.sparql.setCredentials(user=settings.SPARQL_USERNAME,
                                   passwd=settings.SPARQL_PASSWORD,
                                   realm=settings.SPARQL_REALM)
        self.sparql.setHTTPAuth(settings.SPARQL_AUTH)
        self.sparql.setReturnFormat(JSON)

    def cache_drugs(self):
        whole_query = """
        SELECT ?name, ?code WHERE {
        ?s <http://purl.bioontology.org/ontology/UATC/ATC_LEVEL> "5"^^<http://www.w3.org/2001/XMLSchema#string>.
        ?s skos:prefLabel ?name.
        ?s skos:notation ?code.
        }
        """

        # print(whole_query)
        self.sparql.setQuery(whole_query)
        # results = sorted(list(
        #     map(lambda r: tuple(
        #         map(lambda el: el.value, r.values())), self.sparql.query().bindings)))
        #
        # # Turn drugs into objects with name and code
        # DrugStruct = namedtuple("DrugStruct", "name, code")
        # results = [DrugStruct(name=r[0].lower(), code=r[1]) for r in results]

        drugs = self.sparql.query().bindings

        # DrugStruct = namedtuple("DrugStruct", "name, code")
        # drugs = sorted([DrugStruct(name=d["name"].value.lower(), code=d["code"].value) for d in drugs])
        drugs = sorted([NCObject(name=d["name"].value.lower(), code=d["code"].value
                                  ) for d in drugs])

        cache.set("drugs", drugs)

    def get_drugs(self):
        return cache.get("drugs")

    def cache_conditions(self):
        # Change with real service
        json_dir = os.path.dirname(os.path.realpath(__file__))
        with open(os.path.join(json_dir, "med_data", "medDRA.json"), "r") as fp:
            conditions = sorted(json.load(fp).items())

            # #
            # conditions = sorted([("Pain", "10033371"), ("Stinging", "10033371"),
            #                      ("Rhinitis", "10039083"), ("Allergic rhinitis", "10039085"),
            #                      ("Partial visual loss", "10047571"), ("Dry mouth", "10013781"),
            #                      ("Sprue-like enteropathy", "10079622"), ])

            conditions = [NCObject(name=n, code=c) for n, c in conditions]

            cache.set("conditions", conditions)

    def get_conditions(self):
        return cache.get("conditions")

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
