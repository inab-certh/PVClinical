import os
import json

from itertools import chain
from itertools import product

from json import JSONEncoder

from SPARQLWrapper import SPARQLWrapper2
from SPARQLWrapper import JSON

from django.conf import settings
from django.core.cache import cache

# from app.helper_modules import medDRA_hierarchy_tree
from app.helper_modules import medDRA_flat_tree


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

    def __hash__(self):
        return hash(("name", self.name, "code", self.code))

    def __eq__(self, other):
        return "{}-{}".format(
            self.name, self.code).__eq__(
            "{}-{}".format(
                other.name, other.code))

    # def __lt__(self, other):
    #     return "{}-{}-{}-{}-{}-{}-{}".format(
    #         self.name, self.code, self.type, self.soc, self.hlgt, self.hlt, self.pt).__lt__(
    #         "{}-{}-{}-{}-{}-{}-{}".format(
    #             other.name, other.code, other.type, other.soc, other.hlgt, other.hlt, other.pt))
    #
    # def __gt__(self, other):
    #     return "{}-{}-{}-{}-{}-{}-{}".format(
    #         self.name, self.code, self.type, self.soc, self.hlgt, self.hlt, self.pt).__gt__(
    #         "{}-{}-{}-{}-{}-{}-{}".format(
    #             other.name, other.code, other.type, other.soc, other.hlgt, other.hlt, other.pt))


# class ConditionObject(NCObject):
#     def __init__(self, name, code, parent, grandparent, type):
#
#         super().__init__(name, code)
#         self.type = type
#
#         self.id = "{}___{}".format(code, parent)
#         self.parent = "{}___{}".format(parent, grandparent) if parent else ""
#
#     def __hash__(self):
#         return hash(("id", self.id, "parent", self.parent))
#
#     def __eq__(self, other):
#         return "{}{}".format(self.id, self.parent).__eq__(
#             "{}{}".format(other.id, other.parent))
#
#
# # subclass JSONEncoder
# class ConditionEncoder(JSONEncoder):
#         def default(self, o):
#             return o.__dict__
#
#
# class ConditionDecoder(json.JSONDecoder):
#     def __init__(self, *args, **kwargs):
#         json.JSONDecoder.__init__(self, object_hook=self.object_hook, *args, **kwargs)
#
#     def object_hook(self, obj):
#         return ConditionObject(obj.get("name"), obj.get("code"),
#                                obj.get("id").split("___").pop(),
#                                obj.get("parent").split("___").pop(),
#                                obj.get("type"))


# subclass JSONEncoder
class ConditionEncoder(JSONEncoder):
        def default(self, o):
            return o.__dict__


class ConditionDecoder(json.JSONDecoder):
    def __init__(self, *args, **kwargs):
        json.JSONDecoder.__init__(self, object_hook=self.object_hook, *args, **kwargs)

    def object_hook(self, obj):
        return ConditionObject(obj.get("name"), obj.get("code"),
                               obj.get("id").split("___").pop(0),
                               obj.get("parent").split("___").pop(),
                               obj.get("type"))


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
        } order by desc(?soc) desc(?hlgt) desc(?hlt) desc(?pt)
        """
        self.sparql.setQuery(whole_query)

        sparql_conditions = self.sparql.query().bindings

        conditions = sorted([ConditionObject(name=get_binding_value(c, "condition_name"),
                                             code=get_binding_value(c, "condition_code"),
                                             soc=get_binding_value(c, "soc"),
                                             hlgt=get_binding_value(c, "hlgt"),
                                             hlt=get_binding_value(c, "hlt"),
                                             pt=get_binding_value(c, "pt"),
                                             type=get_binding_value(c, "condition_type"),
                                             ) for c in sparql_conditions])

        # with open(os.path.join(settings.JSONS_DIR, "medDRA_tree.json"), "w", encoding="utf8") as fp:
        #     json.dump(medDRA_hierarchy_tree(conditions), fp)


        # print(len(sparql_conditions))
        #
        # conditions = []
        #

        # for c in sparql_conditions:
        #     cond_type = type_2_abbrv(get_binding_value(c, "condition_type"))
        #     possible_parents = self.get_parents(get_binding_value(c, "condition_code"), cond_type)
        #     possible_grandparents = [self.get_parents(parent, type_2_ptype(cond_type)) for parent in possible_parents]
        #     ancestor_pairs = list(chain(*[product(*el) for el in zip([[p] for p in possible_parents],
        #                                                              possible_grandparents)]))
        #     conditions.extend([ConditionObject(name=get_binding_value(c, "condition_name"),
        #                                       code=get_binding_value(c, "condition_code"),
        #                                       parent=parent,
        #                                       grandparent=grandparent,
        #                                       type=cond_type,
        #                                       ) for parent, grandparent in ancestor_pairs])

        # with open(os.path.join(settings.JSONS_DIR, "conditions.json"), "w") as fp:
        #     json.dump(conditions, fp, cls=ConditionEncoder)

        # with open(os.path.join(settings.JSONS_DIR, "conditions.json"), "r") as fp:
        #     conditions = json.load(fp, cls=ConditionDecoder)
        #
        # conditions = list(set(conditions))
        #
        # print(len(conditions))
        #
        #
        #
        # # Just the nodes for the JStree
        # medDRA_tree = medDRA_flat_tree(conditions)

        # Cache medDRA hierarchy tree too
        with open(os.path.join(settings.JSONS_DIR, "medDRA_tree.json")) as fp:
            medDRA_tree = json.load(fp)

        # Keep only specific level concepts
        # condition_types = ["pt",
        #                    "llt"]
        condition_types = ["https://w3id.org/phuse/meddra#PreferredConcept",
                           "https://w3id.org/phuse/meddra#LowLevelConcept"]

        # Allow only llt and pt conditions for select2 conditions_fld
        conditions = list(set(filter(lambda c: c.type in condition_types, conditions)))

        cache.set("conditions", conditions, timeout=None)
        cache.set("medDRA_tree", medDRA_tree, timeout=None)

    def get_conditions(self):
        """ Retrieve conditions from cache
        """
        return cache.get("conditions")

    def get_medDRA_tree(self):
        """ Retrieve medDRA_tree from cache
        """
        return cache.get("medDRA_tree")

    def get_parents(self, node_code, node_type):
        """ Find the specific node's possible parents
        :param node_code: child node to find the parent of
        :param node_type: the type of the child node
        :return: the possible parents for this node
        """

        if not node_code:
            return [""]

        abbrv_2_type = {"soc": "https://w3id.org/phuse/meddra#SystemOrganClassConcept",
                        "hlgt": "https://w3id.org/phuse/meddra#HighLevelGroupConcept",
                        "hlt": "https://w3id.org/phuse/meddra#HighLevelConcept",
                        "pt": "https://w3id.org/phuse/meddra#PreferredConcept",
                        "llt": "https://w3id.org/phuse/meddra#LowLevelConcept"}

        parent_type = type_2_ptype(node_type)

        parents = [""]

        if parent_type:
            whole_query = """
                    prefix meddra: <https://w3id.org/phuse/meddra#> 
                    select ?condition_name, ?parent 
                    from <http://english211.meddra.org> where {{
                        ?condition a <{0}>;
                            skos:prefLabel ?condition_name;
                            meddra:hasIdentifier "{1}"^^<http://www.w3.org/2001/XMLSchema#string>.
                        FILTER(STRSTARTS("{0}", STR(meddra:))
                        && ! STRSTARTS("{0}", STR(meddra:MeddraConcept))).
                        OPTIONAL {{?condition meddra:has{2} ?parent}}. 
                    }} 
                    """.format(abbrv_2_type.get(node_type), node_code, parent_type.upper())
            # print(whole_query)
            self.sparql.setQuery(whole_query)
            results = self.sparql.query().bindings
            parents = list(set(map(lambda res: get_binding_value(res, "parent").strip(
                "https://w3id.org/phuse/meddra#m"), results))) if results else [""]

        return parents


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
        return ""

    ret_val = results_dict[attr].value

    if sep:
        ret_val = ret_val.split(sep).pop()
    if strip_chars:
        ret_val = ret_val.strip(strip_chars)

    return (ret_val or "")


def type_2_ptype(node_type):
    """ Return the parent type of a node given its type
    :param node_type: the type of the node (abrv)
    :return: node's parent type
    """
    # Type to parent type (for tree)
    type_2_ptype = {"soc": None,
                    "hlgt": "soc",
                    "hlt": "hlgt",
                    "pt": "hlt",
                    "llt": "pt"}

    return type_2_ptype.get(node_type)


def type_2_abbrv(node_type):
    """ Get the abbrv of a type
    :param node_type: the type of the node
    :return: the abbrv of a type
    """

    # Type to its abbreviation
    type_2_abbrv = {"https://w3id.org/phuse/meddra#SystemOrganClassConcept": "soc",
                    "https://w3id.org/phuse/meddra#HighLevelGroupConcept": "hlgt",
                    "https://w3id.org/phuse/meddra#HighLevelConcept": "hlt",
                    "https://w3id.org/phuse/meddra#PreferredConcept": "pt",
                    "https://w3id.org/phuse/meddra#LowLevelConcept": "llt"}

    return type_2_abbrv.get(node_type)
