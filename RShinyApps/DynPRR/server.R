require(shiny)
require(shinyBS)
require('lubridate')
require('bcp')
require('changepoint')
require('zoo')
library(xlsx)
if (!require('openfda') ) {
  devtools::install_github("ropenhealth/openfda")
  library(openfda)
  print('loaded open FDA')
}
require(RColorBrewer)
require(wordcloud)
library(shiny)
library(shiny.i18n)
library(shinyjs)
library(jsonlite)
translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')


source('sourcedir.R')
 

#**************************************************
#DYNPRR
#*********************************************
shinyServer(function(input, output, session) {
  
  cacheFolder<-"/var/www/html/openfda/media/"
  # cacheFolder<- "C:/Users/dimst/Desktop/work_project/"
  
  values<-reactiveValues(urlQuery=NULL)
  
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
  
  output$daterange <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    selectedLang = tail(query[['lang']], 1)
    if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
    {
      selectedLang='en'
    }

    langs = list(gr="el", en="en")
    dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]], separator=i18n()$t("to"))
  })
  
  output$daterange <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    selectedLang = tail(query[['lang']], 1)
    if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
    {
      selectedLang='en'
    }
    
    langs = list(gr="el", en="en")
    dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]])
  })
  
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
  # exact <-   ( getquery_d()$exact)
  # if (exact){
  #   return( getexactdrugvar() )
  # } else {
    return( getdrugvar() )
  # }
}

getbestaevar <- function(){
  # exact <-   ( getquery_e()$exact)
  # if (exact){
  #   return( getexactaevar() )
  # } else {
    return( getaevar() )
  # }
}


getbestterm1 <- function(quote=TRUE){
  # quote <-   ( getquery_d()$exact)
  return( getterm1( session))
}

getbestterm2 <- function(quote=TRUE){
  # quote <-   ( getquery_e()$exact)
  return( getterm2( session))
}

gettimerange <- reactive({
  geturlquery()
  mydates <- getstartend()
  start <- mydates[1]
  end <-  mydates[2]
  timerange <- paste0('[', start, '+TO+', end, ']')
  return(timerange)
})

#Functions

#Build a time series vector rolled up to month 
gettstable <- function(tmp){
  q <- geturlquery()
  if (!is.null(tmp) )
    {

    if (q$concomitant == TRUE){
      mydf <- data.frame(count=tmp$count, 
                         date= as.character( floor_date( ymd( (tmp[,1]) ), 'month' ) ), stringsAsFactors = FALSE )
    } else {
      mydf <- data.frame(count=tmp$count, 
                         date= as.character( floor_date( ymd( as.Date(as.POSIXct(tmp[,1], origin="1970-01-01")) ), 'month' ) ), stringsAsFactors = FALSE )
    }
    
    # browser()
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
    names(mydf) <- c('Date', i18n()$t('Count'), i18n()$t('Cumulative Count'))
    names <- c('v1','t1', 'v2' ,'t2', 'v3', 't3')
    values <- c( getbestdrugvar(), getbestterm1(), getbestaevar(), getbestterm2(), gettimevar() )
    mydf_d <- mydf
    mydf_d[,2] <- numcoltohyper(mydf[ , 2], mydates, names, values, type='R', mybaseurl = getcururl(), addquotes=TRUE )
    mydf_d[,3] <- numcoltohyper(mydf[ , 3], mycumdates, names, values, type='R', mybaseurl = getcururl(), addquotes=TRUE )
    #mydf[,2] <- '<b>b</b>'
  } else {
    mydf <- NULL
    mydf_d <- NULL
    mysum <- NULL
  }
mydf <- list(result=mydf, display=mydf_d, total= mysum)

return(mydf)
}

#Reactive queries


#Queries for drug, drug-event, event and all
getquery_de <- reactive({
  q <- geturlquery()
  getquery_d()
  getquery_e()
  if (q$concomitant == TRUE) {
    v <- c( '_exists_', '_exists_', getbestdrugvar(), getbestaevar() , gettimevar() )
    t <- c(getdrugvar(), getaevar(), getbestterm1(), getbestterm2(), gettimerange() ) 
    t[3] <- toupper(q$dename)
    t[4] <- toupper(q$ename)
    myurl <- buildURL(v, t, count=gettimevar() )
    mylist <- fda_fetch_p( session, myurl)
  }
  
  return( list( mydf=mylist, myurl=myurl) )
})  
  

getquery_d <- reactive({
  q <- geturlquery()

  if (q$concomitant == TRUE) {
    exactD <- input$useexactD
    if ( exactD=='exact' )
    {
      exact <- TRUE
      v <- c( '_exists_', '_exists_', getexactdrugvar(),  gettimevar() )
      t <- c( getdrugvar(), getaevar(), getterm1( session, quote=TRUE ), gettimerange() )
      t[3] <- toupper(q$dename)
      myurl <- buildURL(v, t, count=gettimevar() )
      mylist <- fda_fetch_p( session, myurl)
    } else {
      exact <- FALSE
      v <- c( '_exists_', '_exists_', getdrugvar(),  gettimevar() )
      t <- c( getdrugvar(), getaevar(), getterm1( session, quote=FALSE ), gettimerange() )
      t[3] <- toupper(q$dename)
      myurl <- buildURL(v, t, count=gettimevar())
      mylist <- fda_fetch_p( session, myurl)
    }
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    timed<-TimeseriesForDrugReports(q$t1, input$date1, input$date2)
    timedResult <- con$aggregate(timed)
    colnames(timedResult)[1]<-"time"
    mylist<-timedResult
    con$disconnect()
    # Redone
  }
 
  return( list( mydf=mylist) )
}) 



getquery_e <- reactive({
  q <- geturlquery()
  if (q$concomitant == TRUE) {
    exactE <- input$useexactE
    if ( exactE=='exact' )
    {
      exact <- TRUE
      v <- c( '_exists_', '_exists_', getexactaevar() , gettimevar() )
      t <- c( getaevar(), getdrugvar(), getterm2( session, quote=TRUE ), gettimerange() )  
      t[3] <- toupper(q$ename)
      myurl <- buildURL(v, t, count=gettimevar() )
    } else {
      exact <- FALSE
      exact <- FALSE
      v <- c( '_exists_', '_exists_', getaevar(),  gettimevar() )
      t <- c( getaevar(), getdrugvar(), getterm2( session, quote=FALSE ), gettimerange() )
      t[3] <- toupper(q$ename)
      myurl <- buildURL(v, t, count=gettimevar() )
    }
    mylist <- fda_fetch_p( session, myurl)
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    timev<-TimeseriesForEventReports(q$t2, input$date1, input$date2)
    timevResult <- con$aggregate(timev)
    colnames(timevResult)[1]<-"time"
    mylist<-timevResult
    con$disconnect()
    # Redone
  }
 
  return( list( mydf=mylist) )
})    

getquery_all <- reactive({
  q <- geturlquery()
  
  if (q$concomitant == TRUE) {
    v <- c( '_exists_', '_exists_', gettimevar() )
    t <- c(getdrugvar(), getaevar(), gettimerange() )
    myurl <- buildURL(v, t, count=gettimevar() )
    print(myurl)
    mydf <- fda_fetch_p( session, myurl)
    meta <- mydf$meta
    tmp <- mydf$result
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    timeall<-TimeseriesForTotalReports(input$date1, input$date2)
    timeallResult <- con$aggregate(timeall)
    colnames(timeallResult)[1]<-"time"
    tmp<-timeallResult
    con$disconnect()
    # Redone
  }
  
  
  mydfin <- gettstable(tmp)
  mydf <- list(result=mydfin$result, display=mydfin$display, total= mydfin$total)
  return(mydf)
})    

#*******************************************************
#Reactive Other
#*******************************************************

getvars_de <- reactive({
  
  q <- geturlquery()
  
  if (q$concomitant == TRUE) {
    mylist <- getquery_de()
    meta <- mylist$mydf$meta
    tmp <- mylist$mydf$result
    myurl <- mylist$myurl
  }  else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    # browser()
    timede<-TimeseriesForDrugEventReports(q$t1, q$t2, input$date1, input$date2)
    timedeResult <- con$aggregate(timede)
    colnames(timedeResult)[1]<-"time"
    tmp<-timedeResult
    con$disconnect()
    # Redone
  }

  
  mydfin <- gettstable(tmp)
  mydf <- list(result=mydfin$result, display=mydfin$display, total= mydfin$total)
  return(mydf)
}) 

getvars_e <- reactive({
  
  q <- geturlquery()
  
  if (q$concomitant == TRUE) {
    mylist <- getquery_e()
    meta <- mylist$mydf$meta
    tmp <- mylist$mydf$result
    myurl <- mylist$myurl
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    timee<-TimeseriesForEventReports(q$t2, input$date1, input$date2)
    timeeResult <- con$aggregate(timee)
    colnames(timeeResult)[1]<-"time"
    tmp<-timeeResult
    con$disconnect()
    # Redone
  }
  mydfin <- gettstable(tmp)
  mydf <- list(result=mydfin$result, display=mydfin$display, total= mydfin$total)
  return(mydf)
}) 

getvars_d <- reactive({
  q <- geturlquery()
  
  if (q$concomitant == TRUE) {
    mylist <- getquery_d()
    meta <- mylist$mydf$meta
    tmp <- mylist$mydf$result
    myurl <- mylist$myurl
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    timed<-TimeseriesForDrugReports(q$t1, input$date1, input$date2)
    timedResult <- con$aggregate(timed)
    colnames(timedResult)[1]<-"time"
    tmp<-timedResult
    con$disconnect()
    # Redone
  }
  
  
  mydfin <- gettstable(tmp)
  mydf <- list(result=mydfin$result, display=mydfin$display, total= mydfin$total)
  return(mydf)
})   

#Timerange string from 1 December 1999 to present
getstartend <- reactive({
  geturlquery()
  # start <- ('1989-06-30')
  # end <- as.character( Sys.Date() ) 
  start <- input$date1
  end <- input$date2
  return( c(start, end))
})

#Merger time series vectors
buildmergedtable <- reactive({
  q<- geturlquery()
  
  mydf1 <- getvars_de()$result
  mydf2 <- getvars_d()$result
  mydf3 <-getvars_e()$result
  mydf4 <- getquery_all()$result
  # browser()
  
  if ( length(mydf1)*length(mydf2)*length(mydf3)*length(mydf4)> 0 )
    { 
    mydf_d <- merge(mydf1[, c(1,3)], mydf2[, c(1,3)], by.x='Date', by.y='Date')
    names(mydf_d) <- c(i18n()$t('Date'), i18n()$t('Drug Event Counts'), i18n()$t('Drug Counts'))
    mydf_all <- merge(mydf3[, c(1,3)], mydf4[, c(1,3)], by.x='Date', by.y='Date')
    names(mydf_all) <- c(i18n()$t('Date'), i18n()$t('Event Counts'), i18n()$t('Total Counts'))
    mydf <- merge(mydf_d, mydf_all, by.x=i18n()$t('Date'), by.y=i18n()$t(i18n()$t('Date')))
    comb <- mydf[ mydf[ , i18n()$t('Event Counts') ] >0, ]
    comb <- comb[ comb[ ,i18n()$t('Total Counts') ] >2 , ]
    oldnames <- names(comb)
    nij <- comb[,i18n()$t('Drug Event Counts')]
    n.j <- comb[, i18n()$t('Drug Counts') ]
    ni. <- comb[, i18n()$t('Event Counts') ]
    n.. <- comb[, i18n()$t('Total Counts') ]
    prrci <- prre_ci( n.., ni., n.j, nij )
    comb <- data.frame(comb, prr=round(prrci[['prr']], 2), sd=round(prrci[['sd']], 2), lb=round(prrci[['lb']], 2), ub=round(prrci[['ub']], 2) )
    names(comb) <-c(oldnames, 'PRR', 'SD', 'LB', 'UB')
   start <- paste0( '[',  comb[,1], '01')
   start <- gsub('-', '', start)
   start[1] <- '[19060630'
   lastdate <- ymd(start[ length( start)] )
   month(lastdate) <- month(lastdate)+1
   mydates <- c( ymd(start[2:length(start)] ), lastdate  ) 
   mydates <- round_date(mydates, unit='month')
   mydates <- rollback(mydates)
   mydates <- gsub('-', '', as.character( mydates ))
   mycumdates <- paste0(start[1],  '+TO+', mydates ,']')
   
   
   v <- c( '_exists_', '_exists_', getbestdrugvar(), getbestaevar() , gettimevar() )
   t <- c(getdrugvar(), getaevar(), getbestterm1(), getbestterm2(), gettimerange() ) 
   
   names <- c('v1','t1', 'v2' ,'t2', 'v3', 't3')
   values <- c( getbestdrugvar(), getbestterm1(), getbestaevar(), getbestterm2(), gettimevar() )
   comb[,i18n()$t('Drug Event Counts')] <- numcoltohyper(comb[,i18n()$t('Drug Event Counts')], mycumdates, names, values, type='R', mybaseurl = getcururl(), addquotes=FALSE )
    
   names <- c('v1','t1', 'v2' ,'t2', 'v3', 't3')
   values <- c( getbestdrugvar(), getbestterm1(), '_exists_', getbestaevar(), gettimevar() )
   comb[,i18n()$t('Drug Counts')] <- numcoltohyper(comb[,i18n()$t('Drug Counts')], mycumdates, names, values, type='R', mybaseurl = getcururl(), addquotes=FALSE )
   
   names <- c('v1','t1', 'v2','t2', 'v3', 't3')
   values <- c( '_exists_', getbestdrugvar(), getbestaevar(), getbestterm2(), gettimevar() )
   comb[,i18n()$t('Event Counts')] <- numcoltohyper(comb[,i18n()$t('Event Counts')], mycumdates, names, values, type='R', mybaseurl = getcururl(), addquotes=TRUE )
  
   names <- c( 'v1','t1', 'v2','t2','v3', 't3')
   values <- c( '_exists_', getbestdrugvar(), '_exists_', getbestaevar(),  gettimevar() )
   comb[,i18n()$t('Total Counts')] <- numcoltohyper(comb[,i18n()$t('Total Counts')], mycumdates, names, values, type='R', mybaseurl = getcururl(), addquotes=TRUE )
   
    return(comb)
    } else {
      return(NULL)
    }
})

getcodruglist <- reactive({
  
  
  q<- geturlquery()
  
  if (q$concomitant == TRUE) {
    v <- c(getbestdrugvar(), getbestaevar())
    t <- c( getbestterm1(),  getbestterm2())
    t[1] <- toupper(q$dename)
    t[2] <- toupper(q$ename)
    myurl <- buildURL( v, t,
                       count= getexactdrugvar(), limit=999 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:999,]
    
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    coco<-CocomitantForDrugEventReports(q$t1, q$t2, input$date1, input$date2)
    cocoResult <- con$aggregate(coco)
    colnames(cocoResult)[1]<-"term"
    mydf<-cocoResult
    mydf <- mydf[1:999,]
    # Redone
  }
  
  mydf <- mydf[!is.na(mydf[,2]), ]
  mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
  return( list( mydf=mydf) )
})

getcoeventlist <- reactive({
 
  
  q<- geturlquery()
  
  if (q$concomitant == TRUE) {
    v <- c(getbestdrugvar(), getbestaevar())
    t <- c( getbestterm1(),  getbestterm2())
    t[1] <- toupper(q$dename)
    t[2] <- toupper(q$ename)
    myurl <- buildURL( v, t,
                       count= getexactaevar(), limit=999 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:999,]
    
  } else {
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    react<-ReactionsForDrugEventReports(q$t1, q$t2, input$date1, input$date2)
    reactResult <- con$aggregate(react)
    colnames(reactResult)[1]<-"term"
    mydf<-reactResult
    mydf <- mydf[1:999,]
    # Redone
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
  q<-geturlquery()
  if ( is.null( getterm1( session) ) ){
    return(data.frame( c(paste('Please enter a drug and event name'), '') ) )
  }
  # browser()
  if( whichcount=='D')
  {
    mylist <- getcodruglist()
   
  } else {
    mylist <- getcoeventlist()
    
  }
  con$disconnect()
  mydf <- mylist$mydf

  if(is.null(mydf) || length(mydf$cumsum)==0)
  {
    return(NULL)
  }
  # myurl <- mylist$myurl
  sourcedf <- mydf
  #    print(names(mydf))
  # browser()
#Drug Table
  if (whichcount =='D'){
    colname <- i18n()$t("Drug")
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
      mynames <- c(  colname, i18n()$t('Count'), i18n()$t('Cumulative Sum')) 
    }
    else {
      medlinelinks <- rep(' ', nrow( sourcedf ) )
      mynames <- c('-', colname, i18n()$t('Count'), i18n()$t('Cumulative Sum')) 
    }
    names <- c('v1','t1', 'v2', 't2')
    values <- c(getbestaevar(), getbestterm2(), getexactdrugvar() ) 
#Event Table
  } else {
    colname <- i18n()$t('Preferred Term')
    medlinelinks <- makemedlinelink(sourcedf[,1], 'M')          
    mydf <- data.frame( mydf) 
    mynames <- c(colname, i18n()$t('Count'), i18n()$t('Cumulative Sum') ) 
    names <- c('v1','t1', 'v2', 't2')
    values <- c(getbestdrugvar(), getbestterm1(), getexactaevar() ) 
  }
  mydf[,'count'] <- numcoltohyper(mydf[ , 'count' ], mydf[ , 'term'], names, values, mybaseurl = getcururl(), addquotes=TRUE )
  mydf[,'term'] <- coltohyper(mydf[,'term'], whichcount , mybaseurl = getcururl(), 
                              append= paste0( "&v1=", input$v1) )
  names(mydf) <- mynames

  return( list( mydf=mydf, sourcedf=sourcedf ) )
}   


getdrugeventtotal <- reactive({
  mysum <- getvars_de()$total
  return( mysum )
})

getdrugtotal <- reactive({
  mysum <- getvars_d()$total
  return( mysum )
})
geteventtotal <- reactive({
  mysum <- getvars_e()$total
  return( mysum )
})
getalltotal <- reactive({
  mysum <- getquery_all()$total
  return( mysum )
})


getts <- reactive({
  data <-  getvars_de()$result
  #Check date variable in the dataset to see whether it is in Date format
  #Assign variable you want to run CPA to x
  datax<-data[,2]
  myts <- zoo( datax, data[,1])
  return(myts)
})

updatevars <- reactive({
  input$update
  isolate( {
    updateTextInput(session, "t1", value=( input$drugname ) )
    updateTextInput(session, "t2", value= ( input$eventname ) )
  })
})

anychanged <- reactive({
  a <- input$t1
  b <- input$v1
  c <- input$t2
  d <- input$v2
  e <- input$useexactD
  f <- input$useexactE
})

output$downloadDataLbl1 <- output$downloadDataLbl2 <- 
  output$downloadDataLbl3 <- output$downloadDataLbl4 <- renderText({
  return(i18n()$t("Download Data in Excel format"))
})

output$downloadBtnLbl1 <- output$downloadBtnLbl2 <-
  output$downloadBtnLbl3 <- output$downloadBtnLbl4 <- renderText({
  return(i18n()$t("Download"))
})

#SETTERS
output$mymodal <- renderText({
  if (input$update > 0)
  {
    updatevars()    
    toggleModal(session, 'modalExample', 'close')
  }
  return('')
})
#****************************
#Display queries and meta data
#******************************
#**********Drugs in reports

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

output$coquery <- renderTable({  
  #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
  codrugs <- getcocountsD()$mydf
  if ( is.data.frame(codrugs) )
  { 
    return(codrugs) 
  } else  {
    return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )
  }  
}, sanitize.text.function = function(x) x)  

# output$coquery2 <- renderDataTable({  
#   #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codrugs <- getcocountsD()$mydf
#   if ( is.data.frame(codrugs) )
#   { 
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )
#   }  
# }, escape=FALSE) 


output$coquery2 <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  codrugs <- getcocountsD()$mydf
  codrugs <- codrugs[1:length(codrugs)-1]
  coquery2ForExcel<<-codrugs
  if (length(codrugs) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_dynprr", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    hide(id = "daterange")
    hide(id = "maintabs")
    hide(id = "dlcoquery2xlsrow")
    hide(id = "infocoquery2")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(codrugs) )
  { 
    codedrugsIndatatable=codrugs
  } else  {
    codedrugsIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  if (!is.null(input$sourceConcomReportUI)){
    if (input$sourceConcomReportUI){
      write.csv(codrugs,paste0(cacheFolder,values$urlQuery$hash,"_concocounts.csv"))
    }
    
    
  }
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      codedrugsIndatatable,
      options = list(
        autoWidth = TRUE,
        dom = 't',
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
  } else {
    return ( datatable(
      codedrugsIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE))
  }
},
  escape=FALSE)

output$show <- reactive({
  return(values$show)
})

output$coqueryE <- renderTable({  
  #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
  codrugs <- getcocountsE()$mydf
  if ( is.data.frame(codrugs) )
  { 
    return(codrugs) 
  } else  {
    return( data.frame(Term=paste( 'No Events for', getterm1( session ) ) ) )
  }  
}, sanitize.text.function = function(x) x)

# output$coqueryE2 <- renderDataTable({  
#   #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codrugs <- getcocountsE()$mydf
#   if ( is.data.frame(codrugs) )
#   { 
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No Events for', getterm1( session ) ) ) )
#   }  
# }, escape=FALSE)

output$coqueryE2 <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  codrugs <- getcocountsE()$mydf
  codrugs <- codrugs[1:length(codrugs)-1]
  coqueryE2ForExcel<<-codrugs
  if (length(codrugs) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
      # shinyjs::show(id = "myBox")
    }
  }
  else{
    createAlert(session, "nodata_dynprr", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    hide(id = "daterange")
    hide(id = "maintabs")
    hide(id = "dlcoqueryE2xlsrow")
    hide(id = "infocoqueryE2")
    return(NULL)
  }
  
  
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(codrugs) )
  { 
    codedrugsIndatatable=codrugs
  } else  {
    codedrugsIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  if (!is.null(input$sourceEventDataReportUI)){
    if (input$sourceEventDataReportUI){
      write.csv(codrugs,paste0(cacheFolder,values$urlQuery$hash,"_eventcounts.csv"))
    }
    
    
  }
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      codedrugsIndatatable,
      options = list(
        autoWidth = TRUE,
        dom = 't',
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       grlang,
                       enlang)
          # fromJSON(file = '../sharedscripts/datatablesGreek.json'), 
          # fromJSON(file = '../sharedscripts/datatablesEnglish.json'))
        )
      )
      ,  escape=FALSE,rownames= FALSE)
    )
  } else {
    return ( datatable(
      codedrugsIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       grlang,
                       enlang)
          # fromJSON(file = '../sharedscripts/datatablesGreek.json'), 
          # fromJSON(file = '../sharedscripts/datatablesEnglish.json'))
        )
      )
      ,  escape=FALSE,rownames= FALSE))
  }
  
  },  escape=FALSE)


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
  s <- getterm1( session, FALSE)
  if(s == '') {
    s <- 'None'
  }
  out <- paste( '<br><b>Drug Name:<i>', s, '</i></b><br><br>' )
  return(out)
})

output$eventname <- renderText({
  s <- getterm2( session, FALSE)
  if(s == '') {
    s <- 'None'
  }
  out <- paste( '<b>Event Term:<i>', s, '</i></b><br><br>' )
  return(out)
})

output$query_counts <- renderTable({  
#  if (input$t1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
    mydf <- buildmergedtable()
 #   print(head(mydf))
  if ( is.data.frame(mydf) )
    {
    return( mydf) 
  } else  {return(data.frame(Drug=paste( 'No events for drug', getterm1( session, FALSE) ), Count=0))}
    
  }, include.rownames = FALSE, sanitize.text.function = (function(x) x) )

# output$query_counts2 <- renderDataTable({  
#   #  if (input$t1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
#   mydf <- buildmergedtable()
#   #   print(head(mydf))
#   if ( is.data.frame(mydf) )
#   {
#     return( mydf) 
#   } else  {return(data.frame(Drug=paste( 'No events for drug', getterm1( session, FALSE) ), Count=0))}
# }, escape=FALSE )



output$query_counts2 <- DT::renderDT({
  mydf <- buildmergedtable()
  query_counts2ForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_dynprr", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    hide(id = "daterange")
    hide(id = "maintabs")
    hide(id = "dlquery_counts2xlsrow")
    hide(id = "infoquery_counts2")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(mydf) )
  { 
    mydfIndatatable=mydf
  } else  {
    mydfIndatatable= data.frame(Drug=paste( 'No events for drug', getterm1( session, FALSE) ), Count=0) }
  if (!is.null(input$sourceInDataReportUI)){
    if (input$sourceInDataReportUI){
      write.csv(mydfIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_prrcounts.csv"))
    }
    
    
  }
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      mydfIndatatable,
      options = list(
        autoWidth = TRUE,
        dom = 't',
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE
    )
    )
  } else {
    return ( datatable(
      mydfIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE
    ))
  }
  
},  escape=FALSE)



output$allquerytext <- renderText({ 
  mydf <- getquery_all()
  meta <- mydf$meta
  out <- paste('<h4>Meta Data</h4>',
               '<b>Last Update =</b>', meta$last_updated, 
               '<br><b>Total =</b>', prettyNum( mydf$total, big.mark=',' ), 'total reports',
               'for dates from', gettimerange(),
               '<br> <b>Query =</b>', removekey(  makelink(mydf$url) ) )
  return(out)
})

 output$drugeventquerytext <- renderText({ 
   mydf <- getvars_de()
    out <- paste('<b>Total =</b>', prettyNum( getdrugeventtotal(), big.mark=',' ), 'reports for', getterm1( session, FALSE), 'and' , getterm2( session, FALSE), 
                 'for dates from', gettimerange(),
             '<br><b>Query =</b>', removekey( makelink(mydf$url) ), '<br><br>' )
  return(out)
  })

output$eventquerytext <- renderText({ 
  mydf <- getvars_e()
  out <- paste('<b>Total =</b>', prettyNum( geteventtotal(), big.mark=',' ),  'reports for', getterm2( session, FALSE),
               'for dates from', gettimerange(),
               '<br><b>Query =</b>', removekey( makelink(mydf$url) ), '<br><br>' )
  return(out)
})

output$drugquerytext <- renderText({ 
  mydf <- getvars_d()
  meta <- mydf$meta
  out <- paste(
    '<br><b>Total =</b>', prettyNum( mydf$total, big.mark=',' ), 'reports for', getterm1( session, FALSE), 
    'for dates from', gettimerange(),
    '<br><b>Query =</b>', removekey( makelink(mydf$url) ), '<br><br>' )
  return(out)
} )

output$dlprr <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(prrForExcel, file, sheetName="prr")
  }
)
output$dlquery_counts2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(query_counts2ForExcel, file, sheetName="Report Counts")
  }
)
output$dlcoquery2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coquery2ForExcel, file, sheetName="Counts For Drugs")
  }
)
output$dlcoqueryE2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryE2ForExcel, file, sheetName="Counts For Events")
  }
)
output$prrplot <- renderPlot ({
  if(getterm1( session)!=""){
  mydf <- buildmergedtable()
  prrForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_dynprr", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    plot.new()
    hide(id = "daterange")
    hide(id = "maintabs")
    hide(id = "dlprrxlsrow")
    hide(id = "infoprrplot")
    return(NULL)
  }
  mydf <- mydf[ is.finite(mydf[ , 'SD' ] ) , ]  
  if ( getterm1( session, FALSE)==''  )
  {
    mydrugs <- 'All Drugs'
  }
  else 
  {
    mydrugs <- getterm1( session, FALSE)
  }
  if ( getterm2( session, FALSE)=='' )
  {
    myevents <- 'All Events'
  }
  else 
  {
    myevents <- getterm2( session, FALSE)
  }
  
  if ( !is.null(mydf) & getterm1( session, FALSE)!='' & getterm2( session, FALSE)!='' )
    {
    
    if ( nrow(mydf) >0 )
      {
      showdates <- seq( as.Date( input$date1 ), as.Date( input$date2 ), 'months' )
      # browser()
      showdates <- substr(showdates, 1, 7)
      mydf <- mydf[mydf[ , i18n()$t('Date') ] %in% showdates,]
      myylim <- c( min(.5, min(mydf$LB)), max(2, max(mydf$UB) ) )
      xloc <- ymd( mydf[ , i18n()$t('Date') ], truncated=2 )
      labs <- mydf[ , i18n()$t('Date') ]
      
      lbgap <-   exp(log(mydf$LB) + .96*mydf$SD) #exp ( log( prr ) - 1.96*sd )
      ubgap <-   exp(log(mydf$UB) - .96*mydf$SD)
   #   title <- paste( 'PRR Plot for', input$t1,  'and', input$t2 )    
      if ( getterm1( session, FALSE)==''  )
      {
        mydrugs <- 'All Drugs'
      }
      else 
      {
        mydrugs <- getterm1( session, FALSE)
      }
      if ( getterm2( session, FALSE ) =='' )
      {
        myevents <- 'All Events'
      }
      else 
      {
        myevents <- getterm2( session, FALSE )
      }
      # mytitle <- paste( "PRR Plot for", mydrugs, 'and', myevents )
      mytitle <- stri_enc_toutf8(i18n()$t("PRR Plot"))
      plot( xloc, mydf$PRR, ylim=myylim, ylab=i18n()$t("95% Confidence Interval for PRR"),lwd = 0.2,
            xlab='', las=2, xaxt='n', bg='red', cex=0.7, cex.main=1, cex.lab=1,cex.axis=1,  main=mytitle, pch=21,col.lab="#929292", col="#929292",col.axis="#929292",col.main="#929292",font.main = 1)
      
      axis(1, at=xloc[index(xloc)%%6==0], labels=labs[index(labs)%%6==0], las=2, col.lab="#929292",col="#929292" ,col.axis="#929292",col.main="#929292"  )
      
      if( ! isTRUE( all.equal(mydf$PRR, mydf$LB) ) )
      {
        arrows(x0=xloc[ mydf$PRR!=mydf$LB ], x1=xloc[ mydf$PRR!=mydf$LB ],
               y0=lbgap[ mydf$PRR!=mydf$LB ], y1=mydf$LB[ mydf$PRR!=mydf$LB ], angle=90, length=.025,col="#929292")
        arrows(x0=xloc[ mydf$PRR!=mydf$UB ], x1=xloc[ mydf$PRR!=mydf$UB ],
               y1=mydf$UB[ mydf$PRR!=mydf$UB ], y0=ubgap[ mydf$PRR!=mydf$UB ], angle=90, length=.025,col="#929292")
      }
      abline(h=1, col="#ff7f0e")
      grid()
      
      #save plot
      if (!is.null(input$sourcePlotReportUI)){
        if (input$sourcePlotReportUI){
          png(filename = paste0(cacheFolder,values$urlQuery$hash,"_prrplot.png"),width = 900, height = 500, units = "px", pointsize = 12,)
          mytitle <- stri_enc_toutf8(i18n()$t("PRR Plot"))
          plot( xloc, mydf$PRR, ylim=myylim, ylab=i18n()$t("95% Confidence Interval for PRR"),lwd = 0.2,
                xlab='', las=2, xaxt='n', bg='red', cex=0.7, cex.main=1, cex.lab=1,cex.axis=1,  main=mytitle, pch=21,col.lab="#929292", col="#929292",col.axis="#929292",col.main="#929292",font.main = 1)
          
          axis(1, at=xloc[index(xloc)%%6==0], labels=labs[index(labs)%%6==0], las=2, col.lab="#929292",col="#929292" ,col.axis="#929292",col.main="#929292"  )
          
          if( ! isTRUE( all.equal(mydf$PRR, mydf$LB) ) )
          {
            arrows(x0=xloc[ mydf$PRR!=mydf$LB ], x1=xloc[ mydf$PRR!=mydf$LB ],
                   y0=lbgap[ mydf$PRR!=mydf$LB ], y1=mydf$LB[ mydf$PRR!=mydf$LB ], angle=90, length=.025,col="#929292")
            arrows(x0=xloc[ mydf$PRR!=mydf$UB ], x1=xloc[ mydf$PRR!=mydf$UB ],
                   y1=mydf$UB[ mydf$PRR!=mydf$UB ], y0=ubgap[ mydf$PRR!=mydf$UB ], angle=90, length=.025,col="#929292")
          }
          abline(h=1, col="#ff7f0e")
          grid()
          dev.off()
        }
        
      }
      
    }
  } else  {
    mytitle <-  i18n()$t("Please select a drug and event") 
    plot( c(0,1), c(0,1),  main=mytitle )
    text(.5, .5, i18n()$t("Please select a drug and event"))
  }
  
  
}
else{
  # s1 <- calccpmean()
  geturlquery()
  return (NULL)
}
})


output$querytitle <- renderText({ 
  return( paste('<h4>Counts for', getterm1( session, FALSE), 'with event "', getterm2( session, FALSE), '"</h4>') )
})


#URL Management 
getcururl <- reactive({
  mypath <- extractbaseurl( session$clientData$url_pathname )
  s <- paste0( session$clientData$url_protocol, "//", session$clientData$url_hostname,
               ':',
               session$clientData$url_port,
               mypath )
  return(s)
})

output$applinks <- renderText({ 
  return( makeapplinks(  getcururl(), getqueryvars() )  )
})

# output$date1 <- renderText({
#   l <- getdaterange()
# 
#   paste( '<b>Reports from', as.Date(l[1],  "%Y%m%d")  ,'to', as.Date(l[2],  "%Y%m%d"), '</b>')
# })



geturlquery <- reactive({
  q <- parseQueryString(session$clientData$url_search)
  # q<-NULL
  # q$v1<-"patient.drug.openfda.generic_name"
  # q$v2<-"patient.reaction.reactionmeddrapt"
  # q$t1<-"L04AB02"
  # q$t2<-"10003239"
  # q$hash <- "ksjdhfksdhfhsk"
  # q$concomitant<- FALSE
  # browser()
  updateSelectizeInput(session, inputId = "v1", selected = q$drugvar)
  updateTextInput(session, "t1", value=q$term1)
  updateTextInput(session,"t2", value=q$term2) 
  updateTextInput(session, "drugname", value=q$term1)
  updateTextInput(session,"eventname", value=q$term2) 
  updateDateRangeInput(session,'daterange',  start = input$date1, end = input$date2)
  # updateDateInput(session, 'date1', value = q$start)
  # updateDateInput(session, 'date2', value = q$end)
  updateSelectizeInput(session, inputId = "v1", selected = q$v1)
  updateTextInput(session, "t1", value=q$t1)
  updateTextInput(session,"t2", value=q$t2) 
  updateTextInput(session, "drugname", value=q$t1)
  updateTextInput(session,"eventname", value=q$t2)
  updateDateRangeInput(session,'daterange',  start = input$date1, end = input$date2)
  # updateDateInput(session, 'date1', value = q$start)
  # updateDateInput(session, 'date2', value = q$end)
  updateRadioButtons(session, 'useexact',
                     selected = if(length(q$useexact)==0) "exact" else q$useexact)
  updateRadioButtons(session, 'useexactD',
                     selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
  updateRadioButtons(session, 'useexactE',
                     selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
  con_atc <- mongo("atc", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
  drug <- con_atc$find(paste0('{"code" : "',q$t1,'"}'))
  con_atc$disconnect()
  
  q$dename <- drug$names[[1]][1]
  
  con_medra <- mongo("medra", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
  event <- con_medra$find(paste0('{"code" : "',q$t2,'"}'))
  con_medra$disconnect()
  
  q$ename <- event$names[[1]][1]
  values$urlQuery<-q
  return( q )
})



output$urlquery <- renderText({ 
  return( getcururl()  )
  })

output$CountsForEventsInSelectedReports <- renderUI({ 
  # HTML(stri_enc_toutf8(i18n()$t("Counts for events in selected reports")))
  HTML(stri_enc_toutf8(i18n()$t("Events in scenario reports")))
  
})
output$CountsForDrugsInSelectedReports <- renderUI({ 
  # HTML(stri_enc_toutf8(i18n()$t("Counts for drugs in selected reports")))
  HTML(stri_enc_toutf8(i18n()$t("Drugs in scenario reports")))
  
})
output$ReportCountsandPRR <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Report counts and PRR")))
  
})
output$About <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("About")))
  
})
output$DataReference <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Data Reference")))
  
})
output$OtherApps <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Other Apps")))
  
})
output$MetaDataandQueries <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("MetaData and Queries")))
  
})
output$PRROverTime <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("PRR over time")))
  
})
output$PlotPRRbetween <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Plot PRR between")))
  
})

i18n <- reactive({
  selected <- input$selected_language
  if (length(selected) > 0 && selected %in% translator$languages) {
    translator$set_translation_language(selected)
  }
  translator
})

# output$to <- renderText({ 
#  'to'
# })

output$infoprrplot<-renderUI({
  addPopover(session=session, id="infoprrplot", title="Proportional Reporting Ratio", 
             content=paste(i18n()$t("prr explanation"),"<br><br>",i18n()$t("dynprr explanation")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$sourceInDataReport<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceInDataReportUI", "Save data")
})

observeEvent(input$sourceInDataReportUI,{
  
  if (!is.null(input$sourceInDataReportUI))
    if (!input$sourceInDataReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_prrcounts.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceConcomReport<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceConcomReportUI", "Save data")
})

observeEvent(input$sourceConcomReportUI,{
  
  if (!is.null(input$sourceConcomReportUI))
    if (!input$sourceConcomReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_concocounts.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourcePlotReport<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourcePlotReportUI", "Save plot")
})

observeEvent(input$sourcePlotReportUI,{
  
  if (!is.null(input$sourcePlotReportUI))
    if (!input$sourcePlotReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_prrplot.png")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

output$sourceEventDataReport<-renderUI({
  if (!is.null(values$urlQuery$hash))
    checkboxInput("sourceEventDataReportUI", "Save data")
})

observeEvent(input$sourceEventDataReportUI,{
  
  if (!is.null(input$sourceEventDataReportUI))
    if (!input$sourceEventDataReportUI){
      fileName<-paste0(cacheFolder,values$urlQuery$hash,"_eventcounts.csv")
      if (file.exists(fileName)) {
        #Delete file if it exists
        file.remove(fileName)
      }
    }
})

observeEvent(input$date1, {
  
  if (abs(input$date2-input$date1)>365){
    updateDateInput(session, "date2",
                    value=input$date1+365
    )
  }
})

observeEvent(input$date2, {
  
  if (abs(input$date2-input$date1)>365){
    updateDateInput(session, "date1",
                    value=input$date1-365
    )
  }
})


output$infoquery_counts2<-renderUI({
  addPopover(session=session, id="infoquery_counts2", title=i18n()$t("Time Series"), 
             content=paste(i18n()$t("Monthly and cumulative counts for drug-event combination"),"<br><br>",i18n()$t("prr explanation"), "<br><br>",i18n()$t("sd,lb,up explanation")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$infoall2<-renderUI({
  addPopover(session=session, id="infoall2", title="Frequency Table", 
             content=stri_enc_toutf8(i18n()$t("All Counts for Drugs")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$infocoqueryE2<-renderUI({
  addPopover(session=session, id="infocoqueryE2", title=i18n()$t("Info"), 
             content=stri_enc_toutf8(i18n()$t("Frequency table for events found in selected reports")), placement = "left",
             # content=stri_enc_toutf8(i18n()$t("Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations. \"L\" is linked to SPL labels for Drug in openFDA. \"D\" is linked to a dashboard display for a drug.")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

output$infocoquery2<-renderUI({
  addPopover(session=session, id="infocoquery2", title=i18n()$t("Info"), 
             content=stri_enc_toutf8(i18n()$t("Frequency table for events found in selected reports")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})
output$infoindquery2<-renderUI({
  addPopover(session=session, id="infoindquery2", title="Reported Indication for Drug", 
             content=stri_enc_toutf8(i18n()$t("Frequency table of reported indication for which the drug was administered.  Indication is linked to medline dictionary definition for event term")), placement = "left",
             trigger = "hover", options = list(html = "true"))
  return(HTML('<button type="button" class="btn btn-info">i</button>'))
})

}) #End shinyServer
