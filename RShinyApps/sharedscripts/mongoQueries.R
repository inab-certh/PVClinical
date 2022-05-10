library(mongolite)
library(jsonlite)
library(anytime)

# Save mongo_connection_uri variable in Renviron
mongoConnection <- function(){
  return(Sys.getenv("mongo_connection_uri"))
}

totalEventsInReports<-function(drugName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
             "$and": [
                    {
                      "drugreaction": {
                        "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
                      },
                      "reaction": {
                        "$not": {
                            "$size": 0
                        }
                    }
                  },
                    {
                      "receiptdate": {
                        "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                        "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
                      }
                    }
                  ]
            }
        }, {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
            "$unwind": {
                "path": "$reaction"
            }
        }, {
            "$group": {
                "_id": {
                    "$toUpper": "$reaction"
                }, 
                "count": {
                    "$sum": 1
                }
            }
        }, {
            "$sort": {
                "count": -1
            }
    }
  ]')}

totalDrugsInEventReports<-function(eventName, startdate, enddate){
  paste0('[
    {
        "$match": {
            "$and" : [
                  {
                    "drugreaction": {
                        "$eq": "',toupper(eventName),'"
                    }, 
                    "reaction": {
                          "$not": {
                              "$size": 0
                          }
                    }
                  },
                    {
                      "receiptdate": {
                        "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                        "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
                      }
                    }
                  ]
              }
    }, {
        "$unwind": {
            "path": "$drug"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$drug"
            }, 
            "count": {
                "$sum": 1
            }
        }
    }, {
        "$sort": {
            "count": -1
        }
    }
  ]')}

totalEventsInReports<-function(drugName, startdate, enddate, term){
  paste0('[
    {
        "$match": { 
            "$and": [
         {
            
            "drugreaction": {
                "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
            }, 
            "reaction": {
                "$not": {
                    "$size": 0
                }
            }
        },
            {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    }, {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$unwind": {
            "path": "$reaction"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$reaction"
            }, 
            "count": {
                "$sum": 1
            }
        }
    }, {
        "$sort": {
            "count": -1
        }
    }
  ]')}

totalDrugsInReports<-function(drugName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
         {
            "drugreaction": {
                "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
            }, 
            "reaction": {
                "$not": {
                    "$size": 0
                }
            }
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$unwind": {
            "path": "$drug"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$drug"
            }, 
            "count": {
                "$sum": 1
            }
        }
    }, {
        "$sort": {
            "count": -1
        }
    }
  ]')}

TimeseriesForDrugReports<-function(drugName, startdate, enddate, term){
  paste0('[
  {
    "$match": { 
      "$and" : [
         {
            "patient.drug": {
              "$not": {
                "$size": 0
              }
            },
            "drugreaction": {
              "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
            }
          },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
          
  },  {
          "$match": {
              "drug": "',toupper(term),'"
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
  ]')}

TimeseriesForEventReports<-function(eventName, startdate, enddate){
  paste0('[
  {
    "$match": {
      "$and" : [
         {
            "drugreaction": {
              "$not": {
                "$size": 0
              }
            },
            "drugreaction": {
              "$eq": "',toupper(eventName),'"
            }
          },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
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
  ]')}

TimeseriesForDrugEventReports<-function(drugName, eventName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
            {
              "drugreaction": {
                  "$not": {
                      "$size": 0
                  }
              }, 
              "$and": [
                  {
                      "drugreaction": {
                          "$eq": "',toupper(eventName),'"
                      }, 
                      "drugreaction": {
                          "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
                      }
                  }
              ]
          },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
          
    },  {
          "$match": {
              "drug": "',toupper(term),'"
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
  ]')}

CocomitantForDrugEventReports<-function(drugName, eventName, startdate, enddate, term){
  
  paste0('[
    {
        "$match": {
          "$and" : [
            {
              "drugreaction": {
                  "$not": {
                      "$size": 0
                  }
              }, 
              "$and": [
                  {
                      "drugreaction": {
                          "$eq": "',toupper(paste0('1_',toupper(drugName))),'"
                      }
                  }, {
                      "drugreaction": {
                          "$eq": "',toupper(eventName),'"
                      }
                  }
              ]
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$unwind": {
            "path": "$drug"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$drug"
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
  ]')}

ReactionsForDrugEventReports<-function(drugName, eventName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
            {
              "drugreaction": {
                  "$not": {
                      "$size": 0
                  }
              }, 
              "$and": [
                  {
                      "drugreaction": {
                          "$eq": "',toupper(paste0("1_",toupper(drugName))),'"
                      }
                  }, {
                      "drugreaction": {
                          "$eq": "',toupper(eventName),'"
                      }
                  }
              ]
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$unwind": {
            "path": "$reaction"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$reaction"
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
  ]')}

totalreports<-function(startdate, enddate){
  paste0('[
         {
        "$match": {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
    },
    {
        "$count": "safetyreportid"
    }
  ]')}

totalDrugReports<-function(drugName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
            {
            "drugreaction": {
                "$not": {
                    "$size": 0
                }
            }, 
            "drugreaction": {
                "$eq": "',paste0('1_',drugName),'"
            }
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
        
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$count": "safetyreportid"
    }
  ]')}

totalEventReports<-function(eventName, startdate, enddate){
  paste0('[
    {
        "$match": {
          "$and": [
            {
              "drugreaction": {
                  "$not": {
                      "$size": 0
                  }
              }, 
              "drugreaction": {
                  "$eq": "',eventName,'"
              }
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    }, {
        "$count": "safetyreportid"
    }
  ]')}

totalEventReportsOriginal<-function(eventName, startdate, enddate){
  paste0('[
    {
        "$match": {
          "$and": [
            {
              "drugreaction": {
                  "$not": {
                      "$size": 0
                  }
              }, 
              "reaction": {
                  "$eq": "',eventName,'"
              }
          },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    }, {
        "$count": "safetyreportid"
    }
  ]')}

totalDrugReportsOriginal<-function(drugName, startdate, enddate){
  paste0('[
    {
        "$match": {
          "$and":[
              {
                "drugreaction": {
                    "$not": {
                        "$size": 0
                    }
                }, 
                "drug": {
                    "$eq": "',drugName,'"
                }
            },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
        
    }, {
        "$count": "safetyreportid"
    }
  ]')}

totalDrugEventReports<-function(drugName, eventName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
            {
              "drugreaction": {
                  "$not": {
                      "$size": 0
                  }
              }, 
              "$and": [
                  {
                      "drugreaction": {
                          "$eq": "',paste0('1_',drugName),'"
                      }
                  }, {
                      "drugreaction": {
                          "$eq": "',eventName,'"
                      }
                  }
              ]
          },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
          
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$count": "safetyreportid"
    }
  ]')}

createDateAllQuery<-function(startdate, enddate){
  paste0('[{ "$match" : {
                "$and": [
                  
                      { "drugreaction": {
                          "$not" : { "$size" : 0 }
                          }
                      },
                     {
                          "receiptdate": {
                            "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                            "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
                          }
                     }
                  
                      ]
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
  
  ]')}

createEventsAllQuery<-function(startdate, enddate){
  paste0('[
         {
        "$match": {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
    },
    {
        "$unwind": {
            "path": "$reaction"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$reaction"
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
  ]')}

createConDrugQuery<-function(drugName, startdate, enddate, term){
  paste0('[{ "$match" : {
              "$and":[
              
                { "drugreaction": {
                    "$not" : { "$size" : 0 }
                },
                  "drugreaction": {
                    "$eq" : "',paste0('1_',drugName),'"
                  }
                },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
      },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        },
           { "$unwind":
           {"path": "$drug"}
           },
           { "$unwind":
           {"path": "$drug"}
           },
           { "$group":{
                "_id": {
                  "$toUpper": "$drug"
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

createConEventQuery<-function(eventName, startdate, enddate){
  paste0('[{ "$match" : {
              "$and":[
              { "drugreaction": {
                  "$not" : { "$size" : 0 }
              },
                "drugreaction": {
                  "$eq" : "',eventName,'"
                }
              },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
              },
           { "$unwind":
           {"path": "$reaction"}
           },
           { "$unwind":
           {"path": "$reaction"}
           },
           { "$group":{
                "_id": {
                  "$toUpper": "$reaction"
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

TimeseriesForTotalReports<-function(startdate, enddate){
  paste0('[
    {
        "$match": {
          "$and": [
            {
            "drugreaction": {
                "$not": {
                    "$size": 0
                }
            }
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
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
  ]')}

SearchDrugReports<-function(drugName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
            {
            "drugreaction": {
                "$eq": "',paste0('1_',drugName),'"
            }
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$project": {
            "safetyreportid": 1,
            "_id": 0
        }
    }
  ]')}


SearchEventReports<-function(eventName, startdate, enddate){
  paste0('[
    {
        "$match": {
        "$and":[
          {
            "drugreaction": {
                "$eq": "',eventName,'"
            }
        },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    }, {
        "$project": {
            "safetyreportid": 1,
            "_id": 0
        }
    }
  ]')}


SearchDrugEventReports<-function(drugName, eventName, startdate, enddate, term){
  paste0('[
    {
        "$match": {
          "$and": [
            {
              "$and": [
                  {
                      "drugreaction": {
                          "$eq": "',paste0('1_',drugName),'"
                      }
                  }, {
                      "drugreaction": {
                          "$eq": "',eventName,'"
                      }
                  }
              ]
          },
         {
              "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
            }
          ]
      }
    },  {
          "$match": {
              "drug": "',toupper(term),'"
            }
        }, {
        "$project": {
            "safetyreportid": 1,
            "_id": 0
        }
    }
]')}

totalEventInReports<-function(startdate, enddate){
  paste0('[
    {
        "$match": {
        "receiptdate": {
                "$gte": "',paste0(startdate, "T00:00:00.000+00:00"),'",
                "$lte": "',paste0(enddate, "T00:00:00.000+00:00"),'"
              }
        }
    }, {
        "$unwind": {
            "path": "$drug"
        }
    }, {
        "$group": {
            "_id": {
                "$toUpper": "$drug"
            }, 
            "count": {
                "$sum": 1
            }
        }
    }, {
        "$sort": {
            "count": -1
        }
    }
]')}

