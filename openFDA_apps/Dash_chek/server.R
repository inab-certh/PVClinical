library(plotly)
require(shiny)
require(shinyBS)
library(shiny.i18n)
translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')

if (!require('openfda') ) {
  devtools::install_github("ropenhealth/openfda")
  library(openfda)
  print('loaded open FDA')
}
library(xlsx)
library(ggplot2)

source('sourcedir.R')



#*****************************************************
shinyServer(function(input, output, session) {
  
  cacheFolder<-"C:/Users/axill/Documents/shinycache/"
  
  values<-reactiveValues(urlQuery=NULL)
  values<-reactiveValues(cred=fromJSON("credentials.json"))
  
  output$page_content <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    selectedLang = tail(query[['lang']], 1)
    if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
    {
      selectedLang='en'
    }
    
    selectInput('selected_language',
                i18n()$t("Change language"),
                choices = c("en","gr"),
                selected = selectedLang)
    
  })

  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    selectedLang = tail(query[['lang']], 1)
    if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
    {
      selectedLang='en'
    }
    translator$set_translation_language(selectedLang)
    
  })
  

  getdrugname <- reactive({ 

    s <- toupper(values$urlQuery$t1)
    if  (is.null(s) | s=="" ) {
      return("")
    }
    names <- s
    names <- paste0(names, collapse=' ')
    return(names)
  })
  

  
  getquoteddrugname <- reactive({ 
    s <- getdrugname()
    if  (is.null( s ) | s=="" ) {
      return("")
    }
    names <- paste0('"', s, '"')
    names <- paste0(names, collapse=' ')
    return(names)
  })
  
  output$t1 <- renderPrint({ 
    return( getdrugname() )
  })
  
  getdrugvarname <- reactive({ 
    return(values$urlQuery$v1)
  })
  
  getexactdrugvarname <- reactive({ 
    return( paste0(values$urlQuery$v1, '.exact') )
  })
  
  getbestdrugvarname <- function(){
 
    exact <-   TRUE
    if (exact){
      return( getexactdrugvarname() )
    } else {
      return( getdrugvarname() )
    }
  }
  
  getbestdrugname <- function(quote=TRUE){
    exact <-   TRUE
    if (exact)
    {
      return( getquoteddrugname() )
    } else {
      return( getdrugname() )
    }
  }
  
  geteventvarname <- reactive({ 
      return(   "patient.reaction.reactionmeddrapt.exact" )
  })
  
  
  fixInput <- reactive({
    
    updateTextInput(session, "t1", value= (input$t1) )
  })
  
  updatevars <- reactive({
    input$update
    isolate( {
      updateTextInput(session, "t1", value=( input$drugname ) )
    })
  })
  

  #************************************
  # Get Seriuosness Query
  #*********************
  
  getseriouscounts <- reactive({
    
#     "seriousnesscongenitalanomali": "1",
#     "seriousnessdeath": "1",
#     "seriousnessdisabling": "1"
#     "seriousnesshospitalization": "1",
#     "seriousnesslifethreatening": "1",
#     "seriousnessother": "1",

    
    # Refactor
    q<-values$urlQuery
    con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
    drugName<-q$t1

    congAnomQuery<-createQuery(drugName=drugName,seriousnesscongenitalanomali="1")
    conganom <- con$count(congAnomQuery)

    deathQuery<-createQuery(drugName=drugName,seriousnessdeath="1")
    death <- con$count(deathQuery)

    disableQuery<-createQuery(drugName=drugName,seriousnessdisabling="1")
    disable <- con$count(disableQuery)

    hospQuery<-createQuery(drugName=drugName,seriousnesshospitalization="1")
    hosp <- con$count(hospQuery)

    lifethreatQuery<-createQuery(drugName=drugName,seriousnesslifethreatening="1")
    lifethreat <- con$count(lifethreatQuery)

    otherQuery<-createQuery(drugName=drugName,seriousnessother="1")
    other <- con$count(otherQuery)
    
    con$disconnect()

    seriousDF<-data.frame(c(i18n()$t("Congenital Anomaly"), i18n()$t("Death"), i18n()$t("Disability"), i18n()$t("Hospitalization"),
                 i18n()$t("Life Threatening"), i18n()$t("Other")),c(conganom, death, disable, hosp, lifethreat, other))
    colnames(seriousDF)<-c("term","count")
    
    seriousDF <- seriousDF[order(seriousDF[,2]), ]
    return(seriousDF)
    # ReDone

  })    
  
#************************************
# Get Sex Query
#*********************

getsexcounts <- reactive({
  
  # Refactor
  q<-values$urlQuery
  
  con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
  drugName<-q$t1
  

  sexQuery<-createSexQuery(drugName=drugName)
  sexResult<-con$aggregate(sexQuery)
  con$disconnect()
  colnames(sexResult)[1]<-"term"
  

  sexID<-c(i18n()$t("Unknown"),i18n()$t("Male"),i18n()$t("Female"))
  sexResult$term<-sexID[as.numeric(sexResult$term)+1]
  sexResult <- sexResult[order(sexResult[,2]), ]
  
  return( sexResult )
  
  # ReDone
})    
#************************************
# Get source Query
#*********************

getsourcecounts <- reactive({
#   1 = Physician
#   2 = Pharmacist
#   3 = Other Health Professional
#   4 = Lawyer
#   5 = Consumer or non-health professional
  
  # Refactor
  q<-values$urlQuery
  
  con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
  drugName<-q$t1
  
  
  qualificationQuery<-createQualificationQuery(drugName=drugName)
  qualResult<-con$aggregate(qualificationQuery)
  con$disconnect()
  colnames(qualResult)[1]<-"term"
  
  qualID<-c(i18n()$t("Physician"),i18n()$t("Pharmacist"),i18n()$t("Other Health Professional"),i18n()$t("Lawyer"),i18n()$t("Consumer or non-health..."))
  qualResult$term<-qualID[as.numeric(qualResult$term)]
  qualResult <- qualResult[order(qualResult[,2]), ]
  
  

  return( qualResult )
  # ReDone
})    

  #************************************
  # Get Drug-Event Query
  #*********************
  


#**************************
# Concomitant drug table
getcocounts <- reactive({
  geturlquery()
  q<-values$urlQuery
  if ( is.null( getdrugname() ) ){
    return(data.frame( c(paste('Please enter a drug name'), '') ) )
  }

  # Refactor
  con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
  drugName<-q$t1
  
  drugQuery<-createConDrugQuery(drugName=drugName)
  drugResult <- con$aggregate(drugQuery)
  con$disconnect()
  
  colnames(drugResult)[1]<-"term"

  mydf<-drugResult
  # Redone
  
  myrows <- min(nrow(mydf), 999)
  mydf <- mydf[1:myrows,]


  return( list( mydf=mydf ) )
})     

#Indication table
getindcounts <- reactive({
  geturlquery()
  q<-values$urlQuery
  if ( is.null( getdrugname() ) ){
    return(data.frame( c(paste('Please enter a', getsearchtype(), 'name'), '') ) )
  }

  
  # Refactor
  con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
  drugName<-q$t1
  
  drugIndicationQuery<-createDrugIndicationgQuery(drugName=drugName)
  drugIndicationResult <- con$aggregate(drugIndicationQuery)
  con$disconnect()
  
  colnames(drugIndicationResult)[1]<-"term"

  mydf<-drugIndicationResult
  # Redone

  myrows <- min(nrow(mydf), 999)
  mydf <- mydf[1:myrows,]
  mydf <- mydf[!is.na(mydf[,2]), ]
  sourcedf <- mydf

  
  return( list( mydf=mydf, sourcedf=sourcedf ) )
})   

#  
  #Get total counts in database for each event and Total reports in database
  gettotals<- reactive({

    q<-values$urlQuery
    
    # Refactor
    con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
    drugName<-q$t1
    total<-con$count()
    drugQuery<-createQuery(drugName=drugName)
    totaldrug<-con$count(drugQuery)
    con$disconnect()
    # Redone
    
    
    adjust <- total/totaldrug
    out <- list(total=total, totaldrug=totaldrug, adjust=adjust )
  }) 
  
  output$downloadDataLbl <- renderText({
    return(i18n()$t("Download Data in Excel format"))
  })
  
  output$downloadBtnLbl <- renderText({
    return(i18n()$t("Download"))
  })
  

#
#Setters ==============
#

  
output$serious <- renderTable({ 
  mydf <- getseriouscounts()
  if ( is.data.frame(mydf) )
  {
    names(mydf) <- c('Serious', 'Case Counts' )
    mysum <- sum( mydf[,'Case Counts'] )
#    browser()
    mydf <- data.frame(mydf, percent =  100*mydf[,'Case Counts']/mysum )
    names(mydf) <- c('Serious', 'Case Counts', '%' )
    mydf[,'Case Counts'] <- prettyNum( mydf[,'Case Counts'], big.mark=',' )
    mydf[,'%'] <- paste0( format( mydf[,'%'], big.mark=',', digits=2, width=4 ), '%' )
    return(mydf) 
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
}, height=300, align=c("rllr"), sanitize.text.function = function(x) x)  


output$seriousplot <- renderPlotly({ 
  if(getterm1( session)!=""){
  mydf <- getseriouscounts()
  seriousForExcel<<-mydf
  if ( is.data.frame(mydf) )
  {
    names(mydf) <- c('Serious', 'Case Counts' )
    # return( dotchart(mydf[,2], labels=mydf[,1], main=i18n()$t("Seriousness")) ) 
    fig <- plot_ly(
      title = i18n()$t("Seriousness"),
      x = mydf[,1],
      y = mydf[,2],
      name = "SF Zoo",
      type = "bar"
    )%>% layout(title=i18n()$t("Seriousness"),height = 300,autosize = F)
    
    fig
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
  }
  else{
    # s1 <- calccpmean()
    geturlquery()
    q<-values$urlQuery
    return (NULL)
  }
})  

output$seriouspie <- renderPlot({ 
  mydf <- getseriouscounts()
  if ( is.data.frame(mydf) )
  {
    names(mydf) <- c('Serious', 'Case Counts' )
    return( pie(mydf[,2], labels=mydf[,1], main=i18n()$t("Seriousness")) ) 
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
})  
output$sex <- renderTable({ 
  mydf <- getsexcounts()
  if ( is.data.frame(mydf) )
  {
    names(mydf) <- c('Gender', 'Case Counts', 'Code' )
    mysum <- sum( mydf[,'Case Counts'] )
    #    browser()
    mydf <- data.frame(mydf, percent =  100*mydf[,'Case Counts']/mysum )
    names(mydf) <- c('Serious', 'Case Counts', 'Code', '%' )
    mydf[,'Case Counts'] <- prettyNum( mydf[,'Case Counts'], big.mark=',' )
    mydf[,'%'] <- paste0( format( mydf[,'%'], big.mark=',', digits=2, width=4 ), '%' )
    return(mydf) 
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
}, height=300, align=c("rlllr"), sanitize.text.function = function(x) x)  

output$sexplot <- renderPlotly({ 
  if(getterm1( session)!=""){
  mydf <- getsexcounts()
  sexForExcel<<-mydf
  if ( is.data.frame(mydf) )
  {
    # names(mydf) <- c('Gender', 'Case Counts', 'Code' )
    # return( dotchart(mydf[,2], labels=mydf[,1], main=i18n()$t("Gender")) ) 
    fig <- plot_ly(
      title = i18n()$t("Gender"),
      x = mydf[,1],
      y = mydf[,2],
      name = "Gender",
      type = "bar"
    )%>% layout(title=i18n()$t("Gender"),height = 300,autosize = F)
    
    fig
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
  }
  else{
    # s1 <- calccpmean()
    geturlquery()
    q<-values$urlQuery
    return (NULL)
  }
} ) 

output$sexpie <- renderPlotly({ 
  mydf <- getsexcounts()
  if ( is.data.frame(mydf) )
  {
    names(mydf) <- c('Gender', 'Case Counts', 'Code' )
    return( pie(mydf[,2], labels=mydf[,1], main=i18n()$t("Gender")) ) 
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
}) 
output$dl <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    indqueryForExcel<-getindcounts()$mydf
    coqueryForExcel<<-getcocounts()$mydf
    write.xlsx(sourceForExcel, file, sheetName="source")
    write.xlsx(seriousForExcel, file, sheetName="serious", append=TRUE)
    write.xlsx(sexForExcel, file, sheetName="sex", append=TRUE)
    write.xlsx(queryForExcel, file, sheetName="query", append=TRUE)
    write.xlsx(coqueryForExcel, file, sheetName="coquery", append=TRUE)
    write.xlsx(indqueryForExcel, file, sheetName="indquery", append=TRUE)
  }
)
output$sourceplot <- renderPlotly({
  if(getterm1( session)!=""){
  mydf <- getsourcecounts()
  sourceForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_dash", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug"), append = FALSE)
    plot.new()
    hide("seriousplot")
    hide("downloadExcelColumn")
    hide("dl")
    hide("daterange")
    hide("sourceplot")
    hide("sexplot")
    hide("maintabs")
    return(NULL)
  }
  # return(dotchart(mydf[,2], labels=mydf[,1], main=i18n()$t("Primary Source Qualifications") ))
  fig <- plot_ly(
    title = i18n()$t("Primary Source Qualifications"),
    x = mydf[,1],
    y = mydf[,2],
    name = "SF Zoo",
    type = "bar"
  )%>% layout(title=i18n()$t("Primary Source Qualifications"),height = 300,autosize = F)
  
  
  if (!is.null(input$sourcePlotReportUI)){
    if (input$sourcePlotReportUI){
      write.csv(iris,paste0(cacheFolder,values$urlQuery$hash,"_iris.csv"))
    }
      

  }
  
  fig
}
else{
  # s1 <- calccpmean()
  geturlquery()
  q<-values$urlQuery
  return (NULL)
}
})

output$sourcepie <- renderPlot({
  mydf <- getsourcecounts()
  return(pie(mydf[,2], labels=mydf[,1], main=i18n()$t("Primary Source Qualifications")) )
})

output$source <- renderTable({ 
  mydf <- getsourcecounts()
  if ( is.data.frame(mydf) )
  {
    names(mydf) <- c('Qualifications', 'Case Counts', 'Code' )
    mysum <- sum( mydf[,'Case Counts'] )
    #    browser()
    mydf <- data.frame(mydf, percent =  100*mydf[,'Case Counts']/mysum )
    names(mydf) <- c('Serious', 'Case Counts', 'Code', '%' )
    mydf[,'Case Counts'] <- prettyNum( mydf[,'Case Counts'], big.mark=',' )
    mydf[,'%'] <- paste0( format( mydf[,'%'], big.mark=',', digits=2, width=4 ), '%' )
    return(mydf) 
  } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
}, height=300, align=c("rlllr"), sanitize.text.function = function(x) x)  




output$query <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'

  q<-values$urlQuery
  
  
  # Refactor
  con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
  drugName<-q$t1

  drugEventQuery<-createDrugEventQuery(drugName=drugName)
  drugEventResult<-con$aggregate(drugEventQuery)
  con$disconnect()
  
  colnames(drugEventResult)[1]<-"term"
  drugEventResult$percents<-round(drugEventResult$count/sum(drugEventResult$count),digits=4)
  # Redone
  

  mydf<-drugEventResult
  
  queryForExcel<<-mydf
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(mydf) )
  {
    mydfIndatatable <- mydf
  } 
#   else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
# })
  else {
    mydfIndatatable<- data.frame(Term=paste( 'No results for', getdrugname() ), Count=0)
    }
  datatable(
    mydfIndatatable,
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr', 
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE,rownames= FALSE)
},
escape=FALSE)




output$queryalldrugtext <- renderText({ 
  l <- gettotals()
  return( 
    paste( '<b>Query:</b>', removekey( makelink(l['totaldrugurl']) ) , '<br>') ) 
})



output$alldrugtext <- renderText({ 
  l <- gettotals()
  return( 
    paste( '<b>Total reports with', getdrugname() , 'in database:</b>', prettyNum( l['totaldrug'], big.mark=','  ), '<br>') )
})



#**********Drugs in reports




output$coquery <- DT::renderDT({
  codrugs <- getcocounts()$mydf

  coqueryForExcel<<-codrugs
  query <- parseQueryString(session$clientData$url_search)
  

  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(codrugs) )
  { 
    codrugsIndataTable<-codrugs
  } else  {
    codrugsIndataTable<- data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  
  datatable(
    codrugsIndataTable,
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1))),
      language = list(
        url = ifelse(selectedLang=='gr', 
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE,rownames= FALSE)
},  escape=FALSE)


#addTooltip(session, 'cocloud', tt('cocloud'), placement='top')
output$cocloud <- renderPlot({  
  codrugs <- getcocounts()$mydf
  if ( is.data.frame(codrugs) )
  { 
    names(codrugs) <- c(i18n()$t("Drug"),  i18n()$t("Counts") )
    mytitle <- paste('Medications in Reports That Contain', getdrugname() )
    return( getcloud(codrugs, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
  }  
  
}, height=900, width=900)



output$indquery <- DT::renderDT({
  codinds <- getindcounts()$mydf
  indqueryForExcel<<-codinds
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(codinds) )
  { 
    codindsIndataTable<-codinds
  } else  {
    codindsIndataTable<- data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  datatable(
    codindsIndataTable,
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1))),
      language = list(
        url = ifelse(selectedLang=='gr', 
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE,rownames= FALSE)
},  escape=FALSE)


output$indcloud <- renderPlot({ 
  
  withProgress( message = 'Progress', {
  codinds <- getindcounts()$sourcedf  } )
  if ( is.data.frame(codinds) )
  { 
    names(codinds) <- c(i18n()$t("Indication"),  i18n()$t("Counts") )
    mytitle <- paste('Indications in Reports That Contain', getdrugname() )
    return( getcloud(codinds, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
    }  

}, height=900, width=900)


geturlquery <- reactive({
  q <- parseQueryString(session$clientData$url_search)
  q$v1<-"patient.drug.openfda.generic_name"
  q$v2<-"patient.reaction.reactionmeddrapt"
  q$t1<-"MORPHINE"
  q$t2<-"Anaemia"
  q$hash<-"d38ghr"
  updateSelectizeInput(session, inputId = "v1", selected = q$v1)
  updateNumericInput(session, "limit", value = q$limit)
  updateSelectizeInput(session, 't1', selected= q$drug) 
  updateSelectizeInput(session, 't1', selected= q$t1) 
  updateSelectizeInput(session, 'drugname', selected= q$t1) 
  updateRadioButtons(session, 'useexact',
                     selected = if(length(q$useexact)==0) "exact" else q$useexact)
  updateRadioButtons(session, 'useexactD',
                     selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
  updateRadioButtons(session, 'useexactE',
                     selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
  
  values$urlQuery<-q
  return(q)
})
createinputs <- reactive({
  q <- parseQueryString(session$clientData$url_search)
#  browser()
  v1 <- 
  t1 <- textInput_p("t1", "Name of Drug", '', 
                     HTML( tt('drugname1') ), tt('drugname2'),
                     placement='bottom')
  useexact <- radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'),
                    selected='any', inline=TRUE)
  drugname <- textInput_p("drugname", "Name of Drug", '', 
                            HTML( tt('drugname1') ), tt('drugname2'),
                            placement='left')
  return( list(v1=v1, t1=t1, useexact=useexact, drugname=drugname))
})
output$v1_in <- renderUI( {
  
  s <- selectInput_p("v1", 'Drug Variable' , getdrugvarchoices(), 
                HTML( tt('drugvar1') ), tt('drugvar2'),
                placement='top')
})
output$t1_in <- renderUI( {
  
  s <- textInput_p("t1", "Name of Drug", 'aspirin', 
                   HTML( tt('drugname1') ), tt('drugname2'),
                   placement='bottom')
})
output$drugname_in <- renderText( {
  
#   s <- textInput_p("drugname", "Name of Drug", 'aspirin', 
#                    HTML( tt('drugname1') ), tt('drugname2'),
#                    placement='left')
  s <- 'aspirin'
})
output$useexact_in <- renderUI( {
  
  s <- radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'),
                    selected='any', inline=TRUE)
})


output$date1 <- renderUI({ 
  l <- getdaterange()
  HTML(paste( '<b>', i18n()$t(l[3]) , i18n()$t("from"), as.Date(l[1],  "%Y%m%d")  ,i18n()$t("to"), as.Date(l[2],  "%Y%m%d"), '</b>'))
})

# Return the components of the URL in a string:
output$urlText <- renderText({
  paste(sep = "",
        "protocol: ", session$clientData$url_protocol, "\n",
        "hostname: ", session$clientData$url_hostname, "\n",
        "pathname: ", session$clientData$url_pathname, "\n",
        "port: ",     session$clientData$url_port,     "\n",
        "search: ",   session$clientData$url_search,   "\n"
  )
  return(getbaseurl('E') )
  
})





output$help <- renderUI({
  #  print('test')
  s <- input$sidetabs
  # print(s)
  out <- switch(s, 
                'Graph Options'=loadhelp('graphoptions'),
                'Data Options'=loadhelp('dataoptions'),
                'Axis Options'=loadhelp('axisoptions'),
                'Select Vars'= loadhelp('selectvars'),
                'Load Data'= loadhelp('loaddata'),
                'Overview'= loadhelp('overview'),
                'Overviewside'= loadhelp('overviewside'),
                'none')
  return( HTML(out[[1]]) )
})
i18n <- reactive({
  selected <- input$selected_language
  if (length(selected) > 0 && selected %in% translator$languages) {
    translator$set_translation_language(selected)
  }
  translator
})

output$dashboard <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Dashboard")))
  
})

output$table <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Table")))
  
})



output$Events <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Events")))
  
})
output$ConcomitantMedications <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Concomitant Medications")))
  
})
output$Indications <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Indications")))
  
})


output$About <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("About")))
  
})



output$sourcePlotReport<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourcePlotReportUI", "Primary Source Qualifications Save",TRUE)
})

observeEvent(input$sourcePlotReportUI,{
  
  if (!is.null(input$sourcePlotReportUI))
  if (!input$sourcePlotReportUI){
    fileName<-paste0(cacheFolder,values$urlQuery$hash,"_iris.csv")
    if (file.exists(fileName)) {
      #Delete file if it exists
      file.remove(fileName)
    }
  }
})




getTranslatedNames <- function(){
  return (c( i18n()$t("Tables"),i18n()$t("Word Cloud")))
}
output$wordcloudtabset <- renderUI({
  wordcloudtabset('eventcloud', 'query', 
                  popheads=c( tt('event1'), tt('word1') ), poptext=c( tt('event2'), tt('word2') ),names=getTranslatedNames())
})

})


function(msg="") {
  list(msg = paste0("The message is: '", msg, "'"))
}
