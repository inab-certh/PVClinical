import itertools
import json
import requests

from itertools import chain

from urllib.parse import urlencode
from django.conf import settings


def exists(name, ent_type):
    """ Checks whether a specific entity exists or not
    :param name: the entity's name (i.e. conceptset_name, cohort_name, ir_name etc.)
    :param ent_type: the entity's type (i.e. conceptset, cohortdefinition, ir etc.)
    :return: the status_code and True or False showing whether the enity exists or not
    """
    exists_url = "{}/{}/0/exists".format(settings.OHDSI_ENDPOINT, ent_type)
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    params = {"name": name}

    response = requests.get(exists_url, params=urlencode(params), headers=headers)

    resp_json = response.json()
    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return response.status_code, resp_json == 1


def search_concept(query, domain_lst):
    """ Search concept wrapper
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
    vocabularies = {"Drug": "ATC", "Condition": "MedDRA", "Gender": "Gender"}
    vocabulary_ids = [vocabularies.get(d) for d in domain_lst]
    response = requests.post(search_url, json={"QUERY": query,
                                               "DOMAIN_ID": domain_lst,
                                               "VOCABULARY_ID": vocabulary_ids},
                             headers=headers)

    resp_json = response.json()
    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return response.status_code, resp_json


# def concept_set_exists(cs_name):
#     """ Checks whether a specific concept set exists or not
#     :param cs_name: the name of  the concept set
#     :return: the status_code and True or False showing whether the concept_set exists or not
#     """
#     cs_exists_url = "{}/conceptset/0/exists".format(settings.OHDSI_ENDPOINT)
#     headers = {
#         "Content-Type": "application/json",
#         "Accept": "application/json",
#         # "api-key": "{}".format(settings.OHDSI_APIKEY),
#     }
#
#     params = {"name": cs_name}
#     response = requests.get(cs_exists_url, params=urlencode(params), headers=headers)
#
#     resp_json = response.json()
#     # resp_status = resp_json.get("status")
#     # resp_results = resp_json.get("results") or []
#     return response.status_code, resp_json == 1


def get_concept_set_id(cs_name):
    """ Get a specific concept set if it exists
    :param cs_name: the name of  the concept set
    :return: the concept set id if it exists or None
    """
    matching_set = None
    st, ex = concept_set_exists(cs_name)
    if ex:
        cs_url = "{}/conceptset/".format(settings.OHDSI_ENDPOINT)
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            # "api-key": "{}".format(settings.OHDSI_APIKEY),
        }

        params = {"name": cs_name}
        response = requests.get(cs_url, params=urlencode(params), headers=headers)
        match = list(filter(lambda el: el.get("name") == cs_name, response.json()))
        matching_set = match[0].get("id") if match else None

    return matching_set


# def cohort_exists(cohort_name):
#     """ Checks whether a specific cohort exists or not
#     :param cohort_name: the cohort_name
#     :return: the status_code and True or False showing whether the cohort exists or not
#     """
#     cohort_exists_url = "{}/cohortdefinition/0/exists".format(settings.OHDSI_ENDPOINT)
#     headers = {
#         "Content-Type": "application/json",
#         "Accept": "application/json",
#         # "api-key": "{}".format(settings.OHDSI_APIKEY),
#     }
#
#     params = {"name": cohort_name}
#
#     response = requests.get(cohort_exists_url, params=urlencode(params), headers=headers)
#
#     resp_json = response.json()
#     # resp_status = resp_json.get("status")
#     # resp_results = resp_json.get("results") or []
#     return response.status_code, resp_json == 1


def create_concept_set(cterms, cdomain):
    """ Create concept set wrapper
    :param cterms: the concept terms to search for and add relevant concepts
    :return: the status_code and the json data of the response (containing the following info:
    [createdBy, modifiedBy, createdDate, modifiedDate, id, name])
    """

    # The name of the concept set to be created
    cs_name = "_".join(cterms)

    status_code, exists_json = exists(cs_name, "conceptset")
    # print(status_code, exists_json)

    if status_code != 200:
        return status_code, {}

    if exists_json:
        return 500, {}

    search_statuses = []
    search_concepts = []

    # vocabularies = {"Drug": "ATC", "Condition": "MedDRA"}
    # For all search terms find relevant concepts (if any)
    for cterm in cterms:
        search_status, cterm_concepts = search_concept(cterm, [cdomain])
        search_statuses.append(search_status)
        # search_concepts += filter(lambda c: c.get("VOCABULARY_ID") == vocabularies.get(cdomain),
        #                           cterm_concepts)
        search_concepts += cterm_concepts

    # search_concepts = list(chain(search_concepts))
    # print(search_concepts)

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


def create_cohort(domains_csets_dict):
    """ Create cohort wrapper
    :param domains_csets_dict: a dictionary consisting of domain - concept_sets_names pairs
    :return: the status_code and the json data of the response
    """

    # cohort_def_url = "{}/cohortdefinition/".format(settings.OHDSI_ENDPOINT)
    # headers = {
    #     "Content-Type": "application/json",
    #     "Accept": "application/json",
    #     # "api-key": "{}".format(settings.OHDSI_APIKEY),
    # }
    #
    # # Create new concept set with specific name
    # create_resp = requests.post(cs_create_url, json={"name": cs_name, "id": 0}, headers=headers)
    # resp_json = create_resp.json()
    # if resp_json:

    # The name of the concept set to be created
    cohort_name = "_".join(
        domains_csets_dict.get("Drug", []) + domains_csets_dict.get("Condition", [])
    )

    status_code, exists_json = exists(cohort_name, "cohortdefinition")
    # print(status_code, exists_json)

    if status_code != 200:
        return status_code, {}

    if exists_json:
        return 500, {}

    all_concept_sets = []
    criteria_list = []
    indx = 0
    for domain, csets_names in domains_csets_dict.items():
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            # "api-key": "{}".format(settings.OHDSI_APIKEY),
        }

        for cs_name in csets_names:
            if domain == "Drug":
                criterion = {"DrugExposure":
                                 {"CodesetId": indx,
                                  "DrugTypeExclude": None,
                                  "DrugSourceConcept": None, "First": None
                                  }}
            elif domain == "Condition":
                criterion = {"ConditionOccurrence":
                                 {"CodesetId": indx,
                                  "ConditionTypeExclude": None,
                                  "ConditionSourceConcept": None, "First": None
                                  }}

            criteria_list.append(criterion)

            cs_id = get_concept_set_id(cs_name)
            if cs_id:
                cs_url = "{}/conceptset/{}/expression".format(settings.OHDSI_ENDPOINT, cs_id)
                response = requests.get(cs_url, headers=headers)

                if response.status_code == 200:
                    all_concept_sets.append({"id": indx,
                                             "name": cs_name,
                                             "expression": response.json()})

                    indx += 1
        # domain_concept_sets = list(map(lambda el: get_concept_set(el), csets_names))
        # all_concept_sets.append(domain_concept_sets)

    cohort_def_url = "{}/cohortdefinition/".format(settings.OHDSI_ENDPOINT)

    payload = {"name": cohort_name, "description": None,
               "expressionType": "SIMPLE_EXPRESSION",
               "expression": {"ConceptSets": all_concept_sets, "PrimaryCriteria":
                   {"CriteriaList": criteria_list,
                    "ObservationWindow": {"PriorDays": 0, "PostDays": 0},
                    "PrimaryCriteriaLimit": {"Type": "First"}
                    }, "QualifiedLimit": {"Type": "First"},
                              "ExpressionLimit": {"Type": "First"},
                              "InclusionRules": [], "CensoringCriteria": [],
                              "CollapseSettings": {"CollapseType": "ERA", "EraPad": 0},
                              "CensorWindow":{"StartDate": None, "EndDate": None},
                              "cdmVersionRange": None}}

    # payload = {"name":"Sprue-like Enteropathy condition IIIII","description":None,"expressionType":"SIMPLE_EXPRESSION","expression":{"ConceptSets":[{"id":0,"name":"Sprue-like enteropathy","expression":{"items":[{"concept":{"CONCEPT_CLASS_ID":"Clinical Finding","CONCEPT_CODE":"81704009","CONCEPT_ID":4218097,"CONCEPT_NAME":"Sprue","DOMAIN_ID":"Condition","INVALID_REASON":"V","INVALID_REASON_CAPTION":"Valid","STANDARD_CONCEPT":"S","STANDARD_CONCEPT_CAPTION":"Standard","VOCABULARY_ID":"SNOMED"},"isExcluded":False,"includeDescendants":True,"includeMapped":False},{"concept":{"CONCEPT_CLASS_ID":"Clinical Finding","CONCEPT_CODE":"359653006","CONCEPT_ID":4230257,"CONCEPT_NAME":"Unclassified sprue","DOMAIN_ID":"Condition","INVALID_REASON":"V","INVALID_REASON_CAPTION":"Valid","STANDARD_CONCEPT":"S","STANDARD_CONCEPT_CAPTION":"Standard","VOCABULARY_ID":"SNOMED"},"isExcluded":False,"includeDescendants":True,"includeMapped":False}]}}],"PrimaryCriteria":{"CriteriaList":[{"ConditionOccurrence":{"CodesetId":0,"ConditionTypeExclude":None,"ConditionSourceConcept":None,"First":None}}],"ObservationWindow":{"PriorDays":0,"PostDays":0},"PrimaryCriteriaLimit":{"Type":"First"}},"QualifiedLimit":{"Type":"First"},"ExpressionLimit":{"Type":"First"},"InclusionRules":[],"CensoringCriteria":[],"CollapseSettings":{"CollapseType":"ERA","EraPad":0},"CensorWindow":{"StartDate":None,"EndDate":None},"cdmVersionRange":None}}


    response = requests.post(cohort_def_url, data=json.dumps(payload), headers=headers)
    resp_json = response.json()
    # print(resp_json)

    return response.status_code, resp_json


def create_ir(target_cohorts, outcome_cohorts, **options):
    """ Create ir wrapper
    :param target_cohorts: a list of the target cohorts (id, name, etc.)
    :param outcome_cohorts: a list of the outcome cohorts (id, name, etc.)
    :return: the status_code and the json data of the response
    """

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }


    # The name of the ir to be created
    ir_name = "_".join(list(map(lambda c: c.get("name"), target_cohorts+outcome_cohorts)))

    status_code, exists_json = exists(ir_name, "ir")
    # print(status_code, exists_json)

    if status_code != 200:
        return status_code, {}

    if exists_json:
        return 500, {}

    ir_url = "{}/ir/".format(settings.OHDSI_ENDPOINT)

    age = options.get("age", 0)
    age_crit = options.get("age_crit", "")  # Age criterion (i.e. less than [lt] or greater than [gt])
    age_dict = {"Age": {"Value": age, "Extent":None, "Op": age_crit}} if age > 0 else {}

    genders_lst = options.get("genders")

    gender_concepts = list(itertools.chain(
        *[search_concept(gender, ["Gender"])[-1] for gender in genders_lst]))
    gender_concepts = [el for el in gender_concepts if el.get("CONCEPT_NAME").lower()
                       in [g.lower() for g in genders_lst]]
    # Keep unique concept dicts
    gender_concepts = list(map(dict, set(tuple(dic.items()) for dic in gender_concepts)))

    gender_list = [{"CONCEPT_CODE": gc.get("CONCEPT_CODE"), "CONCEPT_ID": gc.get("CONCEPT_ID"),
                    "CONCEPT_NAME": gc.get("CONCEPT_NAME"), "DOMAIN_ID": gc.get("DOMAIN_ID"),
                    "VOCABULARY_ID": gc.get("VOCABULARY_ID")} for gc in gender_concepts]
    gender_dict = {"Gender": gender_list} if gender_list else {}
    demographic_criteria = ([age_dict] if age_dict else []) + ([gender_dict] if gender_dict else [])

    enddays_offset = options.get("enddays_offset") or 90

    payload = {"id": None, "name":ir_name, "description": None,
               "expression":
                   {"ConceptSets":[],"targetIds": list(map(lambda tc: tc.get("id"), target_cohorts)),
                    "outcomeIds":list(map(lambda oc: oc.get("id"), outcome_cohorts)),
                    "timeAtRisk": {"start": {"DateField": "StartDate","Offset": 0},
                                  "end": {"DateField": "StartDate","Offset": enddays_offset}},
                    "strata": [{"name": "Stratification criteria", "description": None,
                   "expression": {"Type": "ALL", "CriteriaList":
                       [{"Criteria": {"DrugExposure":
                                          {"DrugTypeExclude": None, "DrugSourceConcept": None,
                                           "First": None}},"StartWindow":
                           {"Start": {"Days": None,
                                      "Coeff": -1},
                            "End":{"Days": None,
                                   "Coeff": 1},
                            "UseIndexEnd": False,
                            "UseEventEnd": False},
                         "RestrictVisit": False,
                         "IgnoreObservationPeriod": False,
                         "Occurrence": {"IsDistinct": False,
                                        "Type":2, "Count": 1}
                         }
                        ],
                                  "DemographicCriteriaList": demographic_criteria,
                                  "Groups": []}}]}}
               #  "{{\"ConceptSets\":[],\"targetIds\":{},\"outcomeIds\":{},"
               #     "\"timeAtRisk\":{{\"start\":{{\"DateField\":\"StartDate\",\"Offset\":0}},"
               #     "\"end\":{{\"DateField\":\"StartDate\",\"Offset\":{}}}}},"
               #     "\"strata\":[{{\"name\":\"Stratification criteria\",\"description\":null,"
               #     "\"expression\":{{\"Type\":\"ALL\",\"CriteriaList\":"
               #     "[{{\"Criteria\":{{\"DrugExposure\":{{\"DrugTypeExclude\":null,"
               #     "\"DrugSourceConcept\":null,\"First\":null}}}},\"StartWindow\":"
               #     "{{\"Start\":{{\"Days\":null,\"Coeff\":-1}},\"End\":{{\"Days\":null,\"Coeff\":1}},"
               #     "\"UseIndexEnd\":false,\"UseEventEnd\":false}},\"RestrictVisit\":false,"
               #     "\"IgnoreObservationPeriod\":false,\"Occurrence\":{{\"IsDistinct\":false,"
               #     "\"Type\":2,\"Count\":1}}}}],\"DemographicCriteriaList\":"
               #     "{}}}],\"Groups\":[]}}]}}".format(list(map(lambda tc: tc.get("id"), target_cohorts)),
               #                                        list(map(lambda oc: oc.get("id"), outcome_cohorts)),
               #                                        enddays_offset, json.dumps(demographic_criteria))}

    print(json.dumps(payload))
    print(ir_url)
    response = requests.post(ir_url, data=json.dumps(payload), headers=headers)
    print(response)
    resp_json = response.json()
    # print(resp_json)

    return response.status_code, resp_json
