require(rsconnect)
base <- '/srv/shiny-server/deployshiny/'
dirlist <- list.dirs(full.names=FALSE, recursive=FALSE)
exclude<- c(
  ".git",
  ".Rproj.user",
  "016-knitr-pdf",
  "RR_D - dep",
  'tmp',
  "sharedscripts"
)
app <- setdiff(dirlist, exclude)
app <- c(
 "ChangePoint",
 "Dash" ,
 "RR_E",
 "DrugEnforceView",
 "DynPRR" ,
 "LRTest_E" ,
 "LRTest",
 "RR_D" , 
 "QuickViewDrug",
 "QuickViewDrugEvent",
 "QuickViewEvent",
 "LabelView"  ,
 # "ReportView" ,
 # "deviceenforceview",
 # "510kview", 
 NULL
)
#  "deviceclassview",
 
# "devicerecallview" ,
# "devicereglist",  
# "devicereports" ,   
   
 
# "foodrecallview" , 
    
 
# "LR_D_Activesubstancename" ,   
#  "LR_E_Activesubstancename" ,          
   
# "PMAview" ,         
     
      
#    "RR_D_Activesubstance" ,     
#    "RR_E_Activesubstance" ,      
#    "dynprr_Activesubstance" ,         
# "RR_Dev"  ,     
 

#)

rsconnect::setAccountInfo(name='Name of account to save or remove',
                          token='User token for the account',
                          secret='User secret for the account')
for ( i in seq_along(app))
  {
  deployApp(paste(base, app[i],sep = ""), appName=app[i],forceUpdate = getOption("rsconnect.force.update.apps", TRUE))
}
# for ( i in seq_along(app))
# {
#   deployApp(app[i], lint=FALSE)
# }