from collections import namedtuple


def get_drugs():

    # Change with real service
    drugs = sorted([("Omeprazole", "A02BC01"), ("Esomeprazole", "A02BC05"),
             ("Etybenzatropine", "N04AC30"), ("Benzatropine", "N04AC01"),
             ("Phenytoin", "N03AB02"), ("Olmesartan", "C09CA08")])

    # Turn drugs into objects with name and code
    DrugStruct = namedtuple("DrugStruct", "name, code")
    drugs = [DrugStruct(name=d[0], code=d[1]) for d in drugs]

    return drugs


def get_conditions():

    # Change with real service
    conditions = sorted([("Pain","10033371"), ("Stinging", "10033371"),
                  ("Rhinitis", "10039083"), ("Allergic rhinitis", "10039085"),
                  ("Partial visual loss", "10047571"), ("Dry mouth", "10013781"),
                         ("Sprue-like enteropathy", "10079622"),])

    # Turn conditions into objects with name and code
    ConditionStruct = namedtuple("ConditionStruct", "name, code")
    conditions = [ConditionStruct(name=c[0], code=c[1]) for c in conditions]

    return conditions
