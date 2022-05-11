
require(shiny)
require(shinyBS)
require('lubridate')
require('bcp')
require('changepoint')
require('zoo')
library(shiny.i18n)
# library(tableHTML)

library(xlsx)
library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)
library(ggplot2)
library(htmltools)
library(magrittr)
library(pins)
library(webshot)
library(htmlwidgets)


translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
if (!require('openfda') ) {
  devtools::install_github("ropenhealth/openfda")
  library(openfda)
#  print('loaded open FDA')
}


source( 'sourcedir.R')


#**************************************************
#CPA
#**************************************************
shinyServer(function(input, output, session) {
  
  cacheFolder<-"/var/www/html/openfda/media/"
  # cacheFolder<- "C:/Users/dimst/Desktop/work_project/"
  
  
  values<-reactiveValues(urlQuery=NULL)
  
  #Values for checkboxes view
  ckbx <- reactiveValues(cb1=FALSE, cb2=FALSE, cb3=FALSE, cb4=FALSE)
  
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
  
  
  # output$daterangeout <- renderUI({
  #   query <- parseQueryString(session$clientData$url_search)
  #   selectedLang = tail(query[['lang']], 1)
  #   if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  #   {
  #     selectedLang='en'
  #   }
  # 
  #   langs = list(gr="el", en="en")
  #   # print(langs[[selectedLang]])
  #   # print(i18n()$t("to"))
  #   # langs[[selectedLang]]
  # 
  #   # updateDateRangeInput(session,'daterange', language=langs[[selectedLang]], separator=i18n()$t("to"))
  #   #dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]], separator=i18n()$t("to"))
  # 
  #   return (dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]], separator=i18n()$t("to")))
  # })
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    selectedLang = tail(query[['lang']], 1)
    if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
    {
      selectedLang='en'
    }
    translator$set_translation_language(selectedLang)
    #browser()
    # if (!is.null(query[['lang']])) {
    #   updateSelectInput(session, "selected_language",
    #                     i18n()$t("Change language"),
    #                     choices = c("en","gr"),
    #                     selected = selectedLang
    #   )
    # }
    langs = list(gr="el", en="en")
    
    removeUI(
      selector = "#daterange",
      multiple = FALSE
    )
    
    insertUI(
      selector = "#dtlocator",
      where = "beforeBegin",
      ui = dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]], separator=i18n()$t("to"))
    )
    
  })
  
  
  # observeEvent(input$daterange, {
  #   query <- parseQueryString(session$clientData$url_search)
  #   selectedLang = tail(query[['lang']], 1)
  #   if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  #   {
  #     selectedLang='en'
  #   }
  #   
  #   langs = list(gr="el", en="en")
  #   # print(langs[[selectedLang]])
  #   # print(i18n()$t("to"))
  #   # langs[[selectedLang]]
  #   runjs('$("#daterange input").attr("data-date-language", "gr");')
  #   # runjs('$(".datepicker").datepicker("destroy").datepicker($.datepicker.regional["el"]);')
  #   print(paste0("$('#daterange span span').text('", i18n()$t("to"), "');"))
  #   runjs(paste0("$('#daterange span span').text('", i18n()$t("to"), "');"))
  #   # runjs(paste0('$("#daterange input").attr("data-date-language", "', langs[[selectedLang]],'")'))
  # })
  
#Getters
  getwaittime <- reactive({ 
    if(session$clientData$url_hostname == '10.12.207.87')
    {
      return( 0.75)
    } else if(session$clientData$url_hostname == '127.0.0.1') {
      return (0.25)
    }
    return(0.0)
  })
  
  getqueryvars <- function( num = 1 ) {
    s <- vector(mode = "character", length = 7)
    #Dashboard
    s[1] <- paste0( input$t1, '&v1=', input$v1 )
    
    #PRR for a Drug
    s[2] <- paste0( input$t1, '&v1=', input$v1 )
    
    #PRR for an Event
    s[3] <- paste0( input$t2, '&v1=', input$v1 )
    
    #Dynamic PRR
    s[4] <- paste0( input$t1 , '&v1=', input$v1, '&t2=', input$t2  )
    
    #CPA
    s[5] <- paste0( input$t1 , '&v1=', input$v1,  '&t2=', input$t2  )
    
    #Reportview
    s[6] <- paste0( input$t1, '&v1=', input$v1,  '&t2=', input$t2 , '&v2=', getaevar() )
    
    #labelview
    s[7] <- paste0( input$t1, '&v1=', input$v1 )
    
    #LRTest
    s[8] <- paste0( input$t1, '&v1=', input$v1 )
    return(s)
  }  
  
getdrugvar <- function(){
  
 anychanged()
  return(input$v1)
}

getaevar <- function(){
  return ('patient.reaction.reactionmeddrapt')
}

gettimevar <- function(){
  anychanged()
  return (input$v2)
}

getexactdrugvar <- function(){
  return ( paste0(getdrugvar(), '.exact') )
}

getexactaevar <- function(){
  return ( paste0(getaevar(), '.exact')  )
}

getbestdrugvar <- function(){
  exact <-   ( getexactvals()$exactd)
  if (exact){
    return( getexactdrugvar() )
  } else {
    return( getdrugvar() )
  }
}

getbestaevar <- function(){
  exact <-   ( getexactvals()$exacte)
  if (exact){
    return( getexactaevar() )
  } else {
    return( getaevar() )
  }
}

# getterm1 <- function(quote=TRUE){
#   s <- toupper( input$t1 )
#   if (quote){
#     s <-  gsub('"', '', s , fixed=TRUE)
#     return(paste0('%22', s, '%22'))
#   } else {
#     return( s )
#   }
# }
# 
# getterm2 <- function(quote=TRUE){
#   s <- toupper( input$t2 )
#   if (quote){
#     s <-  gsub('"', '', s , fixed=TRUE)
#     return(paste0('%22', s, '%22'))
#   } else {
#     return( s )
#   }
# }

getbestterm1 <- function(quote=TRUE){
  exact <-   ( getexactvals()$exactd )
  return( getterm1( session,exact))
}

getbestterm2 <- function(quote=TRUE){
  exact <-   ( getexactvals()$exacte)
  return( getterm2( session,exact))
}

gettimerange <- reactive({
  geturlquery()
  mydates <- getstartend()
  start <- mydates[1]
  end <-  mydates[2]
  timerange <- paste0('[', start, '+TO+', end, ']')
  return(timerange)
})
#End Getters

#Timerange string from 1 December 1999 to present
getstartend <- reactive({
  geturlquery()
  start <- ('1906-07-01')
  end <- as.character( Sys.Date() ) 
  return( c(start, end))
})

#Reactive Queries
fixInput <- reactive({
  
  updateTextInput(session, "t1", value= (input$t1) )
  updateTextInput(session,"t2", value=(input$t2))   
})
fetchalldata <- reactive({
  a <- getqueryde()
  a <- getexactvals()
  a <- geturlquery()
  a <- gettotalquery()
  a <- gettotaldaterangequery()
})

getexactvals <- reactive({
  geturlquery()
  exactD <- input$useexactD
  if ( exactD=='exact' )
  { 
    exactd = TRUE
  } else {
    exactd = FALSE
  }
  exactE <- input$useexactE
  if ( exactE=='exact' )
  { 
    exacte = TRUE
  } else {
    exacte = FALSE
  }
  return( list( exacte=exacte, exactd=exactd) )
}) 


gettotalquery <- reactive({
  toggleModal(session, 'updatemodal', 'close')
  # v1 <- getbestdrugvar()
  # t1 <- c(getbestterm1() ) 
  
  
  q <- geturlquery()
  
  if (q$concomitant == TRUE){
    geturlquery()
    toggleModal(session, 'updatemodal', 'close')
    v1 <- getbestdrugvar()
    t1 <- c(getbestterm1() ) 
    myurl <- buildURL(v1, t1, count='', limit=5 )
    mydf <- fda_fetch_p( session, myurl, wait = getwaittime())
    
  }else {
    con <- mongo("dict_fda", url =mongoConnection())
    drugQuery <- SearchDrugReports(q$t1, input$date1, input$date2, q$dname)
    ids <- con$aggregate(drugQuery)
    con$disconnect()
    rank <- ceiling(length(ids$safetyreportid))
    
    v1 <- 'safetyreportid'
    t1 <- paste(ids$safetyreportid[1:100], collapse='", "' )
    # t1 <- ids$safetyreportid
    mydf <- data.frame()
    myurl <- buildURL(v1, t1, count='', limit=5 )
    mylist <- fda_fetch_p( session, myurl, wait = getwaittime())
    x <- mylist$results
    mydf <- rbind(mydf, x)
  }
  mydf <- list(result=mydf$result, url=myurl, meta=mydf$meta)
  return(mydf)
})    

gettotaldaterangequery <- reactive({
  q <- geturlquery()
  
  if (q$concomitant == TRUE){
    geturlquery()
    v1 <- c( getbestdrugvar(), gettimevar() )
    t1 <- c(getbestterm1(), gettimerange() ) 
    myurl <- buildURL(v1, t1, count='', limit=5)
    mydf <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=4)
    
  } else {
    con <- mongo("dict_fda", url =mongoConnection())
    drugQuery <- SearchDrugReports(q$t1, input$date1, input$date2, q$dname)
    ids <- con$aggregate(drugQuery)
    con$disconnect()
    rank <- ceiling(length(ids$safetyreportid))
    
    v1 <- 'safetyreportid'
    t1 <- paste(ids$safetyreportid[1:100], collapse='", "' )
    
    myurl <- buildURL(v1, t1, count='', limit=5)
    
    mydf <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=4)
  }
  
  
  mydf <- list(result=mydf$result, url=myurl, meta=mydf$meta)
  return(mydf)
})  

#Other reactives
getdrugeventtotal <- reactive({
  mysum <- getquerydata()$mydfin$total
  return( mysum )
})

getstartend <- function(){
  geturlquery()
  # start <- input$daterange[1]
  # end <- input$daterange[2]
  start <- input$date1
  end <- input$date2
  return( c(start, end))
}

getqueryde <- reactive({
  q<-geturlquery()
  
  v <- c( getbestdrugvar(), getbestaevar() , gettimevar() )
  t <- c( getbestterm1(), getbestterm2(), gettimerange() )
  if (t[1] !="" & t[2] !=""){
    t[1]<- toupper(q$dname)
    t[2]<- toupper(q$ename)
  }
  if (q$concomitant == TRUE){
    geturlquery()
    myurl <- buildURL(v, t, count=gettimevar() )
    out <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=5 )
    
  } else {
    
    # Refactor
    
    if (t[1]=="" & t[2] ==""){
      con <- mongo("dict_fda", url =mongoConnection())
      
      timeall<-TimeseriesForTotalReports(input$date1, input$date2)
      timeallResult <- con$aggregate(timeall)
      colnames(timeallResult)[1]<-"time"
      timeallResult$time <- as.Date(timeallResult$time, tz = "HST")
      out<-timeallResult
      con$disconnect()
    } else {
      con <- mongo("dict_fda", url =mongoConnection())
      
      timeall<-TimeseriesForDrugEventReports(q$t1, q$t2, input$date1, input$date2, q$dname)
      timeallResult <- con$aggregate(timeall)
      colnames(timeallResult)[1]<-"time"
      timeallResult$time <- as.Date(timeallResult$time, tz = "HST")
      out<-timeallResult
      con$disconnect()
      
    }
    # Redone
    
  }
  return( list(out=out ) )
})

getquerydata <- reactive({
  q<-geturlquery()
  mydf <- getqueryde()
  if (q$concomitant == TRUE){
    tmp <-mydf$out$result
  } else {
    tmp <-mydf$out
  }
  createAlert(session, 'alert', 'calcalert',
              title='Calculating...', 
              content = 'Calculating Time Series...', 
              dismiss = FALSE)
  mydfin <- gettstable( tmp )
  if(!is.null(session$calcalert))
  {
    closeAlert(session,  'calcalert')
  }
  return( list( mydfin= mydfin, mydf=mydf, mysum = mydfin$total ) )
})

getcodruglist <- reactive({
  q<-geturlquery()
  
  if (q$concomitant == TRUE){
    geturlquery()
    v <- c(getbestdrugvar(), getbestaevar())
    t <- c( getbestterm1(),  getbestterm2())
    if (t[1] !="" & t[2] !=""){
      t[1]<- toupper(q$dname)
      t[2]<- toupper(q$ename)
    }
    myurl <- buildURL( v, t, 
                       count= getexactdrugvar(), limit=999 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:999,]
    
  } else {
    
    con <- mongo("dict_fda", url =mongoConnection())
    
    totaleventQuery<-CocomitantForDrugEventReports(q$t1, q$t2, input$date1, input$date2, q$dname)
    mydf <- con$aggregate(totaleventQuery)
    # eventReport<-totaleventResult$safetyreportid
    colnames(mydf)[1]<-"term"
    con$disconnect()
    
    mydf <- mydf[1:999,]
    
  }

  mydf <- mydf[!is.na(mydf[,2]), ]
  mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
  return( list( mydf=mydf) )
})

getcoeventlist <- reactive({
  q<-geturlquery()
  
  if (q$concomitant == TRUE){
    v <- c(getbestdrugvar(), getbestaevar())
    t <- c( getbestterm1(),  getbestterm2())
    if (t[1] !="" & t[2] !=""){
      t[1]<- toupper(q$dname)
      t[2]<- toupper(q$ename)
    }
    myurl <- buildURL( v, t, 
                       count= getexactaevar(), limit=999 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:999,]
    
  } else {
    con <- mongo("dict_fda", url =mongoConnection())
    
    totaleventQuery<-ReactionsForDrugEventReports(q$t1, q$t2, input$date1, input$date2, q$dname)
    mydf <- con$aggregate(totaleventQuery)
    colnames(mydf)[1]<-"term"
    con$disconnect()
    
    mydf <- mydf[1:999,]
    
  }
  
  mydf <- mydf[!is.na(mydf[,2]), ]
  mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
  return( list( mydf=mydf) )
})

getcocountsE <- reactive({
  
  return( getcocounts('E') )
})

getcocountsD <- reactive({
  
  return( getcocounts('D') )
})
#**************************
# Concomitant drug table
getcocounts <- function(whichcount = 'D'){
  geturlquery()
  if ( is.null( getterm1( session) ) ){
    return(data.frame( c(paste('Please enter a drug and event name'), '') ) )
  }
  if( whichcount=='D')
  {
    mylist <- getcodruglist()
  } else (
    mylist <- getcoeventlist()
  )
  mydf <- mylist$mydf
  if(is.null(mydf) || length(mydf$cumsum)==0)
  {
    return(NULL)
  }
  myurl <- mylist$myurl
  sourcedf <- mydf
  #    print(names(mydf))
  #Drug Table
  if (whichcount =='D'){
    colname <- stri_enc_toutf8(i18n()$t("Drug Name"))
    if (input$v1 != 'patient.drug.medicinalproduct')
    {
      drugvar <- gsub( "patient.drug.","" , input$v1, fixed=TRUE)
      drugvar <- paste0( "&v1=", drugvar )
      medlinelinks <- coltohyper( paste0( '%22' , sourcedf[,1], '%22' ), 'L', 
                                  mybaseurl = getcururl(), 
                                  display= rep('L', nrow( sourcedf ) ), 
                                  append= drugvar )
      
      drugvar <- paste0( "&v1=", input$v1 )
      dashlinks <- coltohyper( paste0( '%22' , sourcedf[, 'term' ], '%22' ), 'DA', 
                               mybaseurl = getcururl(), 
                               display= rep('D', nrow( sourcedf ) ), 
                               append= drugvar )
      
      mydf <- data.frame( mydf)
      mynames <- c(  colname, stri_enc_toutf8(i18n()$t("Count")), stri_enc_toutf8(i18n()$t("Cumulative Sum"))) 
    }
    else {
      medlinelinks <- rep(' ', nrow( sourcedf ) )
      mynames <- c('-', colname, i18n()$t("Count")) 
    }
    
    names <- c('v1','t1', 'v2', 't2')
    values <- c(getbestaevar(), getbestterm2(), getexactdrugvar() ) 
    #Event Table
  } else {
    colname <- stri_enc_toutf8(i18n()$t("Preferred Term"))
    mynames <- c(colname, stri_enc_toutf8(i18n()$t("Count")), stri_enc_toutf8(i18n()$t("Cumulative Sum"))) 
    medlinelinks <- makemedlinelink(sourcedf[,1], 'M')          
    mydf <- data.frame( mydf) 
    names <- c('v1','t1', 'v2', 't2')
    values <- c(getbestdrugvar(), getbestterm1(), getexactaevar() ) 
  }
  
  mydf[,'count'] <- numcoltohyper(mydf[ , 'count' ], mydf[ , 'term'], names, values, mybaseurl = getcururl(), addquotes=TRUE )
  mydf[,'term'] <- coltohyper(mydf[,'term'], whichcount , mybaseurl = getcururl(), 
                              append= paste0( "&v1=", input$v1) )
  names(mydf) <- mynames
  return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
}   

gettstable <- function( tmp ){
  # browser()
  q<- geturlquery()
  if ( length(tmp)!=0  )
  {
    
    if (q$concomitant == TRUE){
      mydf <- data.frame(count=tmp$count, 
                         date= as.character( floor_date( ymd( (tmp[,1]) ), 'month' ) ), stringsAsFactors = FALSE )
    }else {
      mydf <- data.frame(count=tmp$count, 
                         date= as.character( floor_date( ymd( (tmp[,1]) ), 'month' ) ), stringsAsFactors = FALSE )
      
    }  
    mydaterange <- getstartend()
     mydf2 <- seq( as.Date(  mydf$date[1] ), as.Date( mydaterange[2] ), 'months' )
    
    mydf2 <-data.frame(date=as.character(mydf2), count=0L)
    mydf2<-rbind(mydf, mydf2)
    mydf2[,'date'] <- sub('-01', '', mydf2[,'date'],fixed=TRUE) 
    mydf <- aggregate(mydf2[,c('count')], by=list(mydf2$date), FUN=sum)
    mysum <- sum(mydf[,2])
    mydf[, 3] <- cumsum(mydf[,2])
    
    start <- paste0( '[',  mydf[,1], '01')
    start <- gsub('-', '', start)
    lastdate <- ymd(start[ length( start)] )
    month(lastdate) <- month(lastdate)+1
    mydates <- c( ymd(start[2:length(start)] ), lastdate  ) 
    mydates <- round_date(mydates, unit='month')
    mydates <- rollback(mydates)
    mydates <- gsub('-', '', as.character( mydates ))
    mycumdates <- paste0(start[1],  '+TO+', mydates ,']')
    mydates <- paste0(start,  '+TO+', mydates ,']')
    names(mydf) <- c("Date", "Count","Cumulative Count")
#    mydf <- mydf[ (mydf[,'Cumulative Count'] > 0), ]
    mydf_d <- mydf
    names <- c('v1','t1', 'v2' ,'t2', 'v3', 't3')
    values <- c( getbestdrugvar(), getbestterm1(), getbestaevar(), getbestterm2(), gettimevar() )
    mydf_d[,2] <- numcoltohyper(mydf[ , 2], mydates, names, values, type='R', mybaseurl = getcururl(), addquotes=TRUE )
    mydf_d[,3] <- numcoltohyper(mydf[ , 3], mycumdates, names, values, type='R', mybaseurl = getcururl(), addquotes=TRUE )

    } else {
    mydf <- NULL
    mydf_d <- NULL
    mysum <- NULL
  }
  mydf <- list(result=mydf, display=mydf_d, total= mysum )
  
  return(mydf)
}    

getts <- reactive({
  data <-  getquerydata()$mydfin$result
  ( mydates <- ymd(data[,'Date'] ) )
  ( mymonths <- month( ymd(data[,'Date'], truncated=2 ) ) )
  ( myyears <- year( ymd(data[,'Date'], truncated=2 ) ) )
  ( startmonth <- mymonths[1])
  ( endmonth <- mymonths[length(mymonths)])
  ( yrange <- range(myyears)) 
  #Check date variable in the dataset to see whether it is in Date format
  #Assign variable you want to run CPA to x
  datax<-data[,2]
  myts <- zoo( datax, data[, 1] )
  return(myts)
})

calccpmean<- reactive({
   myts <- getts()
   datax_changepoint <- cpt.mean(myts, Q=input$maxcp, method='BinSeg')
    return(datax_changepoint)
 }) 

calccpvar<- reactive({
  myts <- getts()
  datax_changepoint <- cpt.var(myts, Q = input$maxcp, method='BinSeg')
  return(datax_changepoint)
}) 
calccpbayes<- reactive({
  myts <- getts()
  mydf <- getquerydata()$mydfin$result[, c(1,2)]
  bcp.flu<-bcp(as.double(myts),p0=0.3)
  return(list(bcp.flu=bcp.flu, data=mydf) )
}) 

updatevars <- reactive({
  input$update
  isolate( {
    updateTextInput(session, "t1", value=( input$drugname ) )
    updateTextInput(session, "t2", value= ( input$eventname ) )
    updateNumericInput(session, "maxcp", value=input$maxcp2)
          })
})

anychanged <- reactive({
  a <- input$t1
  b <- input$v1
  c <- input$t2
  d <- input$v2
  e <- input$useexactD
  f <- input$useexactE
  if(!is.null(session$erroralert))
  {
    closeAlert(session, 'erroralert')
  }
})

# observeEvent(input$date1, {
#   
#   if (abs(input$date2-input$date1)>365){
#     updateDateInput(session, "date2",
#                     value=input$date1+365
#     )
#   }
# })
# 
# observeEvent(input$date2, {
#   
#   if (abs(input$date2-input$date1)>365){
#     updateDateInput(session, "date1",
#                     value=input$date1-365
#     )
#   }
# })

#SETTERS
output$mymodal <- renderText({
  if (input$update > 0)
    {
    updatevars()    
    toggleModal(session, 'modalExample', 'close')
  }
  return('')
})
output$cotitle <- renderText({ 
  return( ( paste0('<h4>Most Common Drugs In Selected Reports</h4><br>') ) )
})

output$cotitleE <- renderText({ 
  return( ( paste0('<h4>Most Common Events In Selected Reports</h4><br>') ) )
})

output$querycotext <- renderText({ 
  l <- getcocountsD()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
})

output$querycotextE <- renderText({ 
  l <- getcocountsE()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
})

# output$coquery <- renderTable({  
#   #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codrugs <- getcocountsD()$mydf
#   if ( is.data.frame(codrugs) )
#   { 
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )
#   }  
# }, sanitize.text.function = function(x) x)  

output$coquery <- DT::renderDT({
  codrugs <- getcocountsD()$mydf
  codrugs <- codrugs[1:length(codrugs)-1]
  coqueryForExcel<<-codrugs
  if (length(codrugs) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_changepoint", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if (!is.null(input$sourceCoDataframeUI)){
    if (input$sourceCoDataframeUI){
      write.csv(codrugs,paste0(cacheFolder,values$urlQuery$hash,"_codrugs.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      if ( is.data.frame(codrugs) )
      { 
        return(codrugs) 
      } else  {
        return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )},
      options = list(
        autoWidth = TRUE,
        dom = 't',
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2,3))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ))
    )
  } else {
    return ( datatable(
      if ( is.data.frame(codrugs) )
      { 
        return(codrugs) 
      } else  {
        return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )},
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2,3))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ))
    )
    
  }
  
},  escape=FALSE)

output$coqueryE <- DT::renderDT({
  codrugs <- getcocountsE()$mydf
  codrugs <- codrugs[1:length(codrugs)-1]
  coqueryEForExcel<<-codrugs
  if (length(codrugs) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_changepoint", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  
  if (!is.null(input$sourceEvDataframeUI)){
    if (input$sourceEvDataframeUI){
      write.csv(codrugs,paste0(cacheFolder,values$urlQuery$hash,"_qevents.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(  datatable(
      if ( is.data.frame(codrugs) )
      { 
        return(codrugs) 
      } else  {
        return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )},
      options = list(
        autoWidth = TRUE,
        dom = 't',
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2,3))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ))
    )
  } else {
    return (   datatable(
      if ( is.data.frame(codrugs) )
      { 
        return(codrugs) 
      } else  {
        return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )},
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2,3))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ))
    )
    
  }
  

},  escape=FALSE)

# output$coqueryE <- renderTable({  
#   #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codrugs <- getcocountsE()$mydf
#   if ( is.data.frame(codrugs) )
#   { 
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No Events for', getterm1( session ) ) ) )
#   }  
# }, sanitize.text.function = function(x) x)


# output$coquery <- DT::renderDT({
#   codrugs <- getcocountsE()$mydf
#   datatable(
#     if ( is.data.frame(codrugs) )
#     { 
#       return(codrugs) 
#     } else  {
#       return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )})
# },  escape=FALSE)

output$cloudcoquery <- renderPlot({  
  mydf <- getcocountsD()$sourcedf
  if ( is.data.frame(mydf) )
  {
    mytitle <- paste('Drug in Reports That Contain', getterm1( session ) )
    return( getcloud(mydf, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getterm1( session ) ) ) )
  }  
  
}, height=900, width=900 )

output$cloudcoqueryE <- renderPlot({  
  mydf <- getcocountsE()$sourcedf
  if ( is.data.frame(mydf) )
  {
    mytitle <- paste('Events in Reports That Contain', getterm1( session ) )
    return( getcloud(mydf, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getterm1( session ) ) ) )
  }  
  
}, height=900, width=900 )

output$drugname <- renderText({
  s <- getterm1( session,FALSE)
  if(s == '') {
    s <- 'None'
  }
  out <- paste( '<br><b>Drug Name:<i>', s, '</i></b><br><br>' )
  return(out)
})

output$eventname <- renderText({
  s <- getterm2( session,FALSE)
  if(s == '') {
    s <- 'None'
  }
  out <- paste( '<b>Event Term:<i>', s, '</i></b><br><br>' )
  return(out)
})

output$maxcp <- renderText({
  s <- input$maxcp
  if(s == '') {
    s <- 'None'
  }
  out <- paste( '<b>Maximum Number of Changepoints:<i>', s, '</i></b>' )
  return(out)
})
output$queryplot <- renderPlotly({ 
  q<-geturlquery()
  
  fetchalldata()
  #   if (input$term1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
  mydf <- getquerydata()$mydfin
  queryForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_changepoint", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    plot.new()
    hide("mainrow")
    return(NULL)
  }
  Dates2<-lapply(mydf$display['Date'], function(x) {
    # x <- as.Date(paste(x,'-01',sep = ''), "%Y-%m-%d")
    x <- paste(x,'-01',sep = '')
    x
  })
  Dates2<-unlist(Dates2, use.names=FALSE)
  if ( is.data.frame(mydf$display) )
  {
    ckbx$cb4 <- TRUE
    labs <-    mydf$display[[1]]
    Date<-mydf$display[[1]]
    Counts<-as.vector(mydf$display[,2])
    
    # p <- ggplot(mydf$display, aes(x=Date, y=Count,group = 1)) +
    #   geom_line() + 
    #   xlab("") +
    #   theme(axis.text.x = element_text(angle = 90, hjust = 1))
    # p
    
    
    # plot(x,y)
    
    
    #from here vagelis
    # plot(Counts, axes=FALSE, xlab="",ylab=i18n()$t("Count"))
    # axis(2)
    # axis(1, at=seq_along(Date),labels=as.character(mydf$display[[1]]), las=2)
    # box()
    # 
    # # mydf$display['Date'][1] <- as.Date(mydf$display['Date'][1], "%Y-%m-%d")
    # # # dm$Date <- as.Date(dm$Date, "%m/%d/%Y")
    # # plot(Count ~ Date, mydf$display)
    # 
    # grid()
    #to here vagelis
    
    # data <- read.table("https://python-graph-gallery.com/wp-content/uploads/bike.csv", header=T, sep=",") %>% head(300)
    
    # Check type of variable
    # str(data)
    
    # Since my time is currently a factor, I have to convert it to a date-time format!
    #data$datetime <- ymd_hms(data$datetime)
    # browser()
    # datetime <- ymd(Dates2)
    # 
    # # Then you can create the xts necessary to use dygraph
    # don <- xts(x = Counts, order.by = datetime)
    # 
    # # Finally the plot
    # p <- dygraph(don) %>%
    #   dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="grey") %>%
    #   # dySeries("V1", drawPoints = TRUE, pointShape = "square", color = "blue")
    #   dyRangeSelector() %>%
    #   dyCrosshair(direction = "vertical") %>%
    #   dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
    #   dyRoller(rollPeriod = 1)
    # p
    f <- list(
      family = "Helvetica Neue, Roboto, Arial, Droid Sans, sans-serif!important",
      color = '#667', 
      size = 13
    )
    datetimeValues <- ymd(Dates2)
    values2 =Counts
    data <- data.frame(datetimeValues, values2)
    p <- plot_ly(x = datetimeValues, y = values2,type = 'scatter', mode = 'lines',line = list(color = '#929292'),showlegend=FALSE)
    p <- p %>% layout(
      yaxis = list(
        title = i18n()$t("Count"),
        titlefont = f
      ))
    
    p <- p %>% layout(title = i18n()$t("Report Counts By Date"),titlefont = f)
    
    if (!is.null(input$sourceYearPlotReportUI)){
      if (input$sourceYearPlotReportUI){
        saveWidget(as_widget(p), "temp.html")
        webshot("temp.html", file = paste0(cacheFolder,q$hash,"_yearplot.png"), cliprect = "viewport")
        # withr::with_dir("/var/www/html/openfda/media", orca(p, paste0(q$hash,"_yearplot.png")))
        # png(filename = paste0(cacheFolder,q$hash,"_timeseries.png"))
        # mytitle <- paste( "Change in Mean Analysis for", mydrugs, 'and', myevents )
        # plot(s1, xaxt = 'n', ylab='Count', xlab='', main=mytitle)
        # axis(1, pos,  labs[pos], las=2  )
        # grid(nx=NA, ny=NULL)
        # abline(v=pos, col = "lightgray", lty = "dotted",
        #       lwd = par("lwd") )
        # dev.off()
      }
      
    }
    
    p
  } else  {return(plot(data.frame(Drug=paste( 'No events for drug', input$term1), Count=0)))}
  
})


output$query <- renderTable({  
  fetchalldata()
#   if (input$term1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
    mydf <- getquerydata()$mydfin
  if ( is.data.frame(mydf$display) )
{
    return(mydf$display) 
  } else  {return(data.frame(Drug=paste( 'No events for drug', input$term1), Count=0))}
  }, include.rownames = FALSE, sanitize.text.function = function(x) x)
# output$coquery <- renderTable({  
#   #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codrugs <- getcocountsD()$mydf
#   if ( is.data.frame(codrugs) )
#   { 
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )
#   }  
# }, sanitize.text.function = function(x) x)  

# output$coqueryE <- renderTable({  
#   #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codrugs <- getcocountsE()$mydf
#   # browser
#   if ( is.data.frame(codrugs) )
#   { 
#     # names(codrugs) <- c(  stri_enc_toutf8(i18n()$t("Preferred Term")), stri_enc_toutf8(i18n()$t("Case Counts for")), paste('%', stri_enc_toutf8(i18n()$t("Count") )))
#     # names(codrugs) <- c(  stri_enc_toutf8('??????'),stri_enc_toutf8('??????'),stri_enc_toutf8('????????'))
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No Events for', getterm1( session ) ) ) )
#   }  
# }, sanitize.text.function = function(x) x)

output$cloudcoquery <- renderPlot({  
  mydf <- getcocountsD()$sourcedf
  if ( is.data.frame(mydf) )
  {
    mytitle <- paste('Drug in Reports That Contain', getterm1( session ) )
    return( getcloud(mydf, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getterm1( session ) ) ) )
  }  
  
}, height=900, width=900 )

output$cloudcoqueryE <- renderPlot({  
  mydf <- getcocountsE()$sourcedf
  if ( is.data.frame(mydf) )
  {
    mytitle <- paste('Events in Reports That Contain', getterm1( session ) )
    return( getcloud(mydf, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getterm1( session ) ) ) )
  }  
  
}, height=900, width=900 )

 output$querytext <- renderText({ 
   fetchalldata()
   mylist <-getquerydata()
   mydf <- mylist$mydfin
   mydf2 <- gettotaldaterangequery()
#    "meta": {
#      "disclaimer": "openFDA is a beta research project and not for clinical use. While we make every effort to ensure that data is accurate, you should assume all results are unvalidated.",
#      "license": "http://open.fda.gov/license",
#      "last_updated": "2014-08-01",
#      "results": {
#        "skip": 0,
#        "limit": 1,
#        "total": 1355
#print(mydf)
meta <- mydf2$meta
out <- paste('<b>Total =</b>', prettyNum( getdrugeventtotal(), big.mark=',' ) , 'for drug-event combination<br>',
             '<b>Query =</b>', removekey( makelink(mylist$myurl) ), '<br><br>' )
 return(out)
  })
output$metatext <- renderText({ 
  fetchalldata()
  mydf <- gettotaldaterangequery()
  meta <- mydf$meta
#  print(meta)
  out <- paste(
    '<br><b>Total =</b>', prettyNum( meta$results$total, big.mark=',' ), 'reports for', getterm1( session,quote=FALSE), 
    'for dates from', gettimerange(),
    '<br><b>Query =</b>', removekey( makelink(mydf$url) ), '<br><br>' )
  return(out)
})
output$allquerytext <- renderText({ 
  fetchalldata()
  mydf <- gettotalquery()
  meta <- mydf$meta
  out <- paste('<h4>Meta Data</h4>',
    '<b>Last Update =</b>', meta$last_updated, 
      '<br><b>Total =</b>', prettyNum( meta$results$total, big.mark=',' ), 'reports for', getterm1( session,quote=FALSE),
    '<br> <b>Query =</b>', removekey(  makelink(mydf$url) ) )
  return(out)
})


output$infocpmeantext <- renderUI ({
  mydf <-getquerydata()$mydfin$result
  if (length(mydf) > 0)
    {
    createAlert(session, 'alert', 'calclert',
                title='Calculating...', 
                content = 'Calculating meanCP', 
                dismiss = FALSE)
    s <- calccpmean()
    
    mycpts <- attr( s@data.set, 'index')[s@cpts[1:length(s@cpts)-1] ]
    mycpts <-paste(mycpts, collapse=', ')
    out <- paste( i18n()$t('Changepoint type      : Change in'), s@cpttype, '<br>' )
    out <- paste(out,  i18n()$t('Method of analysis    :') , s@method , '<br>' )
    out <- paste(out, i18n()$t('Test Statistic  :') , s@test.stat, '<br>' )
    out <- paste(out, i18n()$t('Type of penalty       :') , s@pen.type, 'with value', round(s@pen.value, 6), '<br>' )
    out <- paste(out, i18n()$t('Maximum no. of cpts   : ') , s@ncpts.max, '<br>' )
    out <- paste(out, i18n()$t('Changepoint Locations :') , mycpts , '<br>' )
    
    out <- paste(out, "<br>",i18n()$t('changepoint explanation'), "<br>" )
    if(!is.null(session$calclert))
    {
      closeAlert(session, 'calclert')
    }
    } else {
      out <- i18n()$t('Insufficient data')
    }
    addPopover(session=session, id="infocpmeantext", title=i18n()$t("Application Info"), 
             content=paste(out,i18n()$t('Change in mean analysis explanation')), placement = "left",
             trigger = "hover", options = list(html = "true"))
    #attr(session, "cpmeanplottext") <- out
    # browser()
    # l <- append( l, c('cpmeanplottext' =  out ) )
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  
})
output$dlChangeinMeanAnalysis <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(cpmeanForExcel, file, sheetName="cpmean")
  }
)
output$dlChangeinVarianceAnalysis <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(cpvarForExcel, file, sheetName="cpvar")
  }
)
output$dlBayesianChangepointAnalysis <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(cpbayesForExcel, file, sheetName="cpbayes")
  }
)
output$dlReportCountsbyDate <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(queryForExcel, file, sheetName="query")
  }
)
output$dlCountsForDrugsInSelectedReports <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryForExcel, file, sheetName="coquery")
  }
)
output$dlCountsForEventsInSelectedReports <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryEForExcel, file, sheetName="coqueryE")
  }
)
output$cpmeanplot <- renderPlotly ({
  q<- geturlquery()
  
  if(getterm1( session)!=""){
  mydf <-getquerydata()$mydfin$result
  cpmeanForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_changepoint", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    plot.new()
    hide("mainrow")
    return(NULL)
  }
  if (length(mydf) > 0)
    {
    s1 <- calccpmean()
    labs <-    index( getts() )
    pos <- seq(1, length(labs), 3)
    ckbx$cb1 <- TRUE
    
    if ( getterm1( session, FALSE )==''  )
      {
      mydrugs <- i18n()$t("All Drugs")
      }
    else 
      {
        mydrugs <- getterm1( session, FALSE )
      }
    if ( getterm2( session, FALSE )=='' )
      {
        myevents <- i18n()$t("All Events")
      }
    else 
      {
        myevents <- getterm2( session, FALSE )
      }
    # mytitle <- paste( i18n()$t("Change in mean analysis for"), mydrugs, i18n()$t("and"), myevents )
    mytitle <-  i18n()$t("Change in mean analysis")
    # plot(s1, xaxt = 'n', ylab=i18n()$t("Count"), xlab='', main=mytitle)
    # axis(1, pos,  labs[pos], las=2  )
    # grid(nx=NA, ny=NULL)
    # abline(v=pos, col = "lightgray", lty = "dotted",
    #        lwd = par("lwd") )
    
    values<-as.data.frame(s1@data.set)
    Dates2<-lapply(attr(s1@data.set, "index"), function(x) {
      # x <- as.Date(paste(x,'-01',sep = ''), "%Y-%m-%d")
      x <- paste(x,'-01',sep = '')
      x
    })
    # browser()
    # datetime <- ymd(Dates2)
    # don <- xts(x =as.vector(values), order.by = datetime)
    # p <- dygraph(don,main = "Change in mean analysis") %>%
    #   dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="grey") %>%
    #   # dySeries("V1", drawPoints = TRUE, pointShape = "square", color = "blue")
    #   dyRangeSelector() %>%
    #   # dyLimit(s@param.est$mean[2],label = "Y-axis Limit",color = "red",strokePattern = "dashed")%>%
    #   dyCrosshair(direction = "vertical") %>%
    #   dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
    #   dyRoller(rollPeriod = 1)
    #   for (i in 1:length(s1@param.est$mean)){
    #     p <- p %>% dyLimit(s1@param.est$mean[i])
    #   }
    # # %>%
    # # dyLimit(s1@cpts[2], color = "red")
    # 
    # 
    # p
    
    
    f <- list(
      family = "Helvetica Neue, Roboto, Arial, Droid Sans, sans-serif!important",
      color = '#667', 
      size = 13
    )
    datetimeValues <- ymd(Dates2)
    values2 =values$x
    data <- data.frame(datetimeValues, values)
    # p <- plot_ly(x = attr(s1@data.set,'index'), y = values2,type = 'scatter', mode = 'lines',line = list(color = '#929292'))
    p <- plot_ly(x = attr(s1@data.set,'index'),showlegend=FALSE)
    p <- p %>% add_trace(x = attr(s1@data.set,'index'), y = values2,type = 'scatter', mode = 'lines',line = list(color = '#929292'))
    p <- p %>% layout(title = i18n()$t("Change in mean analysis"),titlefont = f)
    p <- p %>% layout(yaxis = list(
      title = i18n()$t("Count"),
      titlefont = f
    ))
    range_0<-1   
    for (i in 1:(length(s1@param.est$mean))){
      mean_i<-s1@param.est$mean[i]
      range_1<-s1@cpts[i]
      limit1<-c(rep(mean_i, (range_1-range_0+1) ))
      x_range<-attr(s1@data.set,'index')[range_0:range_1]
      t1<-paste(length(x_range),length(limit1))
      p <- p %>% add_trace(x=x_range,y = limit1,  type = 'scatter', mode = 'lines',line = list(color = '#ff7f0e'))
      
      range_0<-range_1
    }
    
    if (!is.null(input$sourcePlotReportUI)){
      if (input$sourcePlotReportUI){
        saveWidget(as_widget(p), "temp.html")
        webshot("temp.html", file = paste0(cacheFolder,q$hash,"_cpmeanplot.png"), cliprect = "viewport")
        # withr::with_dir("/var/www/html/openfda/media", orca(p, paste0(q$hash,"_cpmeanplot.png")))
        
        # png(filename = paste0(cacheFolder,q$hash,"_timeseries.png"))
        # mytitle <- paste( "Change in Mean Analysis for", mydrugs, 'and', myevents )
        # plot(s1, xaxt = 'n', ylab='Count', xlab='', main=mytitle)
        # axis(1, pos,  labs[pos], las=2  )
        # grid(nx=NA, ny=NULL)
        # abline(v=pos, col = "lightgray", lty = "dotted",
        #       lwd = par("lwd") )
        # dev.off()
      }
      
    }
    p
    
    
    }
    else
    {
      return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))
    }
  }
  else{
    # s1 <- calccpmean()
    geturlquery()
    return (NULL)
  }
})

# ckbx$cb1 <- TRUE

output$infocpvartext <- renderUI ({
  mydf <-getquerydata()$mydfin$result
  if (length(mydf) > 0)
    {
    s <- calccpvar()
    mycpts <- attr( s@data.set, 'index')[s@cpts[1:length(s@cpts)-1] ]
    mycpts <-paste(mycpts, collapse=', ')
    out <- paste( i18n()$t('Changepoint type      : Change in'), s@cpttype, '<br>' )
    out <- paste(out,  i18n()$t('Method of analysis    :') , s@method , '<br>' )
    out <- paste(out, i18n()$t('Test Statistic  :') , s@test.stat, '<br>' )
    out <- paste(out, i18n()$t('Type of penalty       :') , s@pen.type, i18n()$t('with value'), round(s@pen.value, 6), '<br>' )
    out <- paste(out, i18n()$t('Maximum no. of cpts   : ') , s@ncpts.max, '<br>' )
    out <- paste(out, i18n()$t('Changepoint Locations :') , mycpts , '<br>' )
    out <- paste(out,"<br>", i18n()$t('changepoint explanation'), '<br>' )
    } else {
       out<-HTML(i18n()$t('Insufficient Data') )
    }
    addPopover(session=session, id="infocpvartext", title="", 
               content=paste(out,i18n()$t('Change in variance analysis explanation')), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$cpvarplot <- renderPlotly ({
  q<-geturlquery()
  
  mydf <-getquerydata()$mydfin$result
  cpvarForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    ckbx$cb2 <- TRUE
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_changepoint", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    plot.new()
    hide("mainrow")
    return(NULL)
  }
  if (length(mydf) > 0)
    {
    s1 <- calccpvar()
    labs <-    index( getts() )
    pos <- seq(1, length(labs), 3)
    if ( getterm1( session, FALSE ) == ''  )
    {
      mydrugs <- 'All Drugs'
    }
    else 
    {
      mydrugs <- getterm1( session,FALSE)
    }
    if ( getterm2( session,FALSE)=='' )
    {
      myevents <- 'All Events'
    }
    else 
    {
      myevents <- getterm2( session,FALSE)
    }
    # mytitle <- paste( "Change in variance analysis for", mydrugs, 'and', myevents )
    mytitle <- i18n()$t("Change in variance analysis")
    # plot(s, xaxt = 'n', ylab=i18n()$t("Count"), xlab='', main=mytitle)
    # axis(1, pos,  labs[pos], las=2  )
    # grid(nx=NA, ny=NULL)
    # abline(v=pos, col = "lightgray", lty = "dotted",
    #        lwd = par("lwd") )
    
    values<-as.data.frame(s1@data.set)
    Dates2<-lapply(attr(s1@data.set, "index"), function(x) {
      # x <- as.Date(paste(x,'-01',sep = ''), "%Y-%m-%d")
      x <- paste(x,'-01',sep = '')
      x
    })
    # datetime <- ymd(Dates2)
    # don <- xts(x =as.vector(values), order.by = datetime)
    # p <- dygraph(don,main = "Change in mean analysis") %>%
    #   dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="grey") %>%
    #   # dySeries("V1", drawPoints = TRUE, pointShape = "square", color = "blue")
    #   dyRangeSelector() %>%
    #   # dyLimit(s@param.est$mean[2],label = "Y-axis Limit",color = "red",strokePattern = "dashed")%>%
    #   dyCrosshair(direction = "vertical") %>%
    #   dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
    #   dyRoller(rollPeriod = 1)
    # p
    f <- list(
      family = "Helvetica Neue, Roboto, Arial, Droid Sans, sans-serif!important",
      color = '#667', 
      size = 13
    )
    datetimeValues <- ymd(Dates2)
    values2 =values$x
    data <- data.frame(datetimeValues, values)
    p <- plot_ly(x = attr(s1@data.set,'index'),showlegend=FALSE)
    p<- p%>% add_trace( y = values2,type = 'scatter', mode = 'lines',name=' ',line = list(color = '#929292'))
    p <-p %>% layout(
      yaxis = list(
        title = i18n()$t("Count"),
        titlefont = f
      ))
    
    p <-p %>% layout(title = i18n()$t("Change in variance analysis"),titlefont = f)
    
    range_0<-1 
    maxy<-max(values2)
    for (i in 1:(length(s1@cpts))){
      p <- p%>% add_segments(x = attr(s1@data.set,'index')[s1@cpts[i]], xend = attr(s1@data.set,'index')[s1@cpts[i]], y = 0, yend = maxy,line = list(color = '#ff7f0e'))
    }
    if (!is.null(input$sourceVarPlotReportUI)){
      if (input$sourceVarPlotReportUI){
        saveWidget(as_widget(p), "temp.html")
        webshot("temp.html", file = paste0(cacheFolder,q$hash,"_cpvarplot.png"), cliprect = "viewport")
        # withr::with_dir("/var/www/html/openfda/media", orca(p, paste0(q$hash,"_cpvarplot.png")))
        # png(filename = paste0(cacheFolder,q$hash,"_timeseries.png"))
        # mytitle <- paste( "Change in Mean Analysis for", mydrugs, 'and', myevents )
        # plot(s1, xaxt = 'n', ylab='Count', xlab='', main=mytitle)
        # axis(1, pos,  labs[pos], las=2  )
        # grid(nx=NA, ny=NULL)
        # abline(v=pos, col = "lightgray", lty = "dotted",
        #       lwd = par("lwd") )
        # dev.off()
      }
      
    }
    p
  }
  
})

output$cpbayestext <- renderPrint ({
  mydf <-getquerydata()$mydfin$result
  if (length(mydf) > 0)
    {
    mycp <- calccpbayes()
    data <- mycp$data
    bcp.flu <- mycp$bcp.flu
    # browser()
    data$postprob <- bcp.flu$posterior.prob
    data2<-data[order(data$postprob,decreasing = TRUE),]
    data2[1:input$maxcp,]
    } else {
      return ( 'Insufficient Data', file='' )
    }
})
output$infocpbayestext <- renderUI ({
  mydf <-getquerydata()$mydfin$result
  if (length(mydf) > 0)
  {
    mycp <- calccpbayes()
    data <- mycp$data
    bcp.flu <- mycp$bcp.flu
    data$postprob <- bcp.flu$posterior.prob
    data2<-data[order(data$postprob,decreasing = TRUE),]
    out<-print(data2[1:input$maxcp,])
    outb<-build_infocpbayes_table(out)
    # outb<-paste(outb,"<br><br>",i18n()$t("Bayesian change point explanation")," ")
    outb<-i18n()$t("Bayesian change point explanation")
    
    
    
  } else {
    outb<-'Insufficient Data'
  }
  addPopover(session=session, id="infocpbayestext", title=i18n()$t("Application Info"), 
             content=HTML(outb), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
  
  
})

output$infoCountsForDrugsInSelectedReports<-renderUI({
  addPopover(session=session, id="infoCountsForDrugsInSelectedReports", title=i18n()$t("Application Info"), 
             content=paste(i18n()$t("Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations"),"<br><br>",i18n()$t("prr explanation")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$infoReportCountsbyDate<-renderUI({
  addPopover(session=session, id="infoReportCountsbyDate", title=i18n()$t("Application Info"), 
             content=stri_enc_toutf8(i18n()$t("Drug-event reports per date diagram")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$infoCountsForEventsInSelectedReports<-renderUI({
  addPopover(session=session, id="infoCountsForEventsInSelectedReports", title=i18n()$t("Application Info"), 
             content=paste(i18n()$t("Frequency table for events found in selected reports. Event name is linked to PRR results for drug-event combinations."),"<br><br>",i18n()$t("prr explanation")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})


build_infocpbayes_table <- function(out)({
  outb<-'row '
  outb<-paste(outb,attr(out,'names')[1],' ')
  outb<-paste(outb,formatC(attr(out,'names')[2], format = "f", width=-8, ),' ')
  outb<-paste(outb,attr(out,'names')[3],' ')
  outb<-paste(outb,'<br>')
  for(i in 1:length(out))
  {
    outb<-paste(outb,attr(out,'row.names')[i])
    outb<-paste(outb,out[1:input$maxcp,]$Date[i],' ')
    outb<-paste(outb,out[1:input$maxcp,]$Count[i],' ')
    outb<-paste(outb,out[1:input$maxcp,]$postprob[i], ' ')
    outb<-paste(outb,'<br><br>')
  }
  return(outb)
})
# output$infocpbayestext <- renderPrint ({
#   mydf <-getquerydata()$mydfin$result
#   browser()
#   if (length(mydf) > 0)
#   {
#     mycp <- calccpbayes()
#     data <- mycp$data
#     bcp.flu <- mycp$bcp.flu
#     data$postprob <- bcp.flu$posterior.prob
#     data2<-data[order(data$postprob,decreasing = TRUE),]
#     out<-print(data2[1:input$maxcp,])
#     outb<-data.frame()
#     for (i in 1:length(out)){
#       outb<-paste(outb,out[i],sep="")
#     }
#     # out<-paste(typeof(data2[1:input$maxcp,]),data2[1:input$maxcp,])
#     # out<-paste( out, collapse='<br>')
#     
#   } else {
#     outb<-'Insufficient Data'
#   }
#   
#   addPopover(session=session, id="infocpbayestext", title="", 
#              content=HTML(outb), placement = "left",
#              trigger = "hover", options = list(html = "true"))
#   return(HTML('<button type="button" class="btn btn-info">i</button>'))
#   
#   
# })
output$cpbayesplot <- renderPlotly ({
  q<-geturlquery()
  
  mydf <-getquerydata()$mydfin$result
  cpbayesForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_changepoint", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    plot.new()
    hide("mainrow")
    return(NULL)
  }
  if (length(mydf) > 0)
    {
    ckbx$cb3 <- TRUE
    s1 <- calccpbayes()$bcp.flu
    # labs <-    index( getts() )
    # plot(s1)
    # grid()
    
    # datetimeValues <- ymd(Dates2)
    # values2 =values$x
    datamean <- s1$posterior.mean
    datameanframe<-as.data.frame(datamean)
    p <- plot_ly(datameanframe,showlegend=FALSE,height = 500)
    p <- p %>% add_trace(datameanframe,y=~X1,type = 'scatter', mode = 'lines',name=' ',line = list(color = '#929292'))
    data <- s1$data
    dataframe<-as.data.frame(data)
    trace_1<-dataframe$V1
    trace_2<-dataframe$V2
    
    titlefont = list()
    f <- list(
      family = "Helvetica Neue, Roboto, Arial, Droid Sans, sans-serif!important",
      color = '#667', 
      size = 13
    )
    # f2 <- list(
    #   family = "Helvetica Neue, Roboto, Arial, Droid Sans, sans-serif!important",
    #   color = '#667', 
    #   size = 11
    # )
    
    p <- p %>% add_trace(x=~trace_1,y=~trace_2, mode = 'markers',marker = list( size = 4))%>% 
      layout(yaxis = list(
        title = i18n()$t("Posterior Means"),
        titlefont = f
      ))
    
    dataPosterior <- s1$posterior.var
    dataPosteriorFrame<-as.data.frame(dataPosterior)
    p2<-plot_ly(dataPosteriorFrame,y=~V1,type = 'scatter', mode = 'lines',name=' ',line = list(color = '#929292'),showlegend=FALSE,height = 500) %>% 
      layout(xaxis = list(
        title = i18n()$t("Location"),
        titlefont = f
      ), 
      yaxis = list(
        title = i18n()$t("Posterior Probability"),
        titlefont = f
      ))
    
      
    fig <- subplot(p, p2,nrows = 2, shareX = TRUE, titleY = TRUE)%>% layout(title = i18n()$t("Posterior Means and Probabilities of Change"),titlefont = f)
    
    if (!is.null(input$sourceBayesPlotReportUI)){
      if (input$sourceBayesPlotReportUI){
        saveWidget(as_widget(fig), "temp.html")
        webshot("temp.html", file = paste0(cacheFolder,q$hash,"_cpbayesplot.png"), cliprect = "viewport")
        # withr::with_dir("/var/www/html/openfda/media", orca(fig, paste0(q$hash,"_cpbayesplot.png")))
        # png(filename = paste0(cacheFolder,q$hash,"_timeseries.png"))
        # mytitle <- paste( "Change in Mean Analysis for", mydrugs, 'and', myevents )
        # plot(s1, xaxt = 'n', ylab='Count', xlab='', main=mytitle)
        # axis(1, pos,  labs[pos], las=2  )
        # grid(nx=NA, ny=NULL)
        # abline(v=pos, col = "lightgray", lty = "dotted",
        #       lwd = par("lwd") )
        # dev.off()
      }
      
    }
    
    fig
    }
  
  })

output$querytitle <- renderText({ 
  return( paste('<h4>Counts for', getterm1( session,FALSE), 'with event "', getterm2( session,FALSE), '"</h4>') )
})

output$urlquery <- renderText({ 
  return( getcururl()  )
})

output$applinks <- renderText({ 
  return( makeapplinks(  getcururl(), getqueryvars() )  )
})


output$date1 <- renderText({ 
  l <- getdaterange()
  paste( '<b>', l[3] , 'from', as.Date(l[1],  "%Y%m%d")  ,'to', as.Date(l[2],  "%Y%m%d"), '</b>')
})

#URL management
getcururl <- reactive({
  mypath <- extractbaseurl( session$clientData$url_pathname )
  s <- paste0( session$clientData$url_protocol, "//", session$clientData$url_hostname,
               ':',
               session$clientData$url_port,
               mypath )
  return(s)
})

geturlquery <- reactive({
  q <- parseQueryString(session$clientData$url_search)
  # q<-NULL
  # q$v1<-"patient.drug.openfda.generic_name"
  # q$v2<-"patient.reaction.reactionmeddrapt"
  # q$t1<-"N05BA12"
  # q$t2<-"10013654"
  # q$t1<-"Omeprazole"
  # q$t2<-"Hypokalaemia"
  # q$t1<-"A02BC01"
  # q$t2<-"10021015"
  # q$hash <- "ksjdhfksdhfhsk"
  # q$concomitant<-FALSE
  updateSelectizeInput(session, inputId = "v1", selected = q$drugvar)
  updateTextInput(session, "t1", value=q$term1)
  updateTextInput(session,"t2", value=q$term2)   
  updateTextInput(session, "drugname", value=q$term1)
  updateTextInput(session,"eventname", value=q$term2) 
  updateSelectizeInput(session, inputId = "v1", selected = q$v1)
  updateTextInput(session, "t1", value=q$t1)
  updateTextInput(session,"t2", value=q$t2) 
  updateTextInput(session, "drugname", value=q$t1)
  updateTextInput(session,"eventname", value=q$t2) 
  updateDateRangeInput(session,'daterange', start = input$date1, end = input$date2)
  updateNumericInput(session,'maxcp', value=q$maxcps)
  updateNumericInput(session,'maxcp2', value=q$maxcps)
  updateRadioButtons(session, 'useexact',
                     selected = if(length(q$useexact)==0) "exact" else q$useexact)
  updateRadioButtons(session, 'useexactD',
                     selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
  updateRadioButtons(session, 'useexactE',
                     selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
  
 
  con_atc <- mongo("atc", url =mongoConnection())
  drug <- con_atc$find(paste0('{"code" : "',q$t1,'"}'))
  con_atc$disconnect()
  
  q$dname <- drug$names[[1]][1]
  
  con_medra <- mongo("medra", url =mongoConnection())
  event <- con_medra$find(paste0('{"code" : "',q$t2,'"}'))
  con_medra$disconnect()
  
  q$ename <- event$names[[1]][1]
  values$urlQuery<-q
  
  return(q)
})

output$downloadDataLbl1 <- output$downloadDataLbl2 <- output$downloadDataLbl3 <-
  output$downloadDataLbl4 <-output$downloadDataLbl5 <- output$downloadDataLbl6 <- renderText({
  return(i18n()$t("Download Data in Excel format"))
})

output$downloadBtnLbl1 <- output$downloadBtnLbl2 <- output$downloadBtnLbl3 <-
  output$downloadBtnLbl4 <- output$downloadBtnLbl5 <- output$downloadBtnLbl6 <-renderText({
  return(i18n()$t("Download"))
})

output$ChangeinMeanAnalysis <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Change in mean analysis")))
  
})
output$ChangeinVarianceAnalysis <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Change in variance analysis")))
  
})
output$BayesianChangepointAnalysis <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Bayesian changepoint analysis")))
  
})
output$ReportCountsbyDate <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Report counts by date")))
  
})
output$CountsForDrugsInSelectedReports <- renderUI({ 
  # HTML(stri_enc_toutf8(i18n()$t("Counts for drugs in selected reports")))
  HTML(stri_enc_toutf8(i18n()$t("Drugs in scenario reports")))
  
})
output$CountsForEventsInSelectedReports <- renderUI({ 
  # HTML(stri_enc_toutf8(i18n()$t("Counts for events in selected reports")))
  HTML(stri_enc_toutf8(i18n()$t("Events in scenario reports")))
  
})
output$OtherApps <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Other Apps")))
  
})
output$DataReference <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Data Reference")))
  
})
output$About <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("About")))
  
})
output$DateReportWasFirstReceivedbyFDA <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Date Report Was First Received by FDA.")))
  
})
output$ChangePointAnalysis <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Change Point Analysis")))
  
})

output$sourcePlotReport<-renderUI({
  if ((!is.null(values$urlQuery$hash) && ckbx$cb1))
    checkboxInput("sourcePlotReportUI", "Save plot")
})

observeEvent(input$sourcePlotReportUI,{
  
  if (!is.null(input$sourcePlotReportUI))
    if (!input$sourcePlotReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_cpmeanplot.png")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceVarPlotReport<-renderUI({
  if ((!is.null(values$urlQuery$hash) && ckbx$cb2))
    checkboxInput("sourceVarPlotReportUI", "Save plot")
})

observeEvent(input$sourceVarPlotReportUI,{
  
  if (!is.null(input$sourceVarPlotReportUI))
    if (!input$sourceVarPlotReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_cpvarplot.png")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceBayesPlotReport<-renderUI({
  if ((!is.null(values$urlQuery$hash)) && ckbx$cb3)
    checkboxInput("sourceBayesPlotReportUI", "Save plot")
})

observeEvent(input$sourceBayesPlotReportUI,{
  
  if (!is.null(input$sourceBayesPlotReportUI))
    if (!input$sourceBayesPlotReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_cpbayesplot.png")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceYearPlotReport<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceYearPlotReportUI", "Save plot")
})

observeEvent(input$sourceYearPlotReportUI,{
  
  if (!is.null(input$sourceYearPlotReportUI))
    if (!input$sourceYearPlotReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_yearplot.png")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceCoDataframe<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceCoDataframeUI", "Save data values")
})

observeEvent(input$sourceCoDataframeUI,{
  
  if (!is.null(input$sourceCoDataframeUI))
    if (!input$sourceCoDataframeUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_codrugs.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceEvDataframe<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceEvDataframeUI", "Save data values")
})

observeEvent(input$sourceEvDataframeUI,{
  
  if (!is.null(input$sourceEvDataframeUI))
    if (!input$sourceEvDataframeUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_qevents.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})




i18n <- reactive({
  selected <- input$selected_language
  if (length(selected) > 0 && selected %in% translator$languages) {
    translator$set_translation_language(selected)
  }
  translator
})




})
