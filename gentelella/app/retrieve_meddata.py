import json
import os
import time

from collections import namedtuple

from SPARQLWrapper import SPARQLWrapper2
from SPARQLWrapper import JSON

from django.conf import settings
from django.core.cache import cache

from app.helper_modules import medDRA_hierarchy_tree


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


class ConditionObject(NCObject):
    def __init__(self, name, code, type, soc=None, hlgt=None, hlt=None, pt=None):
        super().__init__(name, code)
        self.type = type
        self.soc = soc
        self.hlgt = hlgt
        self.hlt = hlt
        self.pt = pt

        # self.soc = None
        # self.hlgt = None
        # self.hlt = None
        # self.pt = None

        # # Select main ancestor to set by type of condition
        # type_to_main_ancestor = {"https://w3id.org/phuse/meddra#HighLevelGroupConcept": "soc",
        #                          "https://w3id.org/phuse/meddra#HighLevelConcept": "hlgt",
        #                          "https://w3id.org/phuse/meddra#PreferredConcept": "hlt",
        #                          "https://w3id.org/phuse/meddra#LowLevelConcept": "pt",
        #                          "https://w3id.org/phuse/meddra#SystemOrganClassConcept": ""}
        #
        # # Set only main ancestor (one level up) for condition
        # setattr(self, type_to_main_ancestor[self.type],
        #         eval(type_to_main_ancestor[self.type]) if type_to_main_ancestor[self.type] else None)

    def __eq__(self, other):
        return "{}-{}-{}-{}-{}-{}-{}".format(
            self.name, self.code, self.type, self.soc, self.hlgt, self.hlt, self.pt).__eq__(
            "{}-{}-{}-{}-{}-{}-{}".format(
                other.name, other.code, other.type, other.soc, other.hlgt, other.hlt, other.pt))

    def __lt__(self, other):
        return "{}-{}-{}-{}-{}-{}-{}".format(
            self.name, self.code, self.type, self.soc, self.hlgt, self.hlt, self.pt).__lt__(
            "{}-{}-{}-{}-{}-{}-{}".format(
                other.name, other.code, other.type, other.soc, other.hlgt, other.hlt, other.pt))

    def __gt__(self, other):
        return "{}-{}-{}-{}-{}-{}-{}".format(
            self.name, self.code, self.type, self.soc, self.hlgt, self.hlt, self.pt).__gt__(
            "{}-{}-{}-{}-{}-{}-{}".format(
                other.name, other.code, other.type, other.soc, other.hlgt, other.hlt, other.pt))


class KnowledgeGraphWrapper:

    def __init__(self):
        self.sparql = SPARQLWrapper2(settings.SPARQL_ENDPOINT)
        self.sparql.setCredentials(user=settings.SPARQL_USERNAME,
                                   passwd=settings.SPARQL_PASSWORD,
                                   realm=settings.SPARQL_REALM)
        self.sparql.setHTTPAuth(settings.SPARQL_AUTH)
        self.sparql.setReturnFormat(JSON)

    def get_synonyms(self, drugs):
        """ Retrieves synonyms for selected drugs
        :param drugs: the selected drugs
        :return: the synonyms
        """

        synonyms = []
        if drugs:
            drugs = list(map(lambda d: d.lower(), drugs))

            drugs_union = "UNION".join(["{{?drugbank_drug <http://purl.org/dc/terms/title> ?drugbank_drug_name.\n"
                                        "?drugbank_drug_name bif:contains \"{}\"}}".format(d) for d in drugs])

            # print(str(tuple(drugs)))
            # drugs = "(\"{}\"@en)".format("\"@en, \"".join(drugs))
            whole_query = """
                    select ?synonym_name, ?drug_code
                    from <http://purl.bioontology.org/ontology/UATC/>
                    from <https://bio2rdf.org/drugbank>
                    where {{
                    {}.
                    ?drug skos:prefLabel ?drug_name.
                    FILTER(lcase(?drugbank_drug_name)=lcase(?drug_name))
                    ?drug <http://purl.bioontology.org/ontology/UATC/ATC_LEVEL> "5"^^<http://www.w3.org/2001/XMLSchema#string>.
                    ?drug skos:notation ?code.
                    bind(str(?code) as ?drug_code)
                    ?drugbank_drug <http://bio2rdf.org/drugbank_vocabulary:synonym> ?synonym.
                    ?synonym <http://purl.org/dc/terms/title> ?synonym_name.
                    FILTER(?synonym_name!=?drugbank_drug_name)
                    }}
                    """.format(drugs_union)

            self.sparql.setQuery(whole_query)
            synonyms = self.sparql.query().bindings

            # Get synonyms filtering out the ones that already exist in drugs field
            synonyms = sorted(["{} - {}".format(
                get_binding_value(synonym, "synonym_name"),
                get_binding_value(synonym, "drug_code", sep=":")
            ) for synonym in synonyms if synonym["synonym_name"].value.lower() not in drugs])
        return synonyms

    def cache_drugs(self):
        """ Caches the drugs for faster retrieval
        """

        whole_query = """
        select ?drug_name, ?drug_code from <http://purl.bioontology.org/ontology/UATC/> where {
            {
                ?drug <http://purl.bioontology.org/ontology/UATC/ATC_LEVEL> "5"^^<http://www.w3.org/2001/XMLSchema#string>.
                ?drug skos:prefLabel ?drug_name.
                ?drug skos:notation ?code.
                bind(str(?code) as ?drug_code)
            }
        }
        """
        #
        self.sparql.setQuery(whole_query)
        drugs = self.sparql.query().bindings
        # drugs = sorted([NCObject(name=d["name"].value.lower(), code=d["code"].value
        #                           ) for d in drugs])
        drugs = sorted([NCObject(name=get_binding_value(d, "drug_name").capitalize(),
                                 code=get_binding_value(d, "drug_code", sep=":")
                                 ) for d in drugs])

        cache.set("drugs", drugs, timeout=None)

    def get_drugs(self):
        """ Retrieve drugs from cache
        """
        return cache.get("drugs")

    def cache_conditions(self):
        """ Caches the conditions for faster retrieval
        """
        # Change with real service

        whole_query = """
        prefix meddra: <https://w3id.org/phuse/meddra#> 
        select ?condition_name, ?soc, ?hlgt, ?hlt, ?pt, ?condition_type, ?condition_code 
        from <http://english211.meddra.org> where {
            ?condition a ?condition_type;
                skos:prefLabel ?condition_name;
                meddra:hasIdentifier ?condition_code.
            FILTER(STRSTARTS(STR(?condition_type), STR(meddra:))
            && ! STRSTARTS(STR(?condition_type), STR(meddra:MeddraConcept))).
            OPTIONAL {?condition meddra:hasPT ?pt}.
            OPTIONAL {?condition meddra:hasHLT ?hlt}.
            OPTIONAL {?condition meddra:hasHLGT ?hlgt}.
            OPTIONAL {?condition meddra:hasSOC ?soc}
        } LIMIT 10000
        """
        self.sparql.setQuery(whole_query)
        # self.sparql.addDefaultGraph(settings.SPARQL_MEDDRA_URI)
        conditions = self.sparql.query().bindings

        conditions = sorted([ConditionObject(name=get_binding_value(c, "condition_name"),
                                             code=get_binding_value(c, "condition_code"),
                                             soc=get_binding_value(c, "soc"),
                                             hlgt=get_binding_value(c, "hlgt"),
                                             hlt=get_binding_value(c, "hlt"),
                                             pt=get_binding_value(c, "pt"),
                                             type=get_binding_value(c, "condition_type"),
                                             ) for c in conditions])

        print(len(conditions))
        print(len(list(set(conditions))))
        # with open(os.path.join(settings.JSONS_DIR, "medDRA_tree.json"), "w", encoding="utf8") as fp:
        #     json.dump(medDRA_hierarchy_tree(conditions), fp)

        cache.set("conditions", conditions, timeout=None)

        # Cache medDRA hierarchy tree too
        with open(os.path.join(settings.JSONS_DIR, "medDRA_tree.json")) as fp:
            medDRA_tree = json.load(fp)

        cache.set("medDRA_tree", medDRA_tree, timeout=None)

        # with open(os.path.join(json_dir, "med_data", "medDRA.json"), "r") as fp:
        #     conditions = sorted(json.load(fp).items())

        # conditions = [NCObject(name=n, code=c) for n, c in conditions]
        #
        # cache.set("conditions", conditions)

    def get_conditions(self):
        """ Retrieve conditions from cache
        """
        return cache.get("conditions")

    def get_medDRA_tree(self):
        """ Retrieve medDRA_tree from cache
        """
        return cache.get("medDRA_tree")


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

def get_binding_value(results_dict, attr, sep=None, strip_chars=None):
    """ Helper function to get value from sparql bindings
    :results_dict: the dictionary returned as results from sparql query
    :attr: the attribute to retrieve value for
    :sep: the separator by which we should split the contained value
    :strip_chars: in case we want to strip characters from the value retrieved
    :return: the value to assign it to an attribute
    """

    # Key does not exist in sparql dictionary keys or is in nullify_attrs list
    if attr not in results_dict.keys():
        return None

    ret_val = results_dict[attr].value

    if sep:
        ret_val = ret_val.split(sep).pop()
    if strip_chars:
        ret_val = ret_val.strip(strip_chars)

    return ret_val

# def keep_one_level_parent(condition):
#     """ Keep only one level parent for the condition
#     :param condition: the condition
#     :return: the condition
#     """
#
#     parent_by_level = ["pt", "hlt", "hlgt", "soc"]
#     for el in parent_by_level:
#         if getattr(condition, parent_by_level.pop(0)):
#             for lvl in parent_by_level:
#                 setattr(condition, lvl, None)

# def ancestors_to_nullify(condition):
#     """ Return attributes (ancestors) of condition to nullify (None).
#     That way we keep only the main ancestor of the current condition
#     :param condition: the current condition
#     :return: second level and upper ancestors to nullify
#     """
#
#     by_type_nullify_ancestors = {"https://w3id.org/phuse/meddra#HighLevelGroupConcept": [],
#                                 "https://w3id.org/phuse/meddra#HighLevelConcept": ["soc"],
#                                 "https://w3id.org/phuse/meddra#PreferredConcept": ["hlgt", "soc"],
#                                 "https://w3id.org/phuse/meddra#LowLevelConcept": ["soc", "hlgt", "hlt"],
#                                 "https://w3id.org/phuse/meddra#SystemOrganClassConcept": []}
#
#     return by_type_nullify_ancestors[condition.type]
