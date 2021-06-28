require(shiny)
require(lubridate)
if (!require('openfda') ) {
  devtools::install_github("ropenhealth/openfda")
  library(openfda)
}

library(shiny)
library(shiny.i18n)
library(tidyverse)
library(xlsx)
library(stringr)
library(plyr)
source('sourcedir.R')


translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')


#**************************************
shinyServer(function(input, output, session) {
  
  cacheFolder<-"/var/www/html/openfda/media/"
  # cacheFolder<- "C:/Users/dimst/Desktop/work_project/"
  
  
  values<-reactiveValues(urlQuery=NULL)
  search_val<-reactiveValues(id = FALSE, skip = NULL)
  
  
  i18n <- reactive({
    selected <- input$selected_language
    if (length(selected) > 0 && selected %in% translator$languages) {
      translator$set_translation_language(selected)
    }
    translator
  })
  
  # geturlquery <- observe({
  #   addClass("panel_title", "custom-title")
  #   # removeClass("panel_title", "shiny-text-output")
  #   # removeClass("panel_title", "shiny-bound-output")
  #   q <- parseQueryString(session$clientData$url_search)
  #   
  #   selectedLang = tail(q[['lang']], 1)
  #   if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  #   {
  #     selectedLang='en'
  #   }
  #   
  #   selectInput('selected_language',
  #               i18n()$t("Change language"),
  #               choices = c("en","gr"),
  #               selected = selectedLang)
  #   langs = list(gr="el", en="en")
  #   
  #   translator$set_translation_language(selectedLang)
  #   updateButton(session, 'prevrow', label = paste('<', i18n()$t('Previous')), icon = NULL, value = NULL,
  #                style = NULL, size = NULL, block = NULL, disabled = NULL)
  #   updateButton(session, 'nextrow', label = paste(i18n()$t('Next'), '>'), icon = NULL, value = NULL,
  #                style = NULL, size = NULL, block = NULL, disabled = NULL)
  #   updateButton(session, 'tabBut', label = paste(i18n()$t('Filter by'), '...'), icon = NULL, value = NULL,
  #                style = NULL, size = NULL, block = NULL, disabled = NULL)
  #   updateButton(session, 'update', label = i18n()$t('Update Variables'), icon = NULL, value = NULL,
  #                style = 'primary', size = NULL, block = NULL, disabled = NULL)
  #   updateButton(session, 'modalCloseBtn', label = i18n()$t('Close'), icon = NULL, value = NULL)
  #   updateSliderInput(session, 'skip', paste(i18n()$t('Report'),' #'), value=1, min=1, step= 1, max=100)
  #   # updateRadioButtons(session, 'useexact',
  #   #                    selected = if(length(q$useexact)==0) "exact" else q$useexact)
  #   # updateRadioButtons(session, 'useexactD',
  #   #                    selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
  #   # updateRadioButtons(session, 'useexactE',
  #   #                    selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
  #   updateTabsetPanel(session, 'maintabs', selected=q$curtab)
  #   # updateTextInput(session, "safetyreportid", value = getreportid())
  #   
  #   t1 <- gsub('"[', '[', q$t1, fixed=TRUE)
  #   t1 <- gsub(']"', ']', t1, fixed=TRUE)
  #   t1 <- gsub('""', '"', t1, fixed=TRUE)
  #   updateTextInput(session, "t1", value = t1)
  #   updateTextInput(session, "t1_2", value = t1)
  #   
  #   t2 <- gsub('"[', '[', q$t2, fixed=TRUE)
  #   t2 <- gsub(']"', ']', t2, fixed=TRUE)
  #   t2 <- gsub('""', '"', t2, fixed=TRUE)
  #   updateTextInput(session, "t2", value = t2)
  #   updateTextInput(session, "t2_2", value = t2)
  #   
  #   if(!is.null(q$t3) )
  #   {  
  #     t3 <- gsub('"[', '[', q$t3, fixed=TRUE)
  #     t3 <- gsub(']"', ']', t3, fixed=TRUE)
  #     t3 <- gsub('""', '"', t3, fixed=TRUE)
  #     updateTextInput(session, "t3", value = t3)
  #     updateTextInput(session, "t3_2", value = t3)
  #   }
  #   
  #   
  #   if(!is.null(q$v1) )
  #   {
  #     v1 <- gsub('"', '', q$v1, fixed=TRUE)
  #     updateSelectizeInput(session, inputId = "v1", selected = v1)
  #     updateSelectizeInput(session, inputId = "v1_2", selected = v1)
  #   } 
  #   if(!is.null(q$v2) )
  #   {
  #     v2 <- gsub('"', '', q$v2, fixed=TRUE)
  #     updateSelectizeInput(session, inputId = "v2", selected = v2)
  #     updateSelectizeInput(session, inputId = "v2_2", selected = v2)
  #   }
  #   if(!is.null(q$v3) )
  #   { 
  #     v3 <- gsub('"', '', q$v3, fixed=TRUE)
  #     updateSelectizeInput(session, inputId = "v3", selected = v3)
  #     updateSelectizeInput(session, inputId = "v3_2", selected = v3)
  #   }
  #   #   
  #   #   updateNumericInput(session, "skip", value = q$skip)
  #   #   return(q)
  #   
  # })
  
  output$paneltitle <- renderText({
    i18n()$t("Drug Adverse Event Report Browser")
    })
  
  output$variablesmodal <- renderText({
    i18n()$t("Enter Variables")
  })
  
  output$variablelbl1 <- output$variablelbl2 <- output$variablelbl3 <- renderText({
    i18n()$t("Variable")
  })
  
  output$termslbl1 <- output$termslbl2 <- output$termslbl3 <- renderText({
    i18n()$t("Terms")
  })
  
  output$termslbl1 <- output$termslbl2 <- output$termslbl3 <- renderText({
    i18n()$t("Terms")
  })
  
  output$overviewtxt <- renderText({
    i18n()$t("Overview")
  })
  
  # output$metadatatxt <- renderText({
  #   i18n()$t("Meta Data")
  # })
  # 
  # output$reportheadertxt <- renderText({
  #   i18n()$t("Report Header")
  # })
  # 
  # output$patienttxt <- renderText({
  #   i18n()$t("Patient")
  # })
  
  output$patreactiontxt <- renderText({
    i18n()$t("Reactions")
  })
  
  output$patdrugtxt <- renderText({
    i18n()$t("Drugs")
  })
  
  output$patdrugopenfdatxt <- renderText({
    i18n()$t("Medication")
    # i18n()$t("Patient.Drug.OpenFDA")
  })
  
  # output$closebtnlbl <- renderText({
  #   i18n()$t("Close")
  # })
  

  # #Translated uiOutputs
  # output$title_panel <- renderText({
  #   paste("<h2>", i18n()$t("Drug Adverse Event Report Browser"), "</h2>")
  # })  
  
  
getskip <- reactive({
  # browser()
  if (search_val$id == TRUE) {
    return( search_val$skip-1 )
    
  } else {
    return( input$skip-1 )
  }
  
})
ntext <- eventReactive( input$nextrow, {
  search_val$id <- FALSE
  q <- geturlquery()
  myskip <- getskip()
  mydf <- getfullquery()

  if (q$concomitant == FALSE){
    numrecs <- mydf$df.total
  } else {
    numrecs <- mydf$df.meta$results$total
  }
  maxlim <- min(getopenfdamaxrecords(), numrecs)
  updateSliderInput( session, 'skip', value= min(myskip+2, maxlim), min=1, step= 1, max=maxlim)
})

observeEvent( input$searchID, {
  search_val$id <- TRUE
  q <- geturlquery()
  if (q$concomitant == FALSE){
    if (q$v1 == 'patient.reaction.reactionmeddrapt') {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      eventQuery <- SearchEventReports(q$t1)
      ids <- con$aggregate(eventQuery)
      con$disconnect()
    } else if (q$v2 == 'patient.reaction.reactionmeddrapt'){
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugeventQuery <- SearchDrugEventReports(q$t1,q$t2)
      ids <- con$aggregate(drugeventQuery)
      con$disconnect()
    } else {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugQuery <- SearchDrugReports(q$t1)
      ids <- con$aggregate(drugQuery)
      con$disconnect()
    }
    
    id_vector <- unlist(list(ids$safetyreportid))
    search_val$skip <- match(input$searchID, id_vector) + 1

    myskip <- getskip()
    mydf <- getfullquery()
    numrecs <- mydf$df.total
  } else {
    v1 <- c(input$v1, input$v2, input$v3)
    t1 <- c(gett1(), gett2(), gett3() ) 
    if (v1[1] != ""){
      t1[1] = q$dename
    }
    if (v1[2] == "patient.reaction.reactionmeddrapt"){
      t1[2] = q$ename
    }
    myurl <- buildURL(v1, t1, limit = 1000, count = 'safetyreportid.exact')
    ids <-  fda_fetch_p(session, myurl)
    id_vector <- unlist(list(ids$results$term))
    search_val$skip <- match(input$safetyreportid, id_vector) - 2
    myskip <- getskip()
    mydf <- getfullquery()
    numrecs <- mydf$df.meta$results$total 
  }
  browser()
  maxlim <- min(getopenfdamaxrecords(), numrecs)
  updateSliderInput( session, 'skip', value= min(myskip+2, maxlim), min=1, step= 1, max=maxlim)
  
  })


gett1 <- function(){
  anychanged()
  s <- input$t1
  if (getv1() != '_exists_')
    {
    s <- toupper( input$t1 )
    }
  return( s )
}
gett2 <- function(){
  s <- input$t2
  if (getv2() != '_exists_')
  {
  s <- toupper( input$t2 )
  }
  return( s )
}
gett3 <- function(){
  s <- input$t3
  if (getv3() != '_exists_')
  {
  s <- toupper( input$t3 )
  }
  return( s )
}
getv1 <- function(){
  s <- ( input$v1 )
  return( s )
}
getv2 <- function(){
  s <- ( input$v2)
  return( s )
}
getv3 <- function(){
  s <- ( input$v3 )
  return( s )
}

updatevars <- reactive({
  input$update
  isolate( {
    updateviewerinputs(session)
  })
})



anychanged <- reactive({
  a <- input$t1
  b <- input$v1
  c <- input$t2
  d <- input$v2
  c <- input$t3
  d <- input$v3
  
  closeAlert(session, 'erroralert')
})

output$mymodal <- renderText({
  if (input$update > 0)
  {
    updatevars()    
    toggleModal(session, 'modalUpdateVars', 'close')
  }
  return('')
})


output$ntext <- renderText( {
  ntext()
  return('')
})

ptext <- eventReactive( input$prevrow, {
  search_val$id <- FALSE
  q <- geturlquery()
  myskip <- getskip() -2 
  mydf <- getfullquery()
  if (q$concomitant == FALSE){
    numrecs <- mydf$df.total
  } else {
    numrecs <- mydf$df.meta$results$total
  }
  maxlim <- getopenfdamaxrecords( numrecs )
  updateSliderInput( session, 'skip', value= max(myskip+2, 1), min=1, step= 1, max=maxlim)
})

output$ptext <- renderText( {
  ptext()
  return('')
})
getquery <- reactive({
  

  if (  input$t1 == '' & input$t2 == '' & input$t3 == ''){
    v1 = '_exists_'
    t1 = 'safetyreportid'
    v2 <- ''
    t2 <- ''
    v3 <- ''
    t3 <- ''
  } else {
    v1 <- c(input$v1, input$v2, input$v3)
    t1 <- c(gett1(), gett2(), gett3() ) 
  }
  q <- geturlquery()
  if (v1[1] != ""){
    t1[1] = q$dename
  }
  if (v1[2] == "patient.reaction.reactionmeddrapt"){
    t1[2] = q$ename
  }
  myurl <- buildURL(v1, t1,  limit=1, skip=getskip())
  # browser()
  
  if (q$concomitant == FALSE){
    if (q$v1 == 'patient.reaction.reactionmeddrapt') {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      eventQuery <- SearchEventReports(q$t1)
      ids <- con$aggregate(eventQuery)
      con$disconnect()
    } else if (q$v2 == 'patient.reaction.reactionmeddrapt'){
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugeventQuery <- SearchDrugEventReports(q$t1,q$t2)
      ids <- con$aggregate(drugeventQuery)
      con$disconnect()
    } else {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugQuery <- SearchDrugReports(q$t1)
      ids <- con$aggregate(drugQuery)
      con$disconnect()
    }
    myurl <- buildURL(v= 'safetyreportid', t=ids$safetyreportid[[getskip()+1]])
    mydf <- fda_fetch_p(session, myurl)
  } else {
    mydf <- fda_fetch_p(session, myurl)
  }

  
  openfdalist <- (mydf$results$patient$drug[[1]])$openfda
  openfdadf <- listtodf(openfdalist, delim='; ', trunc=400)
  patientdf <- mydf$results$patient
  summarydf <- mydf$results$patient$summary
  drugdf <- mydf$results$patient$drug[[1]]
  reactiondf<- mydf$results$patient$reaction[[1]]
  if (is.null(openfdalist)) {
    openfdalist <- data.frame(note='No OpenFDA variables for this report')
  }
  out <- list(df=mydf, patientdf=patientdf, summarydf=summarydf, drugdf=drugdf, 
              reactiondf=reactiondf, openfdadf=openfdadf, url=myurl )

  return(out)
})    

getreportid <- reactive({
  mydf <- getquery()
  tmp <- mydf$df$results
  id <- tmp$safetyreportid
  if (is.null(id)){
    id = 'Missing Report ID'
    createAlert(session, "nodata_report", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    
    hide('titlerow')
    hide('navrow')
    hide('sliderrow')
    hide('mainrow')
  }
  return(id)
})

getfullquery <- reactive({

  if ( input$t1==''  & input$t2 == '' & input$t3 == '' ){
    v1 = '_exists_'
    t1 = 'safetyreportid'
    v2 <- ''
    t2 <- ''
    v3 <- ''
    t3 <- ''
  } else {
    v1 <- c(input$v1, input$v2, input$v3)
    t1 <- c(gett1(), gett2(), gett3() ) 
  }
  q <- geturlquery()
  if (v1[1] != ""){
    t1[1] = q$dename
  }
  if (v1[2] == "patient.reaction.reactionmeddrapt"){
    t1[2] = q$ename
  }
  myurl <- buildURL(v1, t1, limit=1)
 
 
  if (q$concomitant == FALSE){
    if (q$v1 == 'patient.reaction.reactionmeddrapt') {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      eventQuery <- SearchEventReports(q$t1)
      ids <- con$aggregate(eventQuery)
      con$disconnect()
    } else if (q$v2 == 'patient.reaction.reactionmeddrapt'){
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugeventQuery <- SearchDrugEventReports(q$t1,q$t2)
      ids <- con$aggregate(drugeventQuery)
      con$disconnect()
    } else {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugQuery <- SearchDrugReports(q$t1)
      ids <- con$aggregate(drugQuery)
      con$disconnect()
    }
    myurl <- buildURL(v= 'safetyreportid', t=ids$safetyreportid[[1]])
    mydf <- fda_fetch_p(session, myurl)
    mydf$total <- length(ids$safetyreportid)

  } else {
    mydf <- fda_fetch_p(session, myurl)
  }
  
  # mydf <- fda_fetch_p(session, myurl)

  out <- c(df=mydf, url=myurl)
#  print(typeof(mydf$results[[1]]))
  #browser()
  return(out)
})    
output$v1 <- renderText({
  s <- getv1()
  if(s == '') {
    s <- 'None'
  }
  out <- paste0( '<br><b>', i18n()$t('Variable'),': <i>', s, '</i></b>' )
  return(out)
})

output$v2 <- renderText({
  s <- getv2()
  if(s == '') {
    s <- 'None'
  }
  out <- paste0( '<br><b>', i18n()$t('Variable'),': <i>', s, '</i></b>' )
  return(out)
})

output$v3 <- renderText({
  s <- getv3()
  if(s == '') {
    s <- 'None'
  }
  out <- paste0( '<br><b>', i18n()$t('Variable'),': <i>', s, '</i></b>' )
  return(out)
})
output$t1 <- renderText({
  s <- gett1()
  if(s == '') {
    s <- 'None'
  }
  out <- paste0( '<br><b>', i18n()$t('Term'),': <i>', s, '</i></b>' )
  return(out)
})
output$t2 <- renderText({
  s <- gett2()
  if(s == '') {
    s <- 'None'
  }
  out <- paste0( '<br><b>', i18n()$t('Term'),': <i>', s, '</i></b>' )
  return(out)
})
output$t3 <- renderText({
  s <- gett3()
  if(s == '') {
    s <- 'None'
  }
  out <- paste0( '<br><b>', i18n()$t('Term'),': <i>', s, '</i></b>' )
  return(out)
})

#Patient***********************



output$patientreportid <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<h4>' )
  return( s )
})

output$reportinput <- renderText({  
  s  <- paste('<h4>', getreportid(), '<h4>' )
  return( s )
})

output$reporttable <- renderTable({ 
  
  myalldf <- getquery()
  
  if ( is.null( nrow(myalldf$df$results) )  )
  {
    #   print( myalldf$df$results )
    return(data.frame(Drug= 'No results for query', Count=0))
  }
  if ( is.data.frame(myalldf$df$results) )
  {
    tmp <- myalldf$df$results
    types <- (sapply(tmp, class))
    typesval <- types[types!='data.frame']
    mydf <- tmp[ , names(typesval) ]
    myvars <-  c('safetyreportid', 'receivedate', 'receiptdate', 'companynumb')
    availnames <-  myvars %in% names(mydf)
    mydfheader <- mydf[, myvars[availnames] ]
    mynames <- names(mydfheader)
    #       mynames <- gsub('safetyreportid', 'Case_ID', mynames, fixed=TRUE )
    #       mynames <- gsub('receivedate', 'First_Received', mynames, fixed=TRUE )
    #       mynames <- gsub('receiptdate', 'Most_Recent', mynames, fixed=TRUE )
    #       mynames <- gsub('companynumb', 'Company_Number', mynames, fixed=TRUE )
    names(mydfheader) <- mynames
    
    if ('receiptdate' %in% names(mydfheader))
    { 
      mydfheader[ , 'receiptdate'] <- ymd(mydfheader[ , 'receiptdate']) 
      mydfheader[ , 'receiptdate'] <- format(mydfheader[ , 'receiptdate'], "%m/%d/%y") 
    }
    if ('receivedate' %in% names(mydfheader))
    { 
      mydfheader[ , 'receivedate'] <- ymd(mydfheader[ , 'receivedate']) 
      mydfheader[ , 'receivedate'] <- format(mydfheader[ , 'receivedate'], "%m/%d/%y") 
    }
    
    Report <- c( 'First_Received', 'Most_Recent')
    Dates <- c( mydfheader$receivedate, mydfheader$receiptdate)
    mydf_p <- data.frame(Report, Dates)
    mydf <- mydf_p
    
  }
    
    return(mydf) 
  })

output$patienttable <- renderTable({  
  # if (input$t1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
  myalldf <- getquery()
  
  if ( is.null( nrow(myalldf$df$results) )  )
  {
    #   print( myalldf$df$results )
    return(data.frame(Drug= 'No results for query', Count=0))
  }
  if ( is.data.frame(myalldf$df$results) )
  {
    tmp <- myalldf$df$results
    types <- (sapply(tmp, class))
    typesval <- types[types!='data.frame']
    mydf <- tmp[ , names(typesval) ]
    myvars <-  c('safetyreportid', 'receivedate', 'receiptdate', 'companynumb')
    availnames <-  myvars %in% names(mydf)
    mydfheader <- mydf[, myvars[availnames] ]
    mynames <- names(mydfheader)
    #       mynames <- gsub('safetyreportid', 'Case_ID', mynames, fixed=TRUE )
    #       mynames <- gsub('receivedate', 'First_Received', mynames, fixed=TRUE )
    #       mynames <- gsub('receiptdate', 'Most_Recent', mynames, fixed=TRUE )
    #       mynames <- gsub('companynumb', 'Company_Number', mynames, fixed=TRUE )
    names(mydfheader) <- mynames
    
    if ('receiptdate' %in% names(mydfheader))
    { 
      mydfheader[ , 'receiptdate'] <- ymd(mydfheader[ , 'receiptdate']) 
      mydfheader[ , 'receiptdate'] <- format(mydfheader[ , 'receiptdate'], "%m/%d/%y") 
    }
    if ('receivedate' %in% names(mydfheader))
    { 
      mydfheader[ , 'receivedate'] <- ymd(mydfheader[ , 'receivedate']) 
      mydfheader[ , 'receivedate'] <- format(mydfheader[ , 'receivedate'], "%m/%d/%y") 
    }
    myvars <-  c("seriousnesscongenitalanomali",
                 "seriousnessdeath",
                 "seriousnessdisabling",
                 "seriousnesshospitalization",
                 "seriousnesslifethreatening",
                 "seriousnessother")
    availnames <-  names(mydf) %in% myvars 
    myserious <- names( mydf)[availnames]
    myserious <- paste(myserious, collapse=', ')
    myserious <- gsub('seriousnesscongenitalanomali', 'Congenital Anomali', myserious, fixed=TRUE )
    myserious <- gsub('seriousnessdeath', 'Death', myserious, fixed=TRUE )
    myserious <- gsub('seriousnessdisabling', 'Disabling', myserious, fixed=TRUE )
    myserious <- gsub('seriousnesshospitalization', 'Hospitalization', myserious, fixed=TRUE )
    myserious <- gsub('seriousnesslifethreatening', 'Life Threatening', myserious, fixed=TRUE )
    myserious <- gsub('seriousnessother', 'Other', myserious, fixed=TRUE )
  } 
  if ( is.data.frame(myalldf$df$results$patient) )
  {
    mydf <- (myalldf$df$results$patient)    
    types <- (sapply(mydf, class))
    typesval <- types[types!='data.frame' & types!='list']
    mydfpatient <- mydf[ , names(typesval) ]
    myvars <- c( 'patientonsetage', 'patientweight','patientsex' )
    availnames <-  myvars %in% names(mydfpatient)
    mydfpatient <- mydf[ , myvars[availnames] ]
    mynames <- names(mydfpatient)
    mynames <- gsub('patientonsetage', 'Age', mynames, fixed=TRUE )
    mynames <- gsub('patientweight', 'Weight', mynames, fixed=TRUE )
    mynames <- gsub('patientsex', 'Gender', mynames, fixed=TRUE )
    names(mydfpatient) <- mynames
  }
  
  if ('Gender' %in% names(mydfpatient))
  { 
    mydfpatient[ mydfpatient[,'Gender']==2 , 'Gender'] <- 'Female' 
    mydfpatient[ mydfpatient[,'Gender']==1 , 'Gender'] <- 'Male' 
    mydfpatient[ mydfpatient[,'Gender']==0 , 'Gender'] <- 'Unknown' 
  }
 
  # browser()
  
  Patient <- c('Gender', 'Age', 'Weight', 'Outcome')
  if ( is.null(mydfpatient$Weight)){
    mydfpatient$Weight <- "UNKNOWN"
  }
  if ( is.null(mydfpatient$Age)){
    mydfpatient$Age <- "UNKNOWN"
  }
  if ( is.null(mydfpatient$Gender)){
    mydfpatient$Gender <- "UNKNOWN"
  }
  if ( is.null(myserious)){
    myserious <- "UNKNOWN"
  }
  Description <- c(mydfpatient$Gender, mydfpatient$Age, mydfpatient$Weight, myserious)
  mydf_p <- data.frame(Patient, Description)
  
  
  
  #   browser()
  #   mydrugs2 <- listtostring( (myalldf$df$results$patient$drug)[[1]]$activesubstance$activesubstancename )
  #   print(mydrugs2)
  #   print( typeof(mydrugs2) )
 
  mydf <- data.frame(mydfheader, mydfpatient, 
                     Outcome=myserious,
                     stringsAsFactors = FALSE)
  mydf <- mydf_p

  # if (nrow(mydf) > 1)
  # {
  #   mydf[2:nrow(mydf), !chopvars ] <- " "
  # }
  if (!is.null(input$sourceReportframeUI)){
    if (input$sourceReportframeUI){
      write.csv(mydf,paste0(cacheFolder,values$urlQuery$hash,"_report.csv"))
      
    }
  }
  return(mydf) 
})


#Overview**********************
output$overviewtitle <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<h4><br>Header' )
  return( s )
})

output$overviewtable <- renderTable({  
  # if (input$t1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
  myalldf <- getquery()
  if ( is.null( nrow(myalldf$df$results) )  )
  {
 #   print( myalldf$df$results )
    return(data.frame(Drug= 'No results for query', Count=0))
  }
  if ( is.data.frame(myalldf$df$results) )
    {
      tmp <- myalldf$df$results
      types <- (sapply(tmp, class))
      typesval <- types[types!='data.frame']
      mydf <- tmp[ , names(typesval) ]
      myvars <-  c('safetyreportid', 'receivedate', 'receiptdate', 'companynumb')
      availnames <-  myvars %in% names(mydf)
      mydfheader <- mydf[, myvars[availnames] ]
      mynames <- names(mydfheader)
#       mynames <- gsub('safetyreportid', 'Case_ID', mynames, fixed=TRUE )
#       mynames <- gsub('receivedate', 'First_Received', mynames, fixed=TRUE )
#       mynames <- gsub('receiptdate', 'Most_Recent', mynames, fixed=TRUE )
#       mynames <- gsub('companynumb', 'Company_Number', mynames, fixed=TRUE )
      names(mydfheader) <- mynames
      
      if ('receiptdate' %in% names(mydfheader))
      { 
        mydfheader[ , 'receiptdate'] <- ymd(mydfheader[ , 'receiptdate']) 
        mydfheader[ , 'receiptdate'] <- format(mydfheader[ , 'receiptdate'], "%m/%d/%y") 
      }
      if ('receivedate' %in% names(mydfheader))
      { 
        mydfheader[ , 'receivedate'] <- ymd(mydfheader[ , 'receivedate']) 
        mydfheader[ , 'receivedate'] <- format(mydfheader[ , 'receivedate'], "%m/%d/%y") 
      }
      myvars <-  c("seriousnesscongenitalanomali",
                    "seriousnessdeath",
                    "seriousnessdisabling",
                    "seriousnesshospitalization",
                    "seriousnesslifethreatening",
                    "seriousnessother")
      availnames <-  names(mydf) %in% myvars 
      myserious <- names( mydf)[availnames]
      myserious <- paste(myserious, collapse=';')
      myserious <- gsub('seriousnesscongenitalanomali', 'CA', myserious, fixed=TRUE )
      myserious <- gsub('seriousnessdeath', 'DT', myserious, fixed=TRUE )
      myserious <- gsub('seriousnessdisabling', 'DS', myserious, fixed=TRUE )
      myserious <- gsub('seriousnesshospitalization', 'HO', myserious, fixed=TRUE )
      myserious <- gsub('seriousnesslifethreatening', 'LT', myserious, fixed=TRUE )
      myserious <- gsub('seriousnessother', 'OT', myserious, fixed=TRUE )
    } 
  if ( is.data.frame(myalldf$df$results$patient) )
    {
    mydf <- (myalldf$df$results$patient)    
    types <- (sapply(mydf, class))
    typesval <- types[types!='data.frame' & types!='list']
    mydfpatient <- mydf[ , names(typesval) ]
    myvars <- c( 'patientonsetage', 'patientweight','patientsex' )
    availnames <-  myvars %in% names(mydfpatient)
    mydfpatient <- mydf[ , myvars[availnames] ]
    mynames <- names(mydfpatient)
    mynames <- gsub('patientonsetage', 'Age', mynames, fixed=TRUE )
    mynames <- gsub('patientweight', 'Weight', mynames, fixed=TRUE )
    mynames <- gsub('patientsex', 'Gender', mynames, fixed=TRUE )
    names(mydfpatient) <- mynames
  }
  if ('Gender' %in% names(mydfpatient))
    { 
    mydfpatient[ mydfpatient[,'Gender']==2 , 'Gender'] <- 'Female' 
    mydfpatient[ mydfpatient[,'Gender']==1 , 'Gender'] <- 'Male' 
    mydfpatient[ mydfpatient[,'Gender']==0 , 'Gender'] <- 'Unknown' 
  }
  # browser()
  myevents <- listtostring( (myalldf$df$results$patient$reaction)[[1]][1] )
  mydrugs <- (myalldf$df$results$patient$drug)[[1]]$medicinalproduct
  mydrugs2 <- ( (myalldf$df$results$patient$drug)[[1]]$activesubstance$activesubstancename )
  if( length(mydrugs2) < length(mydrugs) )
  {
    mydrugs2 <- vector('character', length=length(mydrugs))
  }
#   browser()
#   mydrugs2 <- listtostring( (myalldf$df$results$patient$drug)[[1]]$activesubstance$activesubstancename )
#   print(mydrugs2)
#   print( typeof(mydrugs2) )
  myindications <- (myalldf$df$results$patient$drug)[[1]]$drugindication 
  mycharacterization <- (myalldf$df$results$patient$drug)[[1]]$drugcharacterization
  mycharacterization <- gsub(1, 'SUSPECT DRUG', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(2, 'CONCOMITANT DRUG', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(3, 'INTERACTING DRUG', mycharacterization, fixed=TRUE )
  mydf <- data.frame(mydfheader, mydfpatient, Events=myevents, 
                     Outcome=myserious,
                     Product_Role=mycharacterization,  
                     Active_Substance=mydrugs2,
                     Medicinal_Products=mydrugs,
                     stringsAsFactors = FALSE)
  if ( length(myindications)!=0 )
    {
    mydf <- data.frame(mydf, Indication=myindications, stringsAsFactors = FALSE)
    }
  vectnames <- c( 'Product_Role', 'Active_Substance', 'Medicinal_Products', 'Indication' )
  chopvars <- names(mydf) %in% vectnames  
  if (nrow(mydf) > 1)
    {
    mydf[2:nrow(mydf), !chopvars ] <- " "
  }
  if (!is.null(input$sourceReportframeUI)){
    if (input$sourceReportframeUI){
      write.csv(mydf,paste0(cacheFolder,values$urlQuery$hash,"_report.csv"))
      
    }
  }
  return(mydf) 
})

#HEADER**********************
output$headertabletitle <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<h4><br>Header' )
      return( s )
  })

output$reportId <- renderText({ getreportid()
   # if (input$safetyreportid != getreportid()){
   #   myurl <- buildURL(v= 'safetyreportid', t=paste(input$safetyreportid, collapse=', ' ) )
   #   result <-  fda_fetch_p(session, myurl)$result
   # }
  
  })
  
output$headertable <- renderTable({  
    mydf <- getquery()
    tmp <- mydf$df$results 
    mynames <- getallvars( allvars(), mytype = 'text', section= c('rh'))
  if ( is.data.frame(tmp) )
{
    mydf <- extractdfcols( tmp, mynames, numrows = nrow(tmp) )
    return(mydf) 
  } else  {return(data.frame(Drug=paste( 'No events for drug', input$t1), Count=0))}
  })

#RECEIVER****************************
output$receivertabletitle <- renderText({  
  s  <- ('<h4>Receiver</h4>' )
  return( s )
})

output$receiver <- renderTable({  
    mydf <- getquery()
    mydf <- getdf( mydf$df$results, 'receiver', message='No receiver data')
    return(mydf) 
})

#PREPORTDUPLICATE****************************

output$reportduplicatetabletitle <- renderText({  
  s  <- ('<h4><br>Report Duplicate</h4>' )
  return( s )
})


output$reportduplicate <- renderTable({  
  mydf <- getquery()
  mydf <- getdf( mydf$df$results, 'reportduplicate', message='No duplicate report data')
  return(mydf) 
})

#SENDER****************************

output$sendertabletitle <- renderText({  
  s  <- '<h4><br>Sender</h4>' 
  return( s )
})

output$sender <- renderTable({  
  mydf <- getquery()
  mydf <- getdf( mydf$df$results, 'sender', message='No sender data')
  return(mydf) 
})

#PRIMARYSOURCE****************************

output$primarysourcetabletitle <- renderText({  
  s  <- '<h4><br>Primary Source</h4>' 
  return( s )
})

output$primarysource <- renderTable({  
  mydf <- getquery()
  mydf <- getdf( mydf$df$results, 'primarysource', message='No primary source data')
  return(mydf) 
})


#PATIENTREACTION********************************

output$patientreactiontabletitle <- renderText({  
  # s  <- paste('<h4>Safety Report ID=', getreportid(), '<br> <br>Reactions</h4>' )
  updateTextInput(session, "safetyreportid", value = getreportid())
  return(  )
})

output$patientreaction <- renderTable({  
  mydf <- getquery()
  mydf <- getdf( mydf=mydf$patientdf, 'reaction', message='No primary source data')
  
  drop<-c("reactionmeddraversionpt")
  mydf <- mydf[,!(names(mydf) %in% drop)]
  if (!is.atomic(mydf)){
    if ( !is.null(mydf$reactionoutcome) ) {
      myreactionout <- mydf$reactionoutcome
      myreactionout <- gsub(1, 'Recovered/Resolved', myreactionout, fixed=TRUE )
      myreactionout <- gsub(2, 'Recovering/Resolving', myreactionout, fixed=TRUE )
      myreactionout <- gsub(3, 'Not recovered/Not resolved', myreactionout, fixed=TRUE )
      myreactionout <- gsub(4, 'Recovered/Resolved with sequelae', myreactionout, fixed=TRUE )
      myreactionout <- gsub(5, 'Fatal', myreactionout, fixed=TRUE )
      myreactionout <- gsub(6, 'Unknown', myreactionout, fixed=TRUE )
      drop<-c("reactionoutcome")
      mydf <- mydf[,!(names(mydf) %in% drop)]
      mydf <- data.frame(Reaction=mydf, Reaction_outcome=myreactionout)
      
    }
  }
  
  if (is.null(colnames(mydf)))
    return (NULL)
  colnames(mydf) = gsub("_", " ",colnames(mydf))
  
  if (!is.null(input$sourcePatientDataframeUI)){
    if (input$sourcePatientDataframeUI){
      write.csv(mydf,paste0(cacheFolder,values$urlQuery$hash,"_patientreaction.csv"))
      
    }
  }
  return(mydf) 
})

#OPENFDA1********************************************
output$patientdrugopenfdatabletitle <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), ' <br><br>Patient.Drug.OpenFDA_1</h4>' )
  return( s )
})

output$openfda <- renderTable({  
  mynames <- getallvars( allvars(), mytype = 'text', section= c('of'))
   mydf <- getquery()
  openfdadf <- mydf$openfdadf
#  browser()
  if (!is.null(input$sourceFdaDataframeUI)){
    if (input$sourceFdaDataframeUI){
      write.csv(openfdadf,paste0(cacheFolder,values$urlQuery$hash,"_openfda.csv"))
      
    }
  }
  if (is.null( names(openfdadf ) ) ) {
    return( data.frame(note='No OpenFDA variables for this report'))
  }
  if( is.data.frame(openfdadf) ) {
    return( ( openfdadf[names(openfdadf) %in% mynames] )  )
    } else {
      return( data.frame(note='No OpenFDA variables'))
    }
 
})

#OpenFDA2****************************
output$patientdrugopenfda2tabletitle <- renderText({  
  s  <- '<h4><br>Patient.Drug.OpenFDA_2 </h4>' 
  return( s )
})

output$openfda2 <- renderTable({  
  mynames <- getallvars( allvars(), mytype = 'text', section= c('o2'))
  mydf <- getquery()
  openfdadf <- mydf$openfdadf
  # if (!is.null(input$sourceFdaSDataframeUI)){
  #   if (input$sourceFdaSDataframeUI){
  #     write.csv(openfdadf,paste0(cacheFolder,values$urlQuery$hash,"_openfda2.csv"))
  #     
  #   }
  # }
  if (is.null( names(openfdadf ))) {
    return( data.frame(note='No OpenFDA variables for this report'))
  }
  if( is.data.frame(openfdadf) ) {
    return( ( openfdadf[names(openfdadf) %in% mynames] )  )
  } else {
    return( data.frame(note='No OpenFDA variables'))
  }
})

#PATIENT**************************
output$patienttabletitle <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<br><br>Patient</h4>' )
  return( s )
})

output$patient <- renderTable({  
   mynames <- getallvars( allvars(), mytype = 'text', section= c('pt', 'p2'))
  mydf <- getquery()
  patientdf <-  mydf$patientdf
  if ( !is.null( mydf$summarydf) )
    {
    patientdf <- data.frame( mydf$patientdf,  mydf$summarydf )
    }
  if (length(patientdf)==0 ) {
    return( data.frame(note='No patient variables for this report'))
  }
  if( is.data.frame(patientdf) ) {
    return( ( ( patientdf[names(patientdf) %in% mynames] ) )  )
  } else {
    return( data.frame(note='No patient variables'))
  }

})

#DRUG*********************************************
output$patientdrugtabletitle <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<h4><br>Drugs' )
  return( s )
})

output$drug <- renderTable({  
  mydf <- getquery()
  tmp <- mydf$drugdf
  openfdadf <- mydf$openfdadf
  types <- (sapply(tmp, class))
  typesval <- types[types!='data.frame' & types!='list']
  mydf <- tmp[ , names(typesval) ]
  mydrugs2 <- ( tmp$activesubstance$activesubstancename )
  if( length(mydrugs2) < nrow(mydf) )
  {
    mydrugs2 <- vector('character', length=nrow(mydf))
  }
  # browser()
  
 

  drop<-c("drugenddateformat","drugstartdateformat",
          "drugauthorizationnumb","drugbatchnumb")
  mydf <- mydf[,!(names(mydf) %in% drop)]
  
  
 
  
  mycharacterization <- mydf$drugcharacterization
  mycharacterization <- gsub(1, 'SUSPECT DRUG', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(2, 'CONCOMITANT DRUG', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(3, 'INTERACTING DRUG', mycharacterization, fixed=TRUE )
  
  if ( !is.null(mydf$actiondrug) ) {
  myactiondrug <- mydf$actiondrug
  myactiondrug <- gsub(1, 'DRUG WITHDRAWN', myactiondrug, fixed=TRUE )
  myactiondrug <- gsub(2, 'DOSE REDUCED', myactiondrug, fixed=TRUE )
  myactiondrug <- gsub(3, 'DOSE INCREASED', myactiondrug, fixed=TRUE )
  myactiondrug <- gsub(4, 'DOSE NOT CHANGED', myactiondrug, fixed=TRUE )
  myactiondrug <- gsub(5, 'UNKNOWN', myactiondrug, fixed=TRUE )
  myactiondrug <- gsub(6, 'NOT APPLICABLE', myactiondrug, fixed=TRUE )
  drop<-c("drugcharacterization", "actiondrug")
  mydf <- mydf[,!(names(mydf) %in% drop)]
  mydf <- data.frame(activesubstance=mydrugs2, Product_Role=mycharacterization,
                     Medication = myactiondrug,mydf)
  
  } else {
    drop<-c("drugcharacterization")
    mydf <- mydf[,!(names(mydf) %in% drop)]
    mydf <- data.frame(activesubstance=mydrugs2, Product_Role=mycharacterization,
                     mydf)
  }
  if ( !is.null(mydf$drugintervaldosagedefinition) ) {
    mydosagedefinition <- mydf$drugintervaldosagedefinition
    mydosagedefinition <- gsub(801, 'YEAR', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(802, 'MONTH', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(803, 'WEEK', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(804, 'DAY', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(805, 'HOUR', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(806, 'MINUTE', mydosagedefinition, fixed=TRUE )
    
    drop<-c("drugintervaldosagedefinition")
    mydf <- mydf[,!(names(mydf) %in% drop)]
    mydf <- data.frame(mydf, Dosage_Definition = mydosagedefinition)
  } 
  
  
  mynames <- names(mydf)
  mynames <- gsub('medicinalproduct', 'Product_name', mynames, fixed=TRUE )
  mynames <- gsub('activesubstance', 'Active_Substance', mynames, fixed=TRUE )
  mynames <- gsub('drugdosageform', 'Pharmaceutical_Form', mynames, fixed=TRUE )
  mynames <- gsub('drugindication', 'Indication', mynames, fixed=TRUE )
  mynames <- gsub('drugadministrationroute', 'Route', mynames, fixed=TRUE )
  mynames <- gsub('drugdosagetext', 'Dosage-Frequency', mynames, fixed=TRUE )
  mynames <- gsub('drugstartdate', 'Start_Date', mynames, fixed=TRUE )
  mynames <- gsub('drugenddate', 'End_Date', mynames, fixed=TRUE )
  mynames <- gsub('drugstructuredosagenumb', 'Dosage_MG', mynames, fixed=TRUE )
  names(mydf) <- mynames
  
  if (!is.null(openfdadf)){
    mydf[ , 'Route'] <- openfdadf$route
  }
  

  mydf <- mydf %>% select(any_of(c('Active_Substance', 'Product_Role', 'Product_name', 
                                   'Dosage_MG', 'Route', 'Pharmaceutical_Form')))
  
  # mydf<-mydf[!(mydf$Product_Role=="CONCOMITANT DRUG" | mydf$Product_Role=="INTERACTING DRUG"),]
  
  mydf<- data.frame(lapply(mydf, function(v) {
    if (is.character(v)) return(str_to_title(v))
    else return(v)
  }))
  
  colnames(mydf) = gsub("_", " ",colnames(mydf))
  
  if (!is.null(input$sourceDrugDataframeUI)){
    if (input$sourceDrugDataframeUI){
      write.csv(mydf,paste0(cacheFolder,values$urlQuery$hash,"_patdrug.csv"))
      
    }
  }
  
  
  mydf[is.na(mydf)] <- ""
  # browser()
  # tmydf <- t(mydf)
  # rownames(tmydf) <- names(mydf)
  return(mydf) 
})

output$medication <- renderTable({  
  mydf <- getquery()
  tmp <- mydf$drugdf
  openfdadf <- mydf$openfdadf
  types <- (sapply(tmp, class))
  typesval <- types[types!='data.frame' & types!='list']
  mydf <- tmp[ , names(typesval) ]
  mydrugs2 <- ( tmp$activesubstance$activesubstancename )
  if( length(mydrugs2) < nrow(mydf) )
  {
    mydrugs2 <- vector('character', length=nrow(mydf))
  }
  

  # if ('drugstartdate' %in% names(mydf))
  # {
  #   if (any(mydf$drugstartdateformat== '102')){
  #     mydf[ , 'drugstartdate'] <- ymd(mydf[ , 'drugstartdate'])
  #     mydf[ , 'drugstartdate'] <- format(mydf[ , 'drugstartdate'], "%y/%m/%d")
  #   } else if (any(mydf$drugstartdateformat== '610')){
  #     mydf[ , 'drugstartdate'] <- ymd(mydf[ , 'drugstartdate'])
  #     mydf[ , 'drugstartdate'] <- format(mydf[ , 'drugstartdate'], "%y/%m")
  #   }
  # }
  # 
  # if ('drugenddate' %in% names(mydf))
  # {
  # 
  #   if (any(mydf$drugenddateformat == '102')){
  #     mydf[ , 'drugenddate'] <- ymd(mydf[ , 'drugenddate'])
  #     mydf[ , 'drugenddate'] <- format(mydf[ , 'drugenddate'], "%y/%m/%d")
  #   } else if (any(mydf$drugenddateformat == '610')){
  #     mydf[ , 'drugenddate'] <- ymd(mydf[ , 'drugenddate'])
  #     mydf[ , 'drugenddate'] <- format(mydf[ , 'drugenddate'], "%y/%m")
  #   }
  # 
  # }
  

if ('drugstartdate' %in% names(mydf))
{
  startDateInd<-which(names(mydf)%in% 'drugstartdate' )
  startDateTypeInd<-which(names(mydf)%in% 'drugstartdateformat' )
  mydf[ , 'drugstartdate']<-apply(mydf,1,function(x) fixDate(x[startDateInd],x[startDateTypeInd]))
}
if ('drugenddate' %in% names(mydf))
{
  endDateInd<-which(names(mydf)%in% 'drugenddate' ) 
  endDateTypeInd<-which(names(mydf)%in% 'drugenddateformat' )
  mydf[ , 'drugenddate']<-apply(mydf,1,function(x) fixDate(x[endDateInd],x[endDateTypeInd]))
}
  
  
  
  drop<-c("drugenddateformat","drugstartdateformat",
          "drugauthorizationnumb","drugbatchnumb")
  mydf <- mydf[,!(names(mydf) %in% drop)]
  
  
  
  
  mycharacterization <- mydf$drugcharacterization
  mycharacterization <- gsub(1, 'SUSPECT DRUG', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(2, 'CONCOMITANT DRUG', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(3, 'INTERACTING DRUG', mycharacterization, fixed=TRUE )
  
  if ( !is.null(mydf$actiondrug) ) {
    myactiondrug <- mydf$actiondrug
    myactiondrug <- gsub(1, 'DRUG WITHDRAWN', myactiondrug, fixed=TRUE )
    myactiondrug <- gsub(2, 'DOSE REDUCED', myactiondrug, fixed=TRUE )
    myactiondrug <- gsub(3, 'DOSE INCREASED', myactiondrug, fixed=TRUE )
    myactiondrug <- gsub(4, 'DOSE NOT CHANGED', myactiondrug, fixed=TRUE )
    myactiondrug <- gsub(5, 'UNKNOWN', myactiondrug, fixed=TRUE )
    myactiondrug <- gsub(6, 'NOT APPLICABLE', myactiondrug, fixed=TRUE )
    drop<-c("drugcharacterization", "actiondrug")
    mydf <- mydf[,!(names(mydf) %in% drop)]
    mydf <- data.frame(activesubstance=mydrugs2, Product_Role=mycharacterization,
                       Medication = myactiondrug,mydf)
    
  } else {
    drop<-c("drugcharacterization")
    mydf <- mydf[,!(names(mydf) %in% drop)]
    mydf <- data.frame(activesubstance=mydrugs2, Product_Role=mycharacterization,
                       mydf)
  }
  if ( !is.null(mydf$drugintervaldosagedefinition) ) {
    mydosagedefinition <- mydf$drugintervaldosagedefinition
    mydosagedefinition <- gsub(801, 'YEAR', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(802, 'MONTH', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(803, 'WEEK', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(804, 'DAY', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(805, 'HOUR', mydosagedefinition, fixed=TRUE )
    mydosagedefinition <- gsub(806, 'MINUTE', mydosagedefinition, fixed=TRUE )
    
    drop<-c("drugintervaldosagedefinition")
    mydf <- mydf[,!(names(mydf) %in% drop)]
    mydf <- data.frame(mydf, Dosage_Definition = mydosagedefinition)
  } 
  
  
  mynames <- names(mydf)
  mynames <- gsub('medicinalproduct', 'Product_name', mynames, fixed=TRUE )
  mynames <- gsub('drugindication', 'Indication', mynames, fixed=TRUE )
  mynames <- gsub('drugdosagetext', 'Dosage_Frequency', mynames, fixed=TRUE )
  mynames <- gsub('drugstartdate', 'Start_Date', mynames, fixed=TRUE )
  mynames <- gsub('drugenddate', 'End_Date', mynames, fixed=TRUE )

  names(mydf) <- mynames
  
  # mydf<-mydf[!(mydf$Product_Role=="CONCOMITANT DRUG" | mydf$Product_Role=="INTERACTING DRUG"),]
  
  mydf <- mydf %>% select(any_of(c('Product_name', 'Medication', 'Indication', 
                          'Start_Date', 'End_Date', 'Dosage_Frequency', 
                          'Dosage_Definition')))
  
  # 'drugstructuredosageunit',
  # 'drugseparatedosagenumb', 'drugintervaldosageunitnumb',
  # 'drugadditional'
  
  mydf<- data.frame(lapply(mydf, function(v) {
    if (is.character(v)) return(str_to_title(v))
    else return(v)
  }))
  
  colnames(mydf) = gsub("_", " ",colnames(mydf))
  
  if (!is.null(input$sourceFdaDataframeUI)){
    if (input$sourceFdaDataframeUI){
      write.csv(mydf,paste0(cacheFolder,values$urlQuery$hash,"_medication.csv"))
      
    }
  }
  mydf[is.na(mydf)] <- ""
  # browser()
  if (ncol(mydf)==0){
    empty_message <- "There is not medication information in the report"
    mydf <-  data.frame(Message=empty_message)
  }
  
  
  # browser()
  # tmydf <- t(mydf)
  # rownames(tmydf) <- names(mydf)
  return(mydf) 
})

output$downloadData <- downloadHandler(
  filename = function() {
    paste(getreportid(), ".xlsx", sep = "")
  },
  content = function(file) {
    
    mydf <- getquery()
    tmp <- mydf$drugdf
    openfdadf <- mydf$openfdadf
    types <- (sapply(tmp, class))
    typesval <- types[types!='data.frame' & types!='list']
    mydf_drug <- tmp[ , names(typesval) ]
    mydf_reaction <- getdf( mydf=mydf$patientdf, 'reaction', message='No primary source data')
    
    # browser()
    if ( is.data.frame(mydf$df$results$patient) )
    {
      mydf <- (mydf$df$results$patient)    
      types <- (sapply(mydf, class))
      typesval <- types[types!='data.frame' & types!='list']
      mydfpatient <- mydf[ , names(typesval) ]
      myvars <- c( 'patientonsetage', 'patientweight','patientsex' )
      availnames <-  myvars %in% names(mydfpatient)
      mydfpatient <- mydf[ , myvars[availnames] ]
      mynames <- names(mydfpatient)
      mynames <- gsub('patientonsetage', 'Age', mynames, fixed=TRUE )
      mynames <- gsub('patientweight', 'Weight', mynames, fixed=TRUE )
      mynames <- gsub('patientsex', 'Gender', mynames, fixed=TRUE )
      names(mydfpatient) <- mynames
    }
    
    if ('Gender' %in% names(mydfpatient))
    { 
      mydfpatient[ mydfpatient[,'Gender']==2 , 'Gender'] <- 'Female' 
      mydfpatient[ mydfpatient[,'Gender']==1 , 'Gender'] <- 'Male' 
      mydfpatient[ mydfpatient[,'Gender']==0 , 'Gender'] <- 'Unknown' 
    }

    
    Patient <- c('Gender', 'Age', 'Weight')
    if ( is.null(mydfpatient$Weight)){
      mydfpatient$Weight <- "UNKNOWN"
    }
    if ( is.null(mydfpatient$Age)){
      mydfpatient$Age <- "UNKNOWN"
    }
    if ( is.null(mydfpatient$Gender)){
      mydfpatient$Gender <- "UNKNOWN"
    }
    
    Description <- c(mydfpatient$Gender, mydfpatient$Age, mydfpatient$Weight)
    mydf_p <- data.frame(Patient, Description)
    
    # browser()
    # write_csv(getquery()$df$result, file)
    # filename = paste(getreportid(), ".xlsx", sep = "")
    write.xlsx(getquery()$df$result, file=file, sheetName="general")
    write.xlsx(mydf_p, file=file, sheetName="patient", append=TRUE)
    write.xlsx(mydf_drug, file=file, sheetName="drug", append=TRUE)
    write.xlsx(mydf_reaction, file=file, sheetName="reaction", append=TRUE)
    write.xlsx(getquery()$openfdadf, file=file, sheetName="openfda", append=TRUE, row.names=FALSE)
    }
  
)


output$sourceFdaDataframe<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceFdaDataframeUI", "Save data values")
})

observeEvent(input$sourceFdaDataframeUI,{
  
  if (!is.null(input$sourceFdaDataframeUI))
    if (!input$sourceFdaDataframeUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_medication.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

# output$sourceFdaSDataframe<-renderUI({
#   if (!is.null(values$urlQuery$hash))
#     checkboxInput("sourceFdaSDataframeUI", "Save OpenFDA_2 values")
# })
# 
# observeEvent(input$sourceFdaSDataframeUI,{
#   
#   if (!is.null(input$sourceFdaSDataframeUI))
#     if (!input$sourceFdaSDataframeUI){
#       fileName<-paste0(cacheFolder,values$urlQuery$hash,"_openfda2.csv")
#       if (file.exists(fileName)) {
#         #Delete file if it exists
#         file.remove(fileName)
#       }
#     }
# })


output$sourceDrugDataframe<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceDrugDataframeUI", "Save data values")
})

observeEvent(input$sourceDrugDataframeUI,{
  
  if (!is.null(input$sourceDrugDataframeUI))
    if (!input$sourceDrugDataframeUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_patdrug.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})


output$sourceReportframe<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceReportframeUI", "Save data values")
})

observeEvent(input$sourceReportframeUI,{
  
  if (!is.null(input$sourceReportframeUI))
    if (!input$sourceReportframeUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_report.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})


output$sourcePatientDataframe<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourcePatientDataframeUI", "Save data values")
})

observeEvent(input$sourcePatientDataframeUI,{
  
  if (!is.null(input$sourcePatientDataframeUI))
    if (!input$sourcePatientDataframeUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_patientreaction.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

#META**************************
output$querytitle <- renderText({ 
  return( paste('<h4>Meta Data and Query </h4><br><h4>Safety Report ID=', getreportid(), '</h4><br>' ))
})
output$metatext <- renderText({ 
   mydf <- getfullquery()
   mydf2 <- getquery()
#    "meta": {
#      "disclaimer": "openFDA is a beta research project and not for clinical use. While we make every effort to ensure that data is accurate, you should assume all results are unvalidated.",
#      "license": "http://open.fda.gov/license",
#      "last_updated": "2014-08-01",
#      "results": {
#        "skip": 0,
#        "limit": 1,
#        "total": 1355
#print(mydf)
link <- paste0('<a href="', ( mydf$url ), '">', removekey( mydf$url ), '</a>')
#print(link)
myurl <- mydf2$url
out <- paste(
  'Disclaimer = ', mydf$df.meta$disclaimer, 
  '<br>License = ', mydf$df.meta$license, 
  '<br>Last Update=', mydf$df.meta$last_updated, 
  '<br>Total=', mydf$df.meta$results$total, 
  '<br> Limit=', mydf$df.meta$results$limit, 
  '<br> Skip=', mydf$df.meta$results$skip, 
  '<br> Error=', mydf$df.meta$error, 
      '<br> URL =', removekey( makelink(myurl) ), 
 '<BR><BR><b>JSON Output = </b><BR>'
  )
 return(out)
  })

output$json <- renderText({ 
  myurl <- getquery()$url
  out <- getjson( myurl )
  return( out )
})



output$date1 <- renderText({ 
  l <- getdaterange()
  paste( '<b>', l[3] ,'from', as.Date(l[1],  "%Y%m%d")  ,'to', as.Date(l[2],  "%Y%m%d"), '</b>')
})


output$reportid <- renderUI({
  p( paste('Safety Report ID=', getreportid() ) )
})

output$currec <- renderUI({ 
  mydf <- getfullquery()
  q <- geturlquery()
  if (q$concomitant == FALSE){
    numrecs <- mydf$df.total
  } else {
    numrecs <- mydf$df.meta$results$total 
  }
  maxlim <- getopenfdamaxrecords( numrecs )
  updateSliderInput( session, 'skip', value=getskip()+1, min=1, step= 1, max=maxlim)
  out <- paste( i18n()$t('Viewing #'), getskip()+1, i18n()$t('of'), numrecs, i18n()$t('selected reports'))
  return(out)
})

getcururl <- reactive({
  mypath <- extractbaseurl( session$clientData$url_pathname )
  s <- paste0( session$clientData$url_protocol, "//", session$clientData$url_hostname,
               ':',
               session$clientData$url_port,
               mypath )
  
  return(s)
})

output$applinks <- renderText({ 
  return( makeapplinks(  getcururl() )  )
})


geturlquery <- reactive({
   q <- parseQueryString(session$clientData$url_search)
   # q<-NULL
   # q$v1<-"patient.drug.openfda.generic_name"
   # q$v2<-"patient.reaction.reactionmeddrapt"
   # q$t1<-"Omeprazole"
   # q$t2<-"Hypokalaemia"
   # q$t1<-"D10AD04"
   # q$t2<-"10012378"
   # q$hash <- "ksjdhfksdhfhsk"
   # q$concomitant <- TRUE
   updateTabsetPanel(session, 'maintabs', selected=q$curtab)
   
   
    t1 <- gsub('"[', '[', q$t1, fixed=TRUE)
    t1 <- gsub(']"', ']', t1, fixed=TRUE)
    t1 <- gsub('""', '"', t1, fixed=TRUE)
    updateTextInput(session, "t1", value = t1)
    updateTextInput(session, "t1_2", value = t1)
  
  t2 <- gsub('"[', '[', q$t2, fixed=TRUE)
  t2 <- gsub(']"', ']', t2, fixed=TRUE)
  t2 <- gsub('""', '"', t2, fixed=TRUE)
  updateTextInput(session, "t2", value = t2)
  updateTextInput(session, "t2_2", value = t2)
  
  if(!is.null(q$t3) )
  {  
  t3 <- gsub('"[', '[', q$t3, fixed=TRUE)
  t3 <- gsub(']"', ']', t3, fixed=TRUE)
  t3 <- gsub('""', '"', t3, fixed=TRUE)
  updateTextInput(session, "t3", value = t3)
  updateTextInput(session, "t3_2", value = t3)
  }
  

if(!is.null(q$v1) )
  {
  v1 <- gsub('"', '', q$v1, fixed=TRUE)
  updateSelectizeInput(session, inputId = "v1", selected = v1)
  updateSelectizeInput(session, inputId = "v1_2", selected = v1)
} 
if(!is.null(q$v2) )
  {
  v2 <- gsub('"', '', q$v2, fixed=TRUE)
  updateSelectizeInput(session, inputId = "v2", selected = v2)
  updateSelectizeInput(session, inputId = "v2_2", selected = v2)
  }
if(!is.null(q$v3) )
  { 
  v3 <- gsub('"', '', q$v3, fixed=TRUE)
  updateSelectizeInput(session, inputId = "v3", selected = v3)
  updateSelectizeInput(session, inputId = "v3_2", selected = v3)
  }
#   
#   updateNumericInput(session, "skip", value = q$skip)
#   return(q)
  if (q$v1=="patient.drug.openfda.generic_name"){
    con_atc <- mongo("atc", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    drug <- con_atc$find(paste0('{"code" : "',q$t1,'"}'))
    con_atc$disconnect()
    
    q$dename <- drug$names[[1]][1]
    if (!is.null(q$v2)){
      
      con_medra <- mongo("medra", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      event <- con_medra$find(paste0('{"code" : "',q$t2,'"}'))
      con_medra$disconnect()
      
      q$ename <- event$names[[1]][1]
      
    }
  } else {
    con_medra <- mongo("medra", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    event <- con_medra$find(paste0('{"code" : "',q$t1,'"}'))
    con_medra$disconnect()
    
    q$dename <- event$names[[1]][1]
  }
  values$urlQuery<-q
})


})



fixDate<-function(dd,type){
  tempDD<-dd
  if (!is.na(type))
    if (type=="102"){
      tempDD <- format(ymd(dd), "%y/%m/%d")
    }
    else if (type== '610'){
      tempDD <- format(ym(dd), "%y/%m")
    }
  
return(tempDD)
}










