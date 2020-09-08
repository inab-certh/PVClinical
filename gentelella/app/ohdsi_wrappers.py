import json
import requests

from itertools import chain

from urllib.parse import urlencode
from django.conf import settings


def search_concept_set(query, domain_lst):
    """ Search concept_set wrapper
    :param query: the query term or terms etc
    :param domain_lst: the domain or list of domains  the query term might belong to
    :return: the status_code and the json data of the response
    """
    search_url = "{}/vocabulary/OHDSI-CDMV5-synpuf/search".format(settings.OHDSI_ENDPOINT)
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    response = requests.post(search_url, json={"QUERY": query, "DOMAIN_ID": domain_lst}, headers=headers)

    resp_json = response.json()
    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return response.status_code, resp_json


def concept_set_exists(cs_name):
    """ Checks whether a specific concept set exists or not
    :param cs_name: the name of  the concept set
    :return: the status_code and True or False showing whether the concept_set exists or not
    """
    cs_exists_url = "{}/conceptset/0/exists".format(settings.OHDSI_ENDPOINT)
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    params = {"name": cs_name}
    response = requests.get(cs_exists_url, params=urlencode(params), headers=headers)

    resp_json = response.json()
    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return response.status_code, resp_json == 1


def cohort_exists(cohort_name):
    """ Checks whether a specific cohort exists or not
    :param cohort_name: the cohort_name
    :return: the status_code and True or False showing whether the cohort exists or not
    """
    cohort_exists_url = "{}/cohortdefinition/0/exists".format(settings.OHDSI_ENDPOINT)
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    params = {"name": cohort_name}

    response = requests.get(cohort_exists_url, params=urlencode(params), headers=headers)

    resp_json = response.json()
    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return response.status_code, resp_json == 1


def create_concept_set(cterms, cdomain):
    """ Create concept set wrapper
    :param cterms: the concept terms to search for and add relevant concepts
    :return: the status_code and the json data of the response (containing the following info:
    [createdBy, modifiedBy, createdDate, modifiedDate, id, name])
    """

    # The name of the concept set to be created
    cs_name = "_".join(cterms)

    status_code, exists_json = concept_set_exists(cs_name)
    print(status_code, exists_json)

    if status_code != 200:
        return status_code, {}

    if exists_json:
        return 500, {}

    search_statuses = []
    search_concepts = []

    # For all search terms find relevant concepts (if any)
    for cterm in cterms:
        search_status, cterm_concepts = search_concept_set(cterm, [cdomain])
        search_statuses.append(search_status)
        search_concepts += cterm_concepts

    # search_concepts = list(chain(search_concepts))
    print(search_concepts)

    if 200 not in search_statuses:
        return search_status, {}

    cs_create_url = "{}/conceptset/".format(settings.OHDSI_ENDPOINT)
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    # Create new concept set with specific name
    create_resp = requests.post(cs_create_url, json={"name": cs_name, "id": 0}, headers=headers)
    resp_json = create_resp.json()

    if create_resp.status_code != 200:
        return create_resp.status_code, {}

    # Adding concepts to newly created concept set
    add_items_url = "{}/conceptset/{}/items".format(settings.OHDSI_ENDPOINT, resp_json.get("id"))

    # Including both descendants and mapped(synonym) terms
    payload = [{"conceptId": sc.get("CONCEPT_ID"), "isExcluded": 0, "includeDescendants": 0, "includeMapped": 0
                } for sc in search_concepts]
    add_items_resp = requests.put(add_items_url, data=json.dumps(payload), headers=headers)
    resp_json = add_items_resp.json()

    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return add_items_resp.status_code, resp_json


# def create_cohort(csets_domains_dict):
#     """ Create cohort set wrapper
#     :param csets_domains_dict: a dictionary consisting of concept set - domain pairs
#     :return: the status_code and the json data of the response (containing the following info:
#     [createdBy, modifiedBy, createdDate, modifiedDate, id, name])
#     """
#
#     """
#     {"name":"Sprue-like Enteropathy condition II","description":null,"expressionType":"SIMPLE_EXPRESSION","expression":{"ConceptSets":[{"id":0,"name":"Sprue-like enteropathy","expression":{"items":[{"concept":{"CONCEPT_CLASS_ID":"Clinical Finding","CONCEPT_CODE":"81704009","CONCEPT_ID":4218097,"CONCEPT_NAME":"Sprue","DOMAIN_ID":"Condition","INVALID_REASON":"V","INVALID_REASON_CAPTION":"Valid","STANDARD_CONCEPT":"S","STANDARD_CONCEPT_CAPTION":"Standard","VOCABULARY_ID":"SNOMED"},"isExcluded":false,"includeDescendants":true,"includeMapped":false},{"concept":{"CONCEPT_CLASS_ID":"Clinical Finding","CONCEPT_CODE":"359653006","CONCEPT_ID":4230257,"CONCEPT_NAME":"Unclassified sprue","DOMAIN_ID":"Condition","INVALID_REASON":"V","INVALID_REASON_CAPTION":"Valid","STANDARD_CONCEPT":"S","STANDARD_CONCEPT_CAPTION":"Standard","VOCABULARY_ID":"SNOMED"},"isExcluded":false,"includeDescendants":true,"includeMapped":false}]}}],"PrimaryCriteria":{"CriteriaList":[{"ConditionOccurrence":{"CodesetId":0,"ConditionTypeExclude":null,"ConditionSourceConcept":null,"First":null}}],"ObservationWindow":{"PriorDays":0,"PostDays":0},"PrimaryCriteriaLimit":{"Type":"First"}},"QualifiedLimit":{"Type":"First"},"ExpressionLimit":{"Type":"First"},"InclusionRules":[],"CensoringCriteria":[],"CollapseSettings":{"CollapseType":"ERA","EraPad":0},"CensorWindow":{"StartDate":null,"EndDate":null},"cdmVersionRange":null}}
#     """
#
#     # The name of the concept set to be created
#     cs_name = "_".join(cterms)
#
#     status_code, exists_json = concept_set_exists(cs_name)
#     print(status_code, exists_json)
#
#     if status_code != 200:
#         return status_code, {}
#
#     if exists_json:
#         return 500, {}
#
#     search_statuses = []
#     search_concepts = []
#
#     # For all search terms find relevant concepts (if any)
#     for cterm in cterms:
#         search_status, cterm_concepts = search_concept_set(cterm, [cdomain])
#         search_statuses.append(search_status)
#         search_concepts += cterm_concepts
#
#     # search_concepts = list(chain(search_concepts))
#     print(search_concepts)
#
#     if 200 not in search_statuses:
#         return search_status, {}
#
#     cs_create_url = "{}/conceptset/".format(settings.OHDSI_ENDPOINT)
#     headers = {
#         "Content-Type": "application/json",
#         "Accept": "application/json",
#         # "api-key": "{}".format(settings.OHDSI_APIKEY),
#     }
#
#     # Create new concept set with specific name
#     create_resp = requests.post(cs_create_url, json={"name": cs_name, "id": 0}, headers=headers)
#     resp_json = create_resp.json()
#
#     if create_resp.status_code != 200:
#         return create_resp.status_code, {}
#
#     # Adding concepts to newly created concept set
#     add_items_url = "{}/conceptset/{}/items".format(settings.OHDSI_ENDPOINT, resp_json.get("id"))
#
#     # Including both descendants and mapped(synonym) terms
#     payload = [{"conceptId": sc.get("CONCEPT_ID"), "isExcluded": 0, "includeDescendants": 0, "includeMapped": 0
#                 } for sc in search_concepts]
#     add_items_resp = requests.put(add_items_url, data=json.dumps(payload), headers=headers)
#     resp_json = add_items_resp.json()
#
#     # resp_status = resp_json.get("status")
#     # resp_results = resp_json.get("results") or []
#     return add_items_resp.status_code, resp_json