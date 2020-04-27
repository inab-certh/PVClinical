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

    def __hash__(self):
        return hash(("name", self.name, "code", self.code, "type", self.type))

    def __eq__(self, other):
        return "{}-{}-{}".format(self.name, self.code, self.type).__eq__(
            "{}-{}-{}".format(other.name, other.code, other.type))


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
        }
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

        # Make sure conditions are unique
        conditions = list(set(conditions))

        # Keep only specific level concepts
        condition_types = ["https://w3id.org/phuse/meddra#PreferredConcept",
                           "https://w3id.org/phuse/meddra#LowLevelConcept"]

        # Just the nodes for the JStree
        medDRA_tree = medDRA_flat_tree(conditions)

        # Allow only llt and pt conditions for select2 conditions_fld
        conditions = list(filter(lambda c: c.type in condition_types, conditions))
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
