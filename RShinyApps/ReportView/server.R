require(shiny)
require(lubridate)
if (!require('openfda') ) {
  devtools::install_github("ropenhealth/openfda")
  library(openfda)
}

library(shiny)
library(shiny.i18n)

source('sourcedir.R')


translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')


#**************************************
shinyServer(function(input, output, session) {
  
  i18n <- reactive({
    selected <- input$selected_language
    if (length(selected) > 0 && selected %in% translator$languages) {
      translator$set_translation_language(selected)
    }
    translator
  })
  
  geturlquery <- observe({
    addClass("panel_title", "custom-title")
    # removeClass("panel_title", "shiny-text-output")
    # removeClass("panel_title", "shiny-bound-output")
    q <- parseQueryString(session$clientData$url_search)
    
    selectedLang = tail(q[['lang']], 1)
    if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
    {
      selectedLang='en'
    }
    
    selectInput('selected_language',
                i18n()$t("Change language"),
                choices = c("en","gr"),
                selected = selectedLang)
    langs = list(gr="el", en="en")
    
    translator$set_translation_language(selectedLang)
    
    updateButton(session, 'prevrow', label = paste('<', i18n()$t('Previous Report')), icon = NULL, value = NULL,
                 style = NULL, size = NULL, block = NULL, disabled = NULL)
    updateButton(session, 'nextrow', label = paste(i18n()$t('Next Report'), '>'), icon = NULL, value = NULL,
                 style = NULL, size = NULL, block = NULL, disabled = NULL)
    updateButton(session, 'tabBut', label = paste(i18n()$t('Filter by'), '...'), icon = NULL, value = NULL,
                 style = NULL, size = NULL, block = NULL, disabled = NULL)
    updateButton(session, 'update', label = i18n()$t('Update Variables'), icon = NULL, value = NULL,
                 style = 'primary', size = NULL, block = NULL, disabled = NULL)
    updateButton(session, 'modalCloseBtn', label = i18n()$t('Close'), icon = NULL, value = NULL)
    updateSliderInput(session, 'skip', paste(i18n()$t('Report'),' #'), value=1, min=1, step= 1, max=100)
    
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
    
  })
  
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
  
  output$metadatatxt <- renderText({
    i18n()$t("Meta Data")
  })
  
  output$reportheadertxt <- renderText({
    i18n()$t("Report Header")
  })
  
  output$patienttxt <- renderText({
    i18n()$t("Patient")
  })
  
  output$patreactiontxt <- renderText({
    i18n()$t("Patient.Reaction")
  })
  
  output$patdrugtxt <- renderText({
    i18n()$t("Patient.Drug")
  })
  
  output$patdrugopenfdatxt <- renderText({
    i18n()$t("Patient.Drug.OpenFDA")
  })
  
  # output$closebtnlbl <- renderText({
  #   i18n()$t("Close")
  # })
  

  # #Translated uiOutputs
  # output$title_panel <- renderText({
  #   paste("<h2>", i18n()$t("Drug Adverse Event Report Browser"), "</h2>")
  # })  
   
getskip <- reactive({
  return( input$skip-1 )
})
ntext <- eventReactive( input$nextrow, {
  myskip <- getskip()
  mydf <- getfullquery()
  numrecs <- mydf$df.meta$results$total
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
  myskip <- getskip()
  mydf <- getfullquery()
  numrecs <- mydf$df.meta$results$total
  maxlim <- getopenfdamaxrecords( numrecs )
  updateSliderInput( session, 'skip', value= max(myskip, 1), min=1, step= 1, max=maxlim)
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
  myurl <- buildURL(v1, t1,  limit=1, skip=getskip())

  mydf <- fda_fetch_p(session, myurl)
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
  myurl <- buildURL(v1, t1, limit=1)
  mydf <- fda_fetch_p(session, myurl)
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
  mycharacterization <- gsub(1, 'Suspect drug', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(2, 'Concomitant drug', mycharacterization, fixed=TRUE )
  mycharacterization <- gsub(3, 'Interacting drug', mycharacterization, fixed=TRUE )
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
  return(mydf) 
})

#HEADER**********************
output$headertabletitle <- renderText({  
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<h4><br>Header' )
      return( s )
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
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<br> <br>Patient.Reaction</h4>' )
  return( s )
})

output$patientreaction <- renderTable({  
  mydf <- getquery()
  mydf <- getdf( mydf=mydf$patientdf, 'reaction', message='No primary source data')
 # browser()
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
  s  <- paste('<h4>Safety Report ID=', getreportid(), '<h4><br>Patient.Drug' )
  return( s )
})

output$drug <- renderTable({  
  mydf <- getquery()
  tmp <- mydf$drugdf
  types <- (sapply(tmp, class))
  typesval <- types[types!='data.frame' & types!='list']
  mydf <- tmp[ , names(typesval) ]
  mydrugs2 <- ( tmp$activesubstance$activesubstancename )
  if( length(mydrugs2) < nrow(mydf) )
  {
    mydrugs2 <- vector('character', length=nrow(mydf))
  }
  mydf <- data.frame(activesubstance=mydrugs2, mydf)
  return(mydf) 
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
  numrecs <- mydf$df.meta$results$total
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


geturlquery <- observe({
   q <- parseQueryString(session$clientData$url_search)
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
})


})
