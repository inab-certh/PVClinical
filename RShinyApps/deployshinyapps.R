require(rsconnect)
base <- 'C:/RProjects/deployshiny/'
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
 "510kview", 
 "ChangePoint", 
 "Dash" ,  
 "RR_E",
 "DrugEnforceView",
 "DynPRR" ,
 "deviceenforceview",
 "LabelView"  ,
 "LRTest_E" ,
 "LRTest",  
 "ReportView" , 
 "RR_D" , 
 "QuickView",
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

rsconnect::setAccountInfo(name='vagelisgakis',
                          token='159F8EE8E65CFCE1FB016F62133E2210',
                          secret='0cj43uRyEovfEccqwq99yfvR2T8FkmuCqqRnSnon')
for ( i in seq_along(app))
  {
  deployApp(paste(base, app[i],sep = ""), appName=app[i],forceUpdate = getOption("rsconnect.force.update.apps", TRUE))
}
# for ( i in seq_along(app))
# {
#   deployApp(app[i], lint=FALSE)
# }