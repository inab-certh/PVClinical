import hashlib
import itertools
import json
import requests

# from datetime import datetime
# from datetime import timedelta
from urllib.parse import urlencode
from django.conf import settings


def url_exists(exists_url):
    """ Checks whether a specific url exists or not
    :param exists_url: the url to be checked whether it exists or not
    :return: the status_code and True or False showing whether the url exists or not
    """

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }
    response = requests.get(exists_url, headers=headers)

    resp_json = response.json()
    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return response.status_code, resp_json == 1


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
    st, ex = exists(cs_name, "conceptset")
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


def get_entity_by_name(entity_type, entity_name):
    """ Get a specific entity (i.e. cohortdefinition, iranalysis etc.) if it exists
    :param entity_name: the name of  the entity
    :return: the entity if it exists or None
    """
    matching_entity = None
    st, ex = exists(entity_name, entity_type)
    if ex:
        entity_url = "{}/{}/".format(settings.OHDSI_ENDPOINT, entity_type)
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            # "api-key": "{}".format(settings.OHDSI_APIKEY),
        }

        response = requests.get(entity_url, headers=headers)
        match = list(filter(lambda el: el.get("name") == entity_name, response.json()))
        matching_id = match[0].get("id") if match else None
        matching_entity = requests.get("{}{}".format(entity_url, matching_id),
                                       headers=headers).json() if matching_id else None

    return matching_entity


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
    :param cterms: the domain of the cterms/concepts
    :return: the status_code and the json data of the response (containing the following info:
    [createdBy, modifiedBy, createdDate, modifiedDate, id, name])
    """

    # The name of the concept set to be created
    cs_name = name_entities_group(cterms)

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
    payload = [{"conceptId": sc.get("CONCEPT_ID"), "isExcluded": 0, "includeDescendants": 1, "includeMapped": 0
                } for sc in search_concepts]
    add_items_resp = requests.put(add_items_url, data=json.dumps(payload), headers=headers)
    resp_json = add_items_resp.json()

    # resp_status = resp_json.get("status")
    # resp_results = resp_json.get("results") or []
    return add_items_resp.status_code, resp_json


def create_cohort(domains_csets_dict):
    """ Create cohort wrapper. Allows drugs_cohorts, conditions_cohort and even combination cohorts creation
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

    # The name of the cohort to be created
    cohort_name = name_entities_group(
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
                              "CensorWindow": {"StartDate": None, "EndDate": None},
                              "cdmVersionRange": None}}

    # payload = {"name":"Sprue-like Enteropathy condition IIIII","description":None,"expressionType":"SIMPLE_EXPRESSION","expression":{"ConceptSets":[{"id":0,"name":"Sprue-like enteropathy","expression":{"items":[{"concept":{"CONCEPT_CLASS_ID":"Clinical Finding","CONCEPT_CODE":"81704009","CONCEPT_ID":4218097,"CONCEPT_NAME":"Sprue","DOMAIN_ID":"Condition","INVALID_REASON":"V","INVALID_REASON_CAPTION":"Valid","STANDARD_CONCEPT":"S","STANDARD_CONCEPT_CAPTION":"Standard","VOCABULARY_ID":"SNOMED"},"isExcluded":False,"includeDescendants":True,"includeMapped":False},{"concept":{"CONCEPT_CLASS_ID":"Clinical Finding","CONCEPT_CODE":"359653006","CONCEPT_ID":4230257,"CONCEPT_NAME":"Unclassified sprue","DOMAIN_ID":"Condition","INVALID_REASON":"V","INVALID_REASON_CAPTION":"Valid","STANDARD_CONCEPT":"S","STANDARD_CONCEPT_CAPTION":"Standard","VOCABULARY_ID":"SNOMED"},"isExcluded":False,"includeDescendants":True,"includeMapped":False}]}}],"PrimaryCriteria":{"CriteriaList":[{"ConditionOccurrence":{"CodesetId":0,"ConditionTypeExclude":None,"ConditionSourceConcept":None,"First":None}}],"ObservationWindow":{"PriorDays":0,"PostDays":0},"PrimaryCriteriaLimit":{"Type":"First"}},"QualifiedLimit":{"Type":"First"},"ExpressionLimit":{"Type":"First"},"InclusionRules":[],"CensoringCriteria":[],"CollapseSettings":{"CollapseType":"ERA","EraPad":0},"CensorWindow":{"StartDate":None,"EndDate":None},"cdmVersionRange":None}}

    response = requests.post(cohort_def_url, data=json.dumps(payload), headers=headers)
    resp_json = response.json()
    # print(resp_json)

    return response.status_code, resp_json


# def generate_cohort(cohort_id):
#     """ Generate a specific cohort
#     :param cohort_id: the cohort's id
#     :return: the status_code and the json data of the response
#     """
#     gen_cohort_url = "{}/cohortdefinition/{}/generate/OHDSI-CDMV5-synpuf".format(settings.OHDSI_ENDPOINT,
#                                                                                  cohort_id)
#     headers = {
#         "Content-Type": "application/json",
#         "Accept": "application/json",
#         # "api-key": "{}".format(settings.OHDSI_APIKEY),
#     }
#
#     response = requests.get(gen_cohort_url, headers=headers)
#     resp_json = response.json()
#     return response.status_code, resp_json


def create_ir(target_cohorts, outcome_cohorts, **options):
    """ Create ir wrapper
    :param target_cohorts: a list of the target cohorts (id, name, etc.)
    :param outcome_cohorts: a list of the outcome cohorts (id, name, etc.)
    :param **options: the various options concerning option of the ir study (i.e. age, gender, study period etc.)
    :return: the status_code and the json data of the response
    """

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    # The name of the ir to be created
    ir_name = name_entities_group(list(map(lambda c: c.get("name"), target_cohorts + outcome_cohorts)))

    status_code, exists_json = exists(ir_name, "ir")
    # print(status_code, exists_json)

    if status_code != 200:
        return status_code, {}

    if exists_json:
        return 500, {}

    ir_url = "{}/ir/".format(settings.OHDSI_ENDPOINT)

    options["target_cohorts"] = target_cohorts
    options["outcome_cohorts"] = outcome_cohorts
    options["ir_name"] = ir_name

    return add_change_ir(None, **options)

    # age = options.get("age")
    # ext_age = options.get("ext", None)
    # age_crit = options.get("age_crit", "")  # Age criterion (i.e. less than [lt] or greater than [gt])
    # age_dict = {"Age": {"Value": age, "Extent": ext_age, "Op": age_crit}} #if age > 0 else {}
    #
    # genders_lst = options.get("genders")
    #
    # gender_concepts = list(itertools.chain(
    #     *[search_concept(gender, ["Gender"])[-1] for gender in genders_lst]))
    # gender_concepts = [el for el in gender_concepts if el.get("CONCEPT_NAME").lower()
    #                    in [g.lower() for g in genders_lst]]
    # # Keep unique concept dicts
    # gender_concepts = list(map(dict, set(tuple(dic.items()) for dic in gender_concepts)))
    #
    # gender_list = [{"CONCEPT_CODE": gc.get("CONCEPT_CODE"), "CONCEPT_ID": gc.get("CONCEPT_ID"),
    #                 "CONCEPT_NAME": gc.get("CONCEPT_NAME"), "DOMAIN_ID": gc.get("DOMAIN_ID"),
    #                 "VOCABULARY_ID": gc.get("VOCABULARY_ID")} for gc in gender_concepts]
    # gender_dict = {"Gender": gender_list} #if gender_list else {}
    # # demographic_criteria = ([age_dict] if age_dict else []) + ([gender_dict] if gender_dict else [])
    # demographic_criteria = [age_dict] + [gender_dict]
    #
    # # now = datetime.now()
    # study_start_date = options.get("study_start_date")  # or now.strftime("%Y-%m-%d")
    # study_end_date = options.get("study_end_date")  # or (now + timedelta(days=90)).strftime("%Y-%m-%d")
    # study_window_dict = {"studyWindow": {"startDate": study_start_date, "endDate": study_end_date}
    #                      } if study_start_date and study_end_date else {}
    #
    # expression_dict = {"ConceptSets": [], "targetIds": list(map(lambda tc: tc.get("id"), target_cohorts)),
    #                    "outcomeIds": list(map(lambda oc: oc.get("id"), outcome_cohorts)),
    #                    "timeAtRisk": {"start": {"DateField": "StartDate", "Offset": 0},
    #                                   "end": {"DateField": "StartDate", "Offset": 0}},
    #                    "strata": [{"name": "Stratification criteria", "description": None,
    #                                "expression": {"Type": "ALL", "CriteriaList":
    #                                    [{"Criteria": {"DrugExposure":
    #                                                       {"DrugTypeExclude": None, "DrugSourceConcept": None,
    #                                                        "First": None}}, "StartWindow":
    #                                          {"Start": {"Days": None,
    #                                                     "Coeff": -1},
    #                                           "End": {"Days": None,
    #                                                   "Coeff": 1},
    #                                           "UseIndexEnd": False,
    #                                           "UseEventEnd": False},
    #                                      "RestrictVisit": False,
    #                                      "IgnoreObservationPeriod": False,
    #                                      "Occurrence": {"IsDistinct": False,
    #                                                     "Type": 2, "Count": 1}
    #                                      }
    #                                     ],
    #                                               "DemographicCriteriaList": demographic_criteria,
    #                                               "Groups": []}}]}
    #
    # if study_start_date or study_end_date:
    #     expression_dict.update(study_window_dict)
    #
    # payload = {"id": None, "name": ir_name, "description": None,
    #            "expression": json.dumps(expression_dict)
    #            }
    #
    # response = requests.post(ir_url, data=json.dumps(payload), headers=headers)
    # resp_json = response.json()
    # # print(resp_json)
    # #
    # return response.status_code, resp_json


def get_ir_option(ir_id, option_name):
    """ Get the selected option of an existing ir
    :param ir_id: the id of the existing ir
    :param option_name: the specific option to be retrieved
    :return: the option that was asked to be retrieved
    """
    options = {}
    ir_ent = get_entity_by_name("ir", ir_id)
    ir_expr = json.loads(ir_ent.get("expression", {}))
    options["targetIds"] = ir_expr.get("targetIds")
    options["outcomeIds"] = ir_expr.get("outcomeIds")
    ir_demographic_criteria = ir_expr.get("DemographicCriteriaList", {})
    age_crit = ir_demographic_criteria.get("Age", {})
    options["age"] = age_crit.get("Value")
    options["ext_age"] = age_crit.get("Extend")
    options["age_crit"] = age_crit.get("Op")

    options["genders"] = ir_demographic_criteria.get("Gender")

    ir_study_window = ir_expr.get("studyWindow")

    options["study_start_date"] = ir_study_window.get("study_start_date")
    options["study_end_date"] = ir_study_window.get("study_end_date")

    return options.get(option_name)


def change_ir(ir_id, **options):
    """ Create ir wrapper
    :param ir_id: the id of the ir to be changed
    :param **options: the various options concerning option of the ir study (i.e. age, gender, study period etc.)
    :return: the status_code and the json data of the response
    """

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    ir_url = "{}/ir/{}".format(settings.OHDSI_ENDPOINT, ir_id)

    status_code, exists_json = url_exists(ir_url)

    if status_code != 200:
        return status_code, {}

    # if exists_json:
    #     return 500, {}

    return add_change_ir(ir_id, **options)


def add_change_ir(ir_id, **options):
    """ Helper function for both create_ir and change_ir
    :param ir_id: the id of the ir to be changed
    :param options: the various options concerning option of the ir study depending on the function that calls helper
    function
    :return: the status_code and the json data of the response
    """
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        # "api-key": "{}".format(settings.OHDSI_APIKEY),
    }

    ir_url = "{}/ir/{}".format(settings.OHDSI_ENDPOINT, ir_id or "")

    # expression = {}

    target_cohorts = options.get("target_cohorts")
    outcome_cohorts = options.get("outcome_cohorts")
    ir_name = options.get("ir_name")

    if ir_id:
        response = requests.get("{}/ir/{}".format(settings.OHDSI_ENDPOINT, ir_id), headers=headers)
        response_json = response.json()
        ir_name = response_json.get("name")
        # expression = json.loads(response_json.get("expression"))

    target_cohorts_ids = list(map(lambda tc: tc.get("id"), target_cohorts)
                              ) if target_cohorts else get_ir_option("targetIds")  # expression.get("targetIds")
    outcome_cohorts_ids = list(map(lambda oc: oc.get("id"), outcome_cohorts)
                               ) if outcome_cohorts else get_ir_option("outcomeIds")  # expression.get("outcomeIds")

    age = options.get("age") or get_ir_option("age")
    ext_age = options.get("ext_age", None) or get_ir_option("ext_age")
    age_crit = options.get("age_crit", "") or get_ir_option("age_crit")  # Age criterion (i.e. less than [lt] or greater than [gt])
    age_dict = {"Age": {"Value": age, "Extent": ext_age, "Op": age_crit}}  # if age > 0 else {}

    genders_lst = options.get("genders") or get_ir_option("genders")

    gender_concepts = list(itertools.chain(
        *[search_concept(gender, ["Gender"])[-1] for gender in genders_lst]))
    gender_concepts = [el for el in gender_concepts if el.get("CONCEPT_NAME").lower()
                       in [g.lower() for g in genders_lst]]
    # Keep unique concept dicts
    gender_concepts = list(map(dict, set(tuple(dic.items()) for dic in gender_concepts)))

    gender_list = [{"CONCEPT_CODE": gc.get("CONCEPT_CODE"), "CONCEPT_ID": gc.get("CONCEPT_ID"),
                    "CONCEPT_NAME": gc.get("CONCEPT_NAME"), "DOMAIN_ID": gc.get("DOMAIN_ID"),
                    "VOCABULARY_ID": gc.get("VOCABULARY_ID")} for gc in gender_concepts]
    gender_dict = {"Gender": gender_list}  # if gender_list else {}
    # demographic_criteria = ([age_dict] if age_dict else []) + ([gender_dict] if gender_dict else [])
    demographic_criteria = [age_dict] + [gender_dict]

    # now = datetime.now()
    study_start_date = options.get("study_start_date") or get_ir_option("study_start_date")  # or now.strftime("%Y-%m-%d")
    study_end_date = options.get("study_end_date") or get_ir_option("study_end_date")  # or (now + timedelta(days=90)).strftime("%Y-%m-%d")
    study_window_dict = {"studyWindow": {"startDate": study_start_date, "endDate": study_end_date}
                         } if study_start_date and study_end_date else {}

    expression_dict = {"ConceptSets": [], "targetIds": target_cohorts_ids,
                       "outcomeIds": outcome_cohorts_ids,
                       "timeAtRisk": {"start": {"DateField": "StartDate", "Offset": 0},
                                      "end": {"DateField": "StartDate", "Offset": 0}},
                       "strata": [{"name": "Stratification criteria", "description": None,
                                   "expression": {"Type": "ALL", "CriteriaList":
                                       [{"Criteria": {"DrugExposure":
                                                          {"DrugTypeExclude": None, "DrugSourceConcept": None,
                                                           "First": None}}, "StartWindow":
                                             {"Start": {"Days": None,
                                                        "Coeff": -1},
                                              "End": {"Days": None,
                                                      "Coeff": 1},
                                              "UseIndexEnd": False,
                                              "UseEventEnd": False},
                                         "RestrictVisit": False,
                                         "IgnoreObservationPeriod": False,
                                         "Occurrence": {"IsDistinct": False,
                                                        "Type": 2, "Count": 1}
                                         }
                                        ],
                                                  "DemographicCriteriaList": demographic_criteria,
                                                  "Groups": []}}]}

    if study_start_date or study_end_date:
        expression_dict.update(study_window_dict)

    payload = {"id": ir_id, "name": ir_name, "description": None,
               "expression": json.dumps(expression_dict)
               }

    if ir_id:
        response = requests.put(ir_url, data=json.dumps(payload), headers=headers)
    else:
        response = requests.post(ir_url, data=json.dumps(payload), headers=headers)
    resp_json = response.json()
    # print(resp_json)
    #
    return response.status_code, resp_json


def name_entities_group(entities_names):
    """ Give a name to a group of OHDSI entities (i.e. concept sets, cohorts etc.)
    :param entities_names: a list of the entities names
    :return: the name of the group
    """

    return hashlib.md5("_".join(entities_names).encode('utf-8')).hexdigest()

