library(mongolite)
library(jsonlite)
library(anytime)


convert_time_to_unix <- function(ymd, timezone = "Asia/Manila") {
  unix_seconds <- as.integer(anytime::anytime(ymd, tz = timezone))
  # Convert to milliseconds and character by pasting three zeroes at the end
  return(paste0(unix_seconds, "000"))
}



createQuery<-function(drugName=NULL,eventName=NULL,startDate=NULL,endDate=NULL,noConc=FALSE,sex=NULL,qualification=NULL,
                      seriousnesscongenitalanomali=NULL,seriousnessdeath=NULL,seriousnessdisabling=NULL,seriousnesshospitalization=NULL,
                      seriousnesslifethreatening=NULL,seriousnessother=NULL)
{
  #sex : 1=Male,2=Female 
  #qualification : 1=Physician, 2=Pharmacist, 3=Other Health Professional, 4=Lawyer, 5=Consumer or non-health...

  
  fda_query<-list()
  if (is.null(endDate))
    endDate<-Sys.Date()
  if (is.null(startDate))
    startDate<-"1980-01-01"
  
  if (!is.null(drugName)){
    if (!noConc)
      fda_query$patient.drug.openfda.generic_name <- toupper(drugName)
    else
      fda_query$drugcharacteaction <- paste0("1_",toupper(drugName))
  }
  
  if (!is.null(eventName))
    fda_query$patient.reaction.reactionmeddrapt<-toupper(eventName)
  
  if (!is.null(sex))
    fda_query$patient.patientsex<-sex
  

  if (!is.null(qualification))
    fda_query$primarysource.qualification<-qualification
  
  
  if (!is.null(seriousnesscongenitalanomali))
    fda_query$seriousnesscongenitalanomali<-seriousnesscongenitalanomali
  
  if (!is.null(seriousnessdeath))
    fda_query$seriousnessdeath<-seriousnessdeath
  
  if (!is.null(seriousnessdisabling))
    fda_query$seriousnessdisabling<-seriousnessdisabling
  
  if (!is.null(seriousnesshospitalization))
    fda_query$seriousnesshospitalization<-seriousnesshospitalization
  
  if (!is.null(seriousnesslifethreatening))
    fda_query$seriousnesslifethreatening<-seriousnesslifethreatening
  
  if (!is.null(seriousnessother))
    fda_query$seriousnessother<-seriousnessother
  
  
  fda_query$receiptdate = list(
    # Such that it is greater than or equal (gte, let for less than or equal)
    "$gte" = list(
      # To the date
      "$date" = list(
        # Represented by this Unix epoch time
        "$numberLong" = convert_time_to_unix(startDate)
      )
    ),
    "$lte" = list(
      "$date" = list(
        "$numberLong" = convert_time_to_unix(endDate)
      )
    )
  )
  

  json_fda_query <- jsonlite::toJSON(fda_query, auto_unbox = TRUE, pretty = TRUE)
  return(json_fda_query)
}

# connectionHandle<-function(query=NULL,type="count"){
#   cred<-fromJSON("credentials.json")
#   # browser()
#   con <- mongo("fda", url = paste0("mongodb://",cred$Name,":",cred$Password,"@83.212.101.89:37777/FDAforPVClinical?authSource=admin"))
#   if (is.null(query))
#     result<-con[type]()
#   else
#     result<-con[type](query)
#   con$disconnect()
#   
#   return(result)
#   
# }
# 
# connectionHandle()

con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")




createSexQuery<-function(drugName){


paste0('[{ "$match" :
              { "patient.patientsex": {
                  "$exists" : true
              },
                "patient.drug.openfda.generic_name": {
                  "$eq" : "',toupper(drugName),'"
                }
              }
              },  
              { "$group" :
                { "_id": {
                "$toLower": "$patient.patientsex"
                },
                "count": { "$sum": 1 }}
              },
                 { "$sort" :{ "count" : -1}}]')}




createQualificationQuery<-function(drugName){
paste0('[{ "$match" :
              { "primarysource.qualification": {
                  "$exists" : true
              },
                "patient.drug.openfda.generic_name": {
                  "$eq" : "',toupper(drugName),'"
                }
              }
              },  
              { "$group" :
                { "_id": {
                "$toLower": "$primarysource.qualification"
                },
                "count": { "$sum": 1 }}
              },
                 { "$sort" :{ "count" : -1}}]')}





createConDrugQuery<-function(drugName){
paste0('[{ "$match" :
              { "patient.drug": {
                  "$not" : { "$size" : 0 }
              },
                "patient.drug.openfda.generic_name": {
                  "$eq" : "',toupper(drugName),'"
                }
              }
              },
           { "$unwind":
           {"path": "$patient.drug"}
           },
           { "$unwind":
           {"path": "$patient.drug.openfda.generic_name"}
           },
           { "$group":{
                "_id": {
                  "$toUpper": "$patient.drug.openfda.generic_name"
                },
                "count": {
                  "$sum": 1
                }
            }
           },
           {"$sort":
           {
  "count": -1
}
           }
           ]')

}




createDrugIndicationgQuery<-function(drugName){
  paste0('[{ "$match" :
              { "patient.drug": {
                  "$not" : { "$size" : 0 }
              },
                "patient.drug.openfda.generic_name": {
                  "$eq" : "',toupper(drugName),'"
                }
              }
              },
           { "$unwind":
           {"path": "$patient.drug"}
           },
           { "$group":{
                "_id": {
                  "$toUpper": "$patient.drug.drugindication"
                },
                "count": {
                  "$sum": 1
                }
            }
           },
           {"$sort":
           {
  "count": -1
}
           }
           ]')
  
}




createDrugEventQuery<-function(drugName){
  paste0('[{ "$match" :
              { "patient.drug": {
                  "$not" : { "$size" : 0 }
              },
                "patient.drug.openfda.generic_name": {
                  "$eq" : "',toupper(drugName),'"
                },
                "patient.reaction": {
                "$not" : { "$size" : 0 }
                }
              }
              },
           { "$unwind":
           {"path": "$patient.reaction"}
           },
           { "$group":{
                "_id": {
                  "$toUpper": "$patient.reaction.reactionmeddrapt"
                },
                "count": {
                  "$sum": 1
                }
            }
           },
           {"$sort":
           {
  "count": -1
}
           }
           ]')
  
}


createDateDrugQuery<-function(drugName){
  paste0('[{ "$match" :
              { "patient.drug": {
                  "$not" : { "$size" : 0 }
              },
                "drugcharacteaction": {
                  "$eq" : "',toupper(paste0("1_",toupper(drugName))),'"
                }
              }
              },
           { "$group":{
                "_id": {
                  "$toUpper": "$receiptdate"
                },
                "count": {
                  "$sum": 1
                }
            }
           },
           {"$sort":
           {
  "_id": 1
}
           }
           ]')
  
}


createDateEventQuery<-function(eventName){
  paste0('[{ "$match" :
              { "patient.drug": {
                  "$not" : { "$size" : 0 }
              },
                "drugcharacteaction": {
                  "$eq" : "',toupper(eventName),'"
                }
              }
              },
           { "$group":{
                "_id": {
                  "$toUpper": "$receiptdate"
                },
                "count": {
                  "$sum": 1
                }
            }
           },
           {"$sort":
           {
  "_id": 1
}
           }
           ]')
  
}

createDateDrugEventQuery<-function(drugName, eventName){
  paste0('[{"$match": {
                "patient.drug": {
                  "$not": {
                    "$size": 0
                  }
                }, 
                "$and": [
                  {
                    "patient.reaction.reactionmeddrapt": {
                      "$eq": "',toupper(eventName),'"
                    }, 
                    "drugcharacteaction": {
                      "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
                    }
                  }
                  ]
              }
            }, {
              "$group": {
                "_id": {
                  "$toUpper": "$receiptdate"
                }, 
                "count": {
                  "$sum": 1
                }
              }
            }, {
              "$sort": {
                "_id": 1
              }
            }
        
    ]')
  
}


createDateAllQuery<-function(){
  paste0('[{ "$match" :
              { "patient.drug": {
                  "$not" : { "$size" : 0 }
                  }
                }
              },
           { "$group":{
                "_id": {
                  "$toUpper": "$receiptdate"
                },
                "count": {
                  "$sum": 1
                }
            }
           },
           { "$sort":
                     {
            "_id": 1
          }
      }
  
           ]')
  
}

totalreports<-function(){
  paste0('[
    {
        "$count": "safetyreportid"
    }
]')}

totalDrugReports<-function(drugName){
  paste0('[
    {
        "$match": {
            "patient.drug": {
                "$not": {
                    "$size": 0
                }
            }, 
            "patient.drug.openfda.generic_name": {
                "$eq": "',toupper(drugName),'"
            }
        }
    }, {
        "$count": "safetyreportid"
    }
]')}

totalEventReports<-function(eventName){
  paste0('[
    {
        "$match": {
            "patient.drug": {
                "$not": {
                    "$size": 0
                }
            }, 
            "patient.reaction.reactionmeddrapt": {
                "$eq": "',toupper(eventName),'"
            }
        }
    }, {
        "$count": "safetyreportid"
    }
]')}



