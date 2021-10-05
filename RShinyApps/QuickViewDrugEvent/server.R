require(shiny)
# library(shinyalert)
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
require(wordcloud)
library(shiny)
library(shiny.i18n)
library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)
library(DT)
library("rjson")
library(RJSONIO)
library(plotly)
library(webshot)
library(htmltools)
library(magrittr)
library(pins)
library(webshot)
library(htmlwidgets)


translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')

# i18n$set_translation_language("gr")

#source('helperfunctions.r')


source('sourcedir.R')


shinyServer(function(input, output, session) {
  
  # cacheFolder<-"/var/www/html/openfda/media/"
  cacheFolder<- "C:/Users/dimst/Desktop/work_project/"
  

  values<-reactiveValues(urlQuery=NULL)
  ckbx <- reactiveValues(cb1=FALSE)
  
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
    
    # removeUI(
    #   selector = "#daterange",
    #   multiple = FALSE
    # )
    # 
    # insertUI(
    #   selector = "#dtlocator",
    #   where = "beforeBegin",
    #   ui = dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]], separator=i18n()$t("to"))
    # )
    
  })
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
  output$info<-renderUI({
    addPopover(session=session, id="info", title=i18n()$t("Application Info"), 
               content=stri_enc_toutf8(i18n()$t("descriptionList")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  }) 
  getbestaevar <- function(){
    exact <-   ( getexactvals()$exacte)
    if (exact){
      return( getexactaevar() )
    } else {
      return( getaevar() )
    }
  }


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
    
    geturlquery()
    toggleModal(session, 'updatemodal', 'close')
    v1 <- getbestdrugvar()
    t1 <- c(getbestterm1() )
    myurl <- buildURL(v1, t1, count='', limit=5 )
    mydf <- fda_fetch_p( session, myurl, wait = getwaittime())
    # browser()
    mydf <- list(result=mydf$result, url=myurl, meta=mydf$meta)
    # browser()
    return(mydf)
  })

  gettotaldaterangequery <- reactive({
    
    geturlquery()
    v1 <- c( getbestdrugvar(), gettimevar() )
    t1 <- c(getbestterm1(), gettimerange() )
    myurl <- buildURL(v1, t1, count='', limit=5)
    mydf <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=4)
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
    q <- geturlquery()
    
    if (q$concomitant == TRUE){
      
      # v <- c( getbestdrugvar(), getbestaevar() , gettimevar() )
      v <- c( q$v1, getbestaevar() , gettimevar() )
      t <- c( getbestterm1(), getbestterm2(), gettimerange() )
      if (t[1] == q$t1){
        t[1]<-toupper(paste0('"',q$dename,'"'))
      }
      if (!is.null(q$t2)){
        t[2]<-toupper(q$ename)
      }
      
      myurl <- buildURL(v, t, count=gettimevar() )
      out <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=5 )
      # browser()
      if (length(out)==0){
        v <- c( "patient.drug.openfda.generic_name", getbestaevar() , gettimevar() )
        t <- c( getbestterm1(), getbestterm2(), gettimerange() )
        if (t[1] == q$t1){
          t[1]<-toupper(paste0('"',q$dename,'"'))
        }
        if (!is.null(q$t2)){
          t[2]<-toupper(q$ename)
        }
        myurl <- buildURL(v, t, count=gettimevar() )
        out <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=5 )
      }
      
    } else {
      # Refactor
      con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
      
      query<-createDateAllQuery(input$date1, input$date2)
      result <- con$aggregate(query)

      colnames(result)[1]<-"time"
      result$time <- as.Date(result$time, tz = "HST")
      out<-result
      con$disconnect()
      # Redone
    }
    

    
    # browser()
    return( list(out=out ) )
  })

  getquerydata <- reactive({
    q<- geturlquery()
    mydf <- getqueryde()
    if (q$concomitant == TRUE){
      tmp <- mydf$out$result
    } else {
      tmp <- mydf$out
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
    v <- c(getbestdrugvar(), getbestaevar())
    t <- c( getbestterm1(),  getbestterm2())
    myurl <- buildURL( v, t,
                       count= getexactdrugvar(), limit=999 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:999,]
    mydf <- mydf[!is.na(mydf[,2]), ]
    mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
    return( list( mydf=mydf, myurl=myurl) )
  })

  getcoeventlist <- reactive({
    v <- c(getbestdrugvar(), getbestaevar())
    t <- c( getbestterm1(),  getbestterm2())
    myurl <- buildURL( v, t,
                       count= getexactaevar(), limit=999 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:999,]
    mydf <- mydf[!is.na(mydf[,2]), ]
    mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
    return( list( mydf=mydf, myurl=myurl) )
  })

  # getcocountsE <- reactive({
  # 
  #   return( getcocounts('E') )
  # })
  # 
  # getcocountsD <- reactive({
  # 
  #   return( getcocounts('D') )
  # })


  gettstable <- function( tmp ){
    if ( length(tmp)!=0  )
    {

      mydf <- data.frame(count=tmp$count,
                         date= as.character( floor_date( ymd( (tmp[,1]) ), 'month' ) ), stringsAsFactors = FALSE )
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
      names(mydf) <- c(i18n()$t("Date"), i18n()$t("Count"), i18n()$t("Cumulative Count"))
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

  getts <- reactive({
    data <-  getquerydata()$mydfin$result
    # browser()
    ( mydates <- ymd(data[,i18n()$t("Date")] ) )
    ( mymonths <- month( ymd(data[,i18n()$t("Date")], truncated=2 ) ) )
    ( myyears <- year( ymd(data[,i18n()$t("Date")], truncated=2 ) ) )
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

  output$query <- renderTable({
    fetchalldata()
    #   if (input$term1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
    mydf <- getquerydata()$mydfin
    if ( is.data.frame(mydf$display) )
    {
      return(mydf$display)
    } else  {return(data.frame(Drug=paste( 'No events for drug', input$term1), Count=0))}
  }, include.rownames = FALSE, sanitize.text.function = function(x) x)
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
  
  
  output$cpmeantext <- renderText ({
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
      out <- paste( 'Changepoint type      : Change in', s@cpttype, '<br>' )
      out <- paste(out,  'Method of analysis    :' , s@method , '<br>' )
      out <- paste(out, 'Test Statistic  :' , s@test.stat, '<br>' )
      out <- paste(out, 'Type of penalty       :' , s@pen.type, 'with value', round(s@pen.value, 6), '<br>' )
      out <- paste(out, 'Maximum no. of cpts   : ' , s@ncpts.max, '<br>' )
      out <- paste(out, 'Changepoint Locations :' , mycpts , '<br>' )
      if(!is.null(session$calclert))
      {
        closeAlert(session, 'calclert')
      }
    } else {
      out <- "Insufficient data"
    }
    return(out)
  })
  output$infocpmeantext <- renderUI ({
    mydf <-getquerydata()$mydfin
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
               content=paste(out,i18n()$t('changepoint explanation'),i18n()$t('Change in mean analysis explanation')), placement = "left",
               trigger = "hover", options = list(html = "true"))
    #attr(session, "cpmeanplottext") <- out
    # browser()
    # l <- append( l, c('cpmeanplottext' =  out ) )
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
    
  })
  
  output$downloadDataLbl <- renderText({
    return(i18n()$t("Download Data in Excel format"))
  })
  
  output$downloadBtnLbl <- renderText({
    return(i18n()$t("Download"))
  })
  
  output$dl <- downloadHandler(
    filename = function() { "Data.xlsx"},
    content = function(file) {
      write.xlsx(cpmeanForExcel, file, sheetName="cpmeanplot")
    }
  )
  output$cpmeanplot <- renderPlotly ({
    q<- geturlquery()
    
    # con <- mongo("atc", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    # drug <- con$find(paste0('{"code" : "',q$t1,'"}'))
    # con$disconnect()
    # con_med <- mongo("medra", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    # event <- con_med$find(paste0('{"code" : "',q$t2,'"}'))
    # con_med$disconnect()
    if(getterm1( session)!=""){
      mydf <-getquerydata()$mydfin$result
      cpmeanForExcel<<-mydf
      # write.xlsx(mydf, "../mydf.xlsx")
      if (length(mydf) > 0)
      {
        if(!is.null(session$nodataAlert))
        {
          closeAlert(session, "nodataAlert")
        }
        # closeAlert(session, "nodataAlert")
        ckbx$cb1 <- TRUE
        s1 <- calccpmean()
        labs <-    index( getts() )
        pos <- seq(1, length(labs), 3)
  
        if ( getterm1( session, FALSE )==''  )
        {
          mydrugs <- i18n()$t("All Drugs")
        }
        else
        {
          # mydrugs <- getterm1( session, FALSE )
          mydrugs <- q$dename
        }
        if ( getterm2( session, FALSE )=='' )
        {
          myevents <- i18n()$t("All Events")
        }
        else
        {
          myevents <- getterm2( session, FALSE )
          myevents <- q$ename
        }
        mytitle <- paste( i18n()$t("Change in mean analysis for"), mydrugs, i18n()$t("and"), myevents )
        #mytitle <- i18n()$t("Change in mean analysis")
        # par(bg = "gray")
        # plot(s, xaxt = 'n', ylab=i18n()$t("Count"), xlab='', main=mytitle)
        # axis(1, pos,  labs[pos], las=2  )
        # grid(nx=NA, ny=NULL,col = "lightgray")
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
        # browser()
        # p <- dygraph(don,main = "Change in mean analysis") %>%
        #   dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="grey") %>%
        #   # dySeries("V1", drawPoints = TRUE, pointShape = "square", color = "blue")
        #   dyRangeSelector() %>%
        #   # dyLimit(s@param.est$mean[2],label = "Y-axis Limit",color = "red",strokePattern = "dashed")%>%
        #   dyCrosshair(direction = "vertical") %>%
        #   dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
        #   dyRoller(rollPeriod = 1)
        #   # %>%
        #   # dyLimit(s1@cpts[2], color = "red")
        # p
        
        f <- list(
          family = "Helvetica Neue, Roboto, Arial, Droid Sans, sans-serif!important",
          color = '#667', 
          size = 13
        )
        datetimeValues <- ymd(Dates2)
        values2 =values$x
        data <- data.frame(datetimeValues, values)
        
        # jpeg(filename="rplot.jpg")
        
        # plot_ly() %>%
        #   config(
        #     toImageButtonOptions = list(
        #       format = "svg",
        #       filename = "myplot",
        #       width = 600,
        #       height = 700
        #     )
        #   )
        # png(filename = 'dasdjha.png')
        p <- plot_ly(x = attr(s1@data.set,'index'),showlegend=FALSE)
        p <- p %>% add_trace(x = attr(s1@data.set,'index'), y = values2,type = 'scatter', mode = 'lines',line = list(color = '#929292'))
        p <- p %>% layout(title = i18n()$t(mytitle),titlefont = f)
        p <- p %>% layout(yaxis = list(
          title = i18n()$t("Count"),
          titlefont = f
        ))
        #Save image for report
                
        range_0<-1   
        for (i in 1:(length(s1@param.est$mean))){
          mean_i<-s1@param.est$mean[i]
          range_1<-s1@cpts[i]
          limit1<-c(rep(mean_i, (range_1-range_0+1) ))
          x_range<-attr(s1@data.set,'index')[range_0:range_1]
          t1<-paste(length(x_range),length(limit1))
          p <- p %>% add_trace(x=x_range,y = limit1, type = 'scatter', mode = 'lines',line = list(color = '#ff7f0e'))
          
          range_0<-range_1
        }
        
        # p
        
        if (!is.null(input$sourcePlotReportUI)){
          if (input$sourcePlotReportUI){
            # withr::with_dir("/var/www/html/openfda/media", orca(p, paste0(q$hash,"_timeseries.png")))
            saveWidget(as_widget(p), "temp.html")
            webshot("temp.html", file = paste0(cacheFolder,q$hash,"_timeseries.png"), cliprect = "viewport")
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
        hide("PRRRORPanel")
        hide("daterange")
        hide("prr2")
        hide("infocpmeantext")
        hide("xlsrow")
        hide("sourcePlotReport")
        hide("sourceDataframe")
        createAlert(session, "nodata_qvde", "nodataAlert", title = i18n()$t("Info"),
                     content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
        # shinyalert("Oops!", "Something went wrong.", type = "error")
      }
      
    }
    else{
      s1 <- calccpmean()
      return (NULL)
    }
    # orca(p, "test.png")
    # htmlwidgets::saveWidget(p, "date.html")
    # png <- plotly_IMAGE(p, out_file = "plotly-test-image.png")
    
  })
  

  output$cpvartext <- renderText ({
    mydf <-getquerydata()$mydfin$result
    if (length(mydf) > 0)
    {
      s <- calccpvar()
      mycpts <- attr( s@data.set, 'index')[s@cpts[1:length(s@cpts)-1] ]
      mycpts <-paste(mycpts, collapse=', ')
      out <- paste( 'Changepoint type      : Change in', s@cpttype, '<br>' )
      out <- paste(out,  'Method of analysis    :' , s@method , '<br>' )
      out <- paste(out, 'Test Statistic  :' , s@test.stat, '<br>' )
      out <- paste(out, 'Type of penalty       :' , s@pen.type, 'with value', round(s@pen.value, 6), '<br>' )
      out <- paste(out, 'Maximum no. of cpts   : ' , s@ncpts.max, '<br>' )
      out <- paste(out, 'Changepoint Locations :' , mycpts , '<br>' )
      return(out)
    } else {
      return ( 'Insufficient Data' )
    }
  })

  output$cpvarplot <- renderPlot ({
    mydf <-getquerydata()$mydfin$result
    if (length(mydf) > 0)
    {
      s <- calccpvar()
      labs <-    index( getts() )
      pos <- seq(1, length(labs), 3)
      if ( getterm1( session, FALSE ) == ''  )
      {
        mydrugs <- i18n()$t("All Drugs")
      }
      else
      {
        mydrugs <- getterm1( session,FALSE)
      }
      if ( getterm2( session,FALSE)=='' )
      {
        myevents <- i18n()$t("All Events")
      }
      else
      {
        myevents <- getterm2( session,FALSE)
      }
      # mytitle <- paste( "Change in Variance Analysis for", mydrugs, 'and', myevents )
      mytitle <- i18n()$t("Change in variance analysis")
      plot(s, xaxt = 'n', ylab=i18n()$t("Count"), xlab='', main=mytitle)
      axis(1, pos,  labs[pos], las=2  )
      grid(nx=NA, ny=NULL)
      abline(v=pos, col = "lightgray", lty = "dotted",
             lwd = par("lwd") )
    }
  })

  output$cpbayestext <- renderPrint ({
    mydf <-getquerydata()$mydfin$result
    if (length(mydf) > 0)
    {
      mycp <- calccpbayes()
      data <- mycp$data
      bcp.flu <- mycp$bcp.flu
      data$postprob <- bcp.flu$posterior.prob
      data2<-data[order(data$postprob,decreasing = TRUE),]
      data2[1:input$maxcp,]
    } else {
      return ( 'Insufficient Data', file='' )
    }
  })
  output$cpbayesplot <- renderPlot ({
    mydf <-getquerydata()$mydfin$result
    if (length(mydf) > 0)
    {
      s <- calccpbayes()$bcp.flu
      labs <-    index( getts() )
      plot(s)
      grid()
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
  
  
  output$PRRRORResults <- renderUI({
    HTML(stri_enc_toutf8(i18n()$t("PRR and ROR Results")))

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
    # q$t1<-"J01CA04"
    # q$t2<-"10037844"
    # q$t1<-"A02BC01"
    # q$t2<-"10021015"
    # q$t1<-"G01AE10"
    # q$t2<-"10079622"
    # q$hash <- "ksjdhfksdhfhsk"
    # q$concomitant <- FALSE
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
    updateDateRangeInput(session,'daterange',  start = input$date1, end = input$date2)
    updateNumericInput(session,'maxcp', value=q$maxcps)
    updateNumericInput(session,'maxcp2', value=q$maxcps)
    updateRadioButtons(session, 'useexact',
                       selected = if(length(q$useexact)==0) "exact" else q$useexact)
    updateRadioButtons(session, 'useexactD',
                       selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
    updateRadioButtons(session, 'useexactE',
                       selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
    if (q$v1=="patient.drug.openfda.generic_name"){
      con_atc <- mongo("atc", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
      drug <- con_atc$find(paste0('{"code" : "',q$t1,'"}'))
      con_atc$disconnect()
      
      q$dename <- drug$names[[1]][1]
      if (!is.null(q$v2)){
        
        con_medra <- mongo("medra", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
        event <- con_medra$find(paste0('{"code" : "',q$t2,'"}'))
        con_medra$disconnect()
        
        q$ename <- event$names[[1]][1]
        
      } else {
        q$ename <- NULL
      }
    } else {
      con_medra <- mongo("medra", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
      event <- con_medra$find(paste0('{"code" : "',q$t1,'"}'))
      con_medra$disconnect()
      
      q$dename <- event$names[[1]][1]
    }
    values$urlQuery<-q
    # print(values$urlQuery)
    return(q)
  })

  getdrugname <- reactive({
    #    print(input$usepopcb)
    s <- toupper(input$t1)
    if  (is.null(s) | s=="" ) {
      return("")
    }
    names <- s
    # names <- paste0(names, collapse=' ')
    # con <- mongo("atc", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    # names <- con$find(paste0('{"code" : "',s,'"}'))
    # con$disconnect()
    names <- paste0(names, collapse=' ')
    return(names)
  })
  
  getquoteddrugname <- reactive({ 
    s <- getdrugname()
    if  (is.null( s ) | s=="" ) {
      return("")
    }
    names <- paste0('%22', s, '%22')
    names <- paste0(names, collapse=' ')
    return(names)
  })
  
  getbestdrugname <- function(quote=TRUE){
    exact <-   ( getdrugcounts999()$exact)
    if (exact)
    {
      return( getquoteddrugname() )
    } else {
      return( getdrugname() )
    }
  }
  getdrugvarname <- reactive({
    return(input$v1)
  })
  geteventvarname <- reactive({
    return(   "patient.reaction.reactionmeddrapt.exact" )
  })
  getexactdrugvarname <- reactive({
    return( paste0(input$v1, '.exact') )
  })
  getbestdrugvarname <- function(){
    anychanged()
    exact <-   ( getdrugcounts999()$exact)
    if (exact){
      return( getexactdrugvarname() )
    } else {
      return( getdrugvarname() )
    }
  }
  

  #************************************
  # Get source Query
  #*********************

  getsourcecounts <- reactive({
    #   1 = Physician
    #   2 = Pharmacist
    #   3 = Other Health Professional
    #   4 = Lawyer
    #   5 = Consumer or non-health professional

    geturlquery()
    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                      count="primarysource.qualification" )
    mydf <- fda_fetch_p( session, myurl)$result
    mydf[,3] <- mydf[,1]
    mydf[ mydf[,1]==1 , 1] <- 'Physician'
    mydf[ mydf[,1]==2 , 1] <- 'Pharmacist'
    mydf[ mydf[,1]==3 , 1] <- 'Other Health Professional'
    mydf[ mydf[,1]==4 , 1] <- 'Lawyer'
    mydf[ mydf[,1]==5 , 1] <- 'Consumer or non-health...'
    mydf <- mydf[order(mydf[,2]), ]

    return( mydf )
  })

  #************************************
  # Get Drug-Event Query
  #*********************

  getdrugcounts999 <- reactive({

    q<-geturlquery()
    # browser()
    mylist <- getcounts999 ( session, v= getexactdrugvarname(), t= geteventvarname( session, quote = FALSE ),
                             count=geteventvarname(), limit=999, exactrad=input$useexact, counter=1, eventName=q$t2, drugNameOrg = q$dename )
    return( list(mydf=mylist$mydf, myurl=(mylist$myurl), exact = mylist$exact  ) )
  })


  #Build table containing drug-event pairs
  getdrugcountstable <- reactive({
    
    geturlquery()
    mydf <- getdrugcounts()
    myurl <- mydf$myurl
    mydf <- mydf$mydf
    sourcedf <- mydf
    mydf <- data.frame( rep('M', nrow(mydf) ), mydf )
    mydf[,1] <- makemedlinelink(mydf[,2], mydf[,1])
    names <- c('v1','t1' ,'v2', 't2')
    values <- c(getbestdrugvarname(), getbestdrugname(), geteventvarname() )
    mydf[,3] <- numcoltohyper(mydf[ , 3], sourcedf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,2] <- coltohyper(mydf[,2], 'E', mybaseurl = getcururl(),
                           append= paste0( "&v1=", input$v1) )
    return( list(mydf=mydf, myurl=(myurl),  sourcedf=sourcedf  ) )
  })

  #Get total counts in database for each event and Total reports in database
  gettotals<- reactive({
    q <- geturlquery()
    
    if (q$concomitant == TRUE){
      
      v <- c( '_exists_', '_exists_' )
      t <- c( geteventvarname(), getexactdrugvarname() )
      totalurl <- buildURL(v, t,  count='', limit=1)
      totalreports <- fda_fetch_p( session, totalurl)
      total <- totalreports$meta$results$total
      v <- c( '_exists_', getbestdrugvarname() )
      t <- c( geteventvarname(), getbestdrugname() )
      t[2] <- q$dename
      totaldrugurl <- buildURL( v, t, count='', limit=1)
      totaldrugreports <- fda_fetch_p( session, totaldrugurl)
      if ( length( totaldrugreports )==0 )
      {
        totaldrugurl <- buildURL( v= getdrugvarname(), t=getdrugname(), count='', limit=1)
        totaldrugreports <- fda_fetch_p( session, totaldrugurl)
      }

      totaldrug <- totaldrugreports$meta$results$total
      
      
    } else {
   
    # Refactor
    con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    
    totalQuery<-totalreports(input$date1, input$date2)
    totalResult <- con$aggregate(totalQuery)
    total<-totalResult$safetyreportid
    
    totaldrugQuery<-totalDrugReports(q$t1)
    totaldrugResult <- con$aggregate(totaldrugQuery)
    totaldrug<-totaldrugResult$safetyreportid
    con$disconnect()
    # Redone
    }
    
    adjust <- total/totaldrug
    out <- list(total=total, totaldrug=totaldrug, adjust=adjust)
  })


  output$mymodal <- renderText({
    if (input$update > 0)
    {
      updatevars()
      toggleModal(session, 'modalExample', 'close')
    }
    return('')
  })
  #
  #Setters ==============
  #
  output$drugname <- renderText({
    s <- getdrugname()
    if(s == '') {
      s <- 'None'
    }
    out <- paste( '<br><b>Drug Name:<i>', s, '</i></b><br>' )
    return(out)
  })

 
  output$sourceplot <- renderPlot({
    mydf <- getsourcecounts()
    return(dotchart(mydf[,2], labels=mydf[,1], main='Primary Source Qualifications') )
  }, height=300)

  output$sourcepie <- renderPlot({
    mydf <- getsourcecounts()
    return(pie(mydf[,2], labels=mydf[,1], main='Primary Source Qualifications') )
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


  output$query <- renderTable({
    mydf <- getdrugcountstable()$mydf
    if ( is.data.frame(mydf) )
    {
      names(mydf) <- c( 'M', i18n()$t("Preferred Term"), paste( i18n()$t("Case Counts for"), getdrugname()), i18n()$t("% Count") )
      return(mydf)
    } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
  },  sanitize.text.function = function(x) x)

  output$eventcloud <- renderPlot({
    mydf <- getdrugcountstable()$sourcedf
    if ( is.data.frame(mydf) )
    {
      mytitle <- paste('Events in Reports That Contain', getdrugname() )
      return( getcloud(mydf, title=mytitle ) )
    } else  {
      return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
    }

  }, height=800, width=800)

  output$querytext <- renderText({
    l <- getdrugcounts()
    return(
      paste( '<b>Query:</b>', removekey( makelink(l['myurl']) ) , '<br>') )
  })

  output$querytitle <- renderText({
    return( paste('<h4>Counts for', getdrugname(), '</h4><br>') )
  })



  output$alltitle <- renderText({
    return( ('<h4>Counts for Entire Database</h4><br>') )
  })

  output$queryalldrugtext <- renderText({
    l <- gettotals()
    return(
      paste( '<b>Query:</b>', removekey( makelink(l['totaldrugurl']) ) , '<br>') )
  })


  output$queryalltext <- renderText({
    l <- gettotals()
    paste( '<b>Query:</b>', removekey( makelink(l['totalurl'] ) ), '<br>')
  })

  output$alldrugtext <- renderText({
    l <- gettotals()
    return(
      paste( '<b>Total reports with', getdrugname() , 'in database:</b>', prettyNum( l['totaldrug'], big.mark=','  ), '<br>') )
  })

  output$alltext <- renderText({
    l <- gettotals()
    paste( '<b>Total reports with drug name in database:</b>', l['total'], '(meta.results.total)<br>')
  })

  #**********Drugs in reports

  output$cotitle <- renderText({
    return( ( paste0('<h4>Most Common Events In Selected Reports</h4><br>') ) )
  })

  output$querycotext <- renderText({
    l <- getcocounts()
    paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
  })

  output$coquery <- renderTable({
    codrugs <- getcocounts()$mydf
    if ( is.data.frame(codrugs) )
    {
      names(codrugs) <- c('L', 'Drug',  'Counts' )
      return(codrugs)
    } else  {
      return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
    }

  }, sanitize.text.function = function(x) x)


  #addTooltip(session, 'cocloud', tt('cocloud'), placement='top')
  output$cocloud <- renderPlot({
    codrugs <- getcocounts()$sourcedf
    if ( is.data.frame(codrugs) )
    {
      names(codrugs) <- c('Drug',  'Counts' )
      mytitle <- paste('Medications in Reports That Contain', getdrugname() )
      return( getcloud(codrugs, title=mytitle ) )
    } else  {
      return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
    }

  }, height=900, width=900)

  output$indquery <- renderTable({
    # if ( getdrugname() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
    codinds <- getindcounts()$mydf
    if ( is.data.frame(codinds) )
    {
      names(codinds) <- c(i18n()$t("Indication"),  i18n()$t("Counts") )
      return(codinds)
    } else  {
      return( data.frame(Term=paste( 'No', getsearchtype(), 'for', getdrugname() ) ) )
    }

  }, sanitize.text.function = function(x) x)


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

 
  createinputs <- reactive({
    q <- parseQueryString(session$clientData$url_search)
    #  browser()
    v1 <-
      t1 <- textInput_p("t1", "Name of Drug", '',
                        HTML( tt('drugname1') ), tt('drugname2'),
                        placement='bottom')
    # useexact <- radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'),
    #                          selected='exact', inline=TRUE)
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
    # s <- radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'),
    #                   selected='exact', inline=TRUE)
    s <- radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'),
                      selected='any', inline=TRUE)
  })


  output$date1 <- renderText({
    l <- getdaterange()
    paste( '<b>', l[3] , 'from', as.Date(l[1],  "%Y%m%d")  ,'to', as.Date(l[2],  "%Y%m%d"), '</b>')
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

  # Parse the GET query string
  output$queryText <- renderText({
    query <- geturlquery()
    # Return a string with key-value pairs
    paste(names(query), query, sep = "=", collapse=", ")
  })

  getcururl <- reactive({
    mypath <- extractbaseurl( session$clientData$url_pathname )
    s <- paste0( session$clientData$url_protocol, "//", session$clientData$url_hostname,
                 ':',
                 session$clientData$url_port,
                 mypath )

    return(s)
  })


  output$urlquery <- renderText({
    return( getcururl()  )
  })

  output$applinks <- renderText({
    return( makeapplinks(  getcururl(), getqueryvars( 1 ) )  )
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

  
  getsearchtype <- reactive({ 
    if (getwhichprogram() == 'E'){
      return(   "Reaction" )
    } else {
      return( 'Drug' )
    }
  })
  
  getwhichprogram <- reactive( {
    return( getwhich() )
  })
  
  getvar1 <- reactive({ 
    anychanged()
    q <- geturlquery()
    if (getwhichprogram() == 'E'){
      return(   "patient.reaction.reactionmeddrapt" )
    } else {
      return(input$v1)
    }
  })
  
  getprrvarname <- reactive({ 
    q <- geturlquery()
    if (getwhichprogram() != 'E'){
      #PRR table of reactions
      return(   "patient.reaction.reactionmeddrapt.exact" )
    } else {
      #PRR table of drugs
      return( paste0(input$v1, '.exact') )
    }
  })
  
  getexactvar1 <- reactive({
    q <- geturlquery()
    s <- getvar1()
    return(   paste0(s, ".exact") )
  })
  
  getbestvar1 <- function(){
    # exact <-   ( getdrugcounts()$exact)
    # if (exact){
    #   return( getexactvar1() )
    # } else {
      return( getvar1() )
    # }
  }
  
  getbestterm1 <- function(quote=TRUE){
    # exact <-   ( getdrugcounts()$exact)
    # if (exact)
    # {
    #   s <- getterm1( session, quote = TRUE )
    #   s <- gsub(' ', '%20', s, fixed=TRUE)
    #   return( s )
    # } else {
    #   return( getterm1( session ) )
    # }
    return( getterm1( session ))
  }
  
  gettimevar <- function(){
    return ('receiptdate')
  }
  
  gettimerange <- reactive({
    geturlquery()
    mydates <- getstartend()
    start <- mydates[1]
    end <-  mydates[2]
    timerange <- paste0('[', start, '+TO+', end, ']')
    return(timerange)
  })
  
  getstartend <- reactive({
    geturlquery()
    start <- input$date1
    end <- input$date2
    # start <- input$daterange[1]
    # end <- input$daterange[2]
    return( c(start, end))
  })
  
  gettimeappend <- reactive({
    geturlquery()
    mytime <- getstartend()
    s <- paste0('&start=', mytime[1] , '&end=', mytime[2] )
    return( s )
  })
  # Input SETTERS ====================================================================
  updatevars <- reactive({
    input$update
    if(!is.null(session$erroralert))
    {
      closeAlert(session, 'erroralert')
    }
    isolate( {
      updateTextInput(session, "t1", value=( input$drugname ) )
      updateNumericInput(session, "limit", value= ( input$limit2 ) )
      updateNumericInput(session, "start", value= ( input$start2 ) )
    })
  })
  
  anychanged <- reactive({
    a <- input$t1
    b <- input$v1
    c <- input$useexact
    if(!is.null(session$erroralert))
    {
      closeAlert(session, 'erroralert')
    }
  })
  
  output$mymodal <- renderText({
    if (input$update > 0)
    {
      updatevars()    
      toggleModal(session, 'modalExample', 'close')
    }
    return('')
  })
  
  
  output$drugname <- renderText({ 
    s <- getterm1description( input$useexact, getterm1( session ) )
    renderterm( s, 'Drug Name:') 
  } )
  output$eventname <- renderText({ 
    s <- getterm1description( input$useexact, getterm1( session ) )
    renderterm( s, 'Event Name:') 
  } )
  output$limit <- renderText({ renderterm( getlimit( session ), 'Limit Analysis to', 'most frequent terms') } )
  output$start <- renderText({ 
    startfont <- '<i><font color="dodgerblue" size="4">'
    endfont <- '</font></i>'
    renderterm( getstart( session ), 'Start analysis at ranked frequency count # ',
                label2=paste( '<br>Analyzing counts with ranked frequencies from',
                              startfont, getstart( session ) , endfont,
                              'to', 
                              startfont, getstart( session )+getlimit( session )-1, endfont  ) ) 
  } )
  
  output$curtab <- renderText({
    renderterm( input$limit )
  } ) 
  # General Reactives ============================================================
  #************************************
  # Get Drug-Event Query
  #*********************
  
  
  # Only use the first value of limit rows
  getdrugcounts <- reactive({

    q<-geturlquery()
    # v <- c('_exists_' , getexactvar1(), gettimevar() )
    # t <- c(  getexactvar1() ,getterm1( session, quote = TRUE ), gettimerange() )
    
    #changes 19-11-2020
    # if (!is.null(q$t2)){
    #   # mylist <-  getcounts999( session, v= v, t= t,
    #   #                          count=getprrvarname(), exactrad = input$useexact,eventName=toupper(q$t2))
    #   # browser()
    #   # Refactor
    #   con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    #   drugName <- q$t1
    #   eventName<-q$t2
    #   eventQuery <- totalDrugEventReports(drugName, eventName)
    #   eventResult <- con$aggregate(eventQuery)
    #   mylist <- data.frame(ncol = 2, nrow=1)
    #   colnames(mylist) <- c('term','count')
    #   mylist$term <- eventName
    #   mylist$count <- eventResult$safetyreportid
    #   con$disconnect()
    #   # Redone
    # }
    # 
    # else{
    #   # mylist <-  getcounts999( session, v= v, t= t,
    #   #                          count=getprrvarname(), exactrad = input$useexact )
    #   # browser()
    #   # Refactor
    #   con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    #   eventQuery <- createEventsAllQuery()
    #   eventResult <- con$aggregate(eventQuery)
    #   colnames(eventResult)[1]<-"term"
    #   mylist <- eventResult
    #   # browser()
    #   con$disconnect()
    #   # Redone
    # }
    
    #end of changes
    
    
    # mydfAll <- mylist$mydf
    # mydfAll <- mylist
    # start <- getstart( session )
    # last <- min(getlimit( session ) + start - 1, nrow(  mydfAll ) )
    # #If Not enough event terms to start at start, look at last limit values
    # if( last < start )
    # {
    #   start <- last - getlimit( session )
    # }
    # mydf <- mydfAll[ start:last,]
    # 
    # return( list(mydf=mydf, mydfAll= mydfAll) )
    q <- geturlquery()
    v <- c('_exists_' , input$v1, gettimevar() )
    t <- c(  getexactvar1() ,getterm1( session, quote = TRUE ), gettimerange() )

    if (is.null(q$t2) && q$v1 ==  "patient.reaction.reactionmeddrapt"){
      v[2] = "patient.reaction.reactionmeddrapt.exact"
    }
    # browser()
    if (q$concomitant == TRUE){
      t[2]<- q$dename
      if (q$v1 ==  "patient.reaction.reactionmeddrapt"){
        mylist <-  getcounts999fda( session, v= v, t= t, 
                                    count="patient.drug.openfda.generic_name.exact", exactrad = input$useexact, eventName = toupper(q$ename))
        
      } else {
        mylist <-  getcounts999fda( session, v= v, t= t, 
                                    count=getprrvarname(), exactrad = input$useexact, eventName = toupper(q$ename))
      }
      
    } else {
      # browser()
      mylist <-  getcounts999( session, v= v, t= t, 
                               count=getprrvarname(), exactrad = input$useexact, eventName = q$t2, date1 = input$date1, date2=input$date2, drugNameOrg = q$dename )
    }
    
    
    
    mydfAll <- mylist$mydf
    # browser()
    start <- getstart( session )
    last <- min(getlimit( session ) + start - 1, nrow(  mydfAll ) )
    #If Not enough event terms to start at start, look at last limit values
    if( last < start )
    {
      start <- last - getlimit( session )
    }
    mydf <- mydfAll[ start:last,]
    
    return( list(mydf=mydf, mydfAll= mydfAll) )
  })  
  
  
  
  #Build table containing drug-event pairs
  getdrugcountstable <- reactive({
    geturlquery()
    mylist <- getdrugcounts()
    myurl <- mylist$myurl
    #mydf for limit terms
    mydf <- mylist$mydf
    #mydf for all terms
    mydfAll <- mylist$mydfAll
    mydfsource <- mydf
    mydfallsource <- mydfAll
    names <- c('v1','t1' ,'v3', 't3', 'v2', 't2' )
    values <- c(getbestvar1(), getbestterm1(), gettimevar(), gettimerange(),  getprrvarname() )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydfAll[,2] <- numcoltohyper(mydfAll[ , 2], mydfAll[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    #    browser()
    if (getwhich()=='D')
    {
      mydf[,1] <- coltohyper(mydf[,1],  'E',
                             mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() )  )
      mydfAll[,1] <- coltohyper(mydfAll[,1],  'E',
                                mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    } else {
      mydf[,1] <- coltohyper(mydf[,1],  'D',
                             mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
      mydfAll[,1] <- coltohyper(mydfAll[,1],  'D',
                                mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    }
    return( list(mydf=mydf, myurl=(myurl), mydfsource = mydfsource, mydfAll=mydfAll, mydfallsource = mydfallsource  ) )
  })  
  
  
  
  #Get total counts in database for each event and Total reports in database
  gettotals<- reactive({
    q<-geturlquery()
  
    if (q$concomitant == TRUE){
      
      v <- c( '_exists_', '_exists_', gettimevar() )
      t <- c( getprrvarname(), getbestvar1(), gettimerange() )
      totalurl <- buildURL(v, t,  count='', limit=1)
      totalreports <- fda_fetch_p( session, totalurl, flag=NULL)
      total <- totalreports$meta$results$total
      v <- c( '_exists_', '_exists_', getbestvar1(), gettimevar() )
      t <- c( getbestvar1(), getprrvarname(), getbestterm1(), gettimerange() )
      t[3] <- q$dename
      v[3]<- q$v1
      totaldrugurl <- buildURL( v, t, count='', limit=1)
      totaldrugreports <- fda_fetch_p( session, totaldrugurl, flag=paste( 'No Reports for',
                                                                          ifelse(getwhich()=='D', 'drug', 'event' ), getterm1( session ), '<br>' ) )
          if ( length( totaldrugreports )==0 )
            {
            totaldrugurl <- buildURL( v= getvar1(), t=getterm1( session ), count='', limit=1)

            totaldrugreports <- fda_fetch_p( session, totaldrugurl, flag= paste( 'No Reports of Drug', getterm1( session ) ) )
          }
      totaldrug <- totaldrugreports$meta$results$total
    } else {
   
    
      # Refactor
      con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
      
      totalQuery<-totalreports(input$date1, input$date2)
      totalReports <- con$aggregate(totalQuery)
      total <- totalReports$safetyreportid

      if (q$v1 == 'patient.reaction.reactionmeddrapt') {
        
        # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
        con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")      
        eventName<-q$t1
        
        eventTotalQuery<-totalEventReports(eventName=eventName, input$date1, input$date2)
        totalevents <- con$aggregate(eventTotalQuery)
        totaldrug <- totalevents$safetyreportid
        
      }else{
        # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
        con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")      
        drugName<-q$t1
        
        drugTotalQuery<-totalDrugReports(drugName=drugName, input$date1, input$date2, q$dename)
        totaldrugs <- con$aggregate(drugTotalQuery)
        totaldrug <- totaldrugs$safetyreportid
        con$disconnect()
      }
      
      # Redone
    }
    adjust <- total/totaldrug
    out <- list(total=total, totaldrug=totaldrug, adjust=adjust )
  }) 
  
  #Calculate PRR and put in merged table
  getprr <- reactive({
    q<-geturlquery()
    # print(session)
    #    totals <- gettotals()
    
    comblist <- makecomb(session, getdrugcounts()$mydf, geteventtotals(), gettotals(), getsearchtype())
    # browser()
    
    #changes 19-11-2020
    if (is.null(q$t2))
      comb <- comblist$comb
    else{
      con_med <- mongo("medra", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
      event <- con_med$find(paste0('{"code" : "',input$t2,'"}'))
      con_med$disconnect()
      eventName = toupper(event$names[[1]][1])
      comb <- comblist$comb[comblist$comb[,'term']==toupper(eventName),]
    }
      
    #end of changes
    
    
    
    # print(length(comb))
    # if (length(comb) < 1)
    if (nrow(comb) < 1)
    {
      # tmp <- data.frame( Error=paste('No results for', input$useexact, getterm1(session), '.'),
      #                    count=0 )
      tmp <- data.frame( Error=paste(i18n()$t('No results for'), getterm1(session), i18n()$t('and'), getterm2(session), '.'), count=0)
      
      return( list( comb=tmp, sourcedf=tmp) )
    }
    
    row.names(comb) <- 1:nrow(comb)
    
    comb$ror <- round(comb$ror, 2)
    #    ror <- comblist$ror
    if (getwhich() =='D'){ 
      names <- c('exactD', 'exactE','v1', 'term1','term2')
      values <- c(input$useexact , 'exact', getvar1(), gsub( '"', '', getbestterm1(), fixed=TRUE  ) )
      #      browser()
      exacttext <- paste0(  '&exactD=', input$useexact , '&exactE=exact' )
      links <-getcpalinks(comb[ , 1], names, values, getcururl() )
      comb <- data.frame( M='M' , comb, links$dynprr, links$cpa,  comb$ror, comb$nij)
      #      print( names(comb) )
      sourcedf <- comb
      colname <- i18n()$t("Preferred Term")
      iname <- i18n()$t('Definition')
      medlinelinks <- makemedlinelink(sourcedf[,2], iname)
    } else { 
      names <- c('exactD', 'exactE','v2','term2', 'v1','term1')
      values <- c('exact', input$useexact, getvar1(), gsub( '"', '', getbestterm1(), fixed=TRUE  ), input$v1 )
      exacttext <- paste0(  '&exactD=exact', '&exactE=', input$useexact )
      links <-getcpalinks(comb[ , 1], names, values, getcururl(), appendtext =  exacttext )
      comb <- data.frame(D='D', M='L' , comb, links$dynprr, links$cpa,  comb$ror, comb$nij)
      sourcedf <- comb
      colname <- 'Drug Name'
      #browser()
      iname <- c( 'Dashboard', 'Label')
      if (input$v1 != 'patient.drug.medicinalproduct')
      {
        drugvarname <- gsub( "patient.drug.","" , input$v1 , fixed=TRUE)
        drugvar <- paste0( "&v1=", drugvarname)
        medlinelinks <- coltohyper( paste0( '%22' , sourcedf[, 'term' ], '%22' ), 'L', 
                                    mybaseurl = getcururl(), 
                                    display= rep(iname[2], nrow( sourcedf ) ), 
                                    append= drugvar )
        drugvar <- paste0( "&v1=", input$v1 )
        dashlinks <- coltohyper( paste0( '%22' , sourcedf[, 'term' ], '%22' ), 'DA', 
                                 mybaseurl = getcururl(), 
                                 display= rep(iname[1], nrow( sourcedf ) ), 
                                 append= drugvar )
        comb[,'D'] <- dashlinks
      }
      else {
        medlinelinks <- rep(' ', nrow( sourcedf ) )
      }
    }
    comb[,'M'] <- medlinelinks
    names <- c('v1','t1','v3', 't3' ,'v2', 't2')
    values <- c(getbestvar1(), getbestterm1(), gettimevar(), gettimerange(), getprrvarname() )
    comb[,'count.x'] <- numcoltohyper(comb[ , 'count.x'], comb[ , 'term'], names, values, mybaseurl =getcururl(), addquotes=TRUE )
    names <- c('v1','t1','v3', 't3' ,'v2', 't2')
    values <- c( '_exists_', getvar1(), gettimevar(), gettimerange(), getprrvarname() )
    comb[, 'count.y' ] <- numcoltohyper(comb[ , 'count.y' ], comb[ , 'term'], names, values , mybaseurl = getcururl(), addquotes=TRUE)
    comb[,'term'] <- coltohyper( comb[,'term'], ifelse(getwhich()=='D', 'E', 'D' ), 
                                 mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend()) )
    #     comb <- comb[order(comb$prr, decreasing = TRUE),]
    #     sourcedf <- sourcedf[order(sourcedf$prr, decreasing = TRUE),]
    #     row.names(comb)<- seq(1:nrow(comb))
    # Refactor
    con <- mongo("atc", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
    drug <- con$find(paste0('{"code" : "',getterm1( session ),'"}'))
    mydrugc <- drug$names[[1]][1]
    con$disconnect()
    # Redone
    # countname <- paste( i18n()$t("Counts for"), getterm1( session ))
    countname <- paste( i18n()$t("Counts for"), mydrugc)
    names(comb) <-  c( iname, colname,countname, 
                       'Counts for All Reports','PRR', 'RRR',  'a', 'b', 'c', 'd', 'Dynamic PRR', 'Change Point Analysis', 'ROR', 'nij')
    # keptcols <-  c( iname, colname,countname, 
    #                                 'Counts for All Reports', 'PRR',  'Dynamic PRR', 'Change Point Analysis', 'ROR', 'nij')
    keptcols <-  c( iname, colname, countname, 
                    'PRR', 'ROR')
    
    # print(comb[,keptcols])
    # print(comb$ror)
    # browser()
    #    mydf <- mydf[, c(1:4, 7,8,9)]
    return( list( comb=comb[, keptcols], sourcedf=sourcedf, countname=countname, colname=colname) )
  })
  
  geteventtotalstable <- reactive({
    geturlquery()
    mydf <- geteventtotals()
    sourcedf <- mydf
    names <- c('v1','t1','v3', 't3' ,'v2', 't2')
    values <- c('_exists_', getvar1( ), gettimevar(), gettimerange()  , getprrvarname() )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,1] <- coltohyper(mydf[,1], ifelse( getwhich()=='D', 'E', 'D'), 
                           mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    #    print(head(mydf))
    return( list(mydf=mydf, sourcedf=sourcedf) )
  })  
  
  geteventtotals <- reactive(
    {
      
      q <- geturlquery()
      mydf <- getdrugcounts()$mydf
      if ( !is.data.frame(mydf) ) 
      {
        return(NA)
      }
      realterms <- mydf[,1]
      foundtermslist <- mydf[,1]
      foundtermslist <- paste('"', foundtermslist, '"', sep='')
      foundtermslist <- gsub(' ', '%20',foundtermslist, fixed=TRUE )
      browser()
      all <- data.frame(term=rep(URL='u', 'a', length(foundtermslist)), count=0L,  stringsAsFactors = FALSE)
      for (i in seq_along(foundtermslist))
      {
        if (q$concomitant==TRUE){
          if (q$v1 == "patient.reaction.reactionmeddrapt"){
            eventvar <- gsub('.exact', '', getprrvarname(), fixed=TRUE)
            #    myv <- c('_exists_', eventvar)
            myv <- c('_exists_', getprrvarname(), '_exists_', gettimevar() )
            myv[2] <- "patient.drug.openfda.generic_name.exact"
            myt <- c( getbestvar1(),  foundtermslist[[i]], getprrvarname(), gettimerange()  )
            #    cururl <- buildURL(v= myv, t=myt, count= getprrvarname(), limit=1)
            cururl <- buildURL(v= myv, t=myt, limit=1, whichkey=i%%2)
            #   print(cururl)
            #    all_events2 <- getcounts999( session, v= myv, t=myt, count= getprrvarname(), limit=1, counter=i )      
            all_events2 <- fda_fetch_p( session, cururl, message= i )
            
          } else {
            eventvar <- gsub('.exact', '', getprrvarname(), fixed=TRUE)
            #    myv <- c('_exists_', eventvar)
            myv <- c('_exists_', getprrvarname(), '_exists_', gettimevar() )
            myt <- c( getbestvar1(),  foundtermslist[[i]], getprrvarname(), gettimerange()  )
            #    cururl <- buildURL(v= myv, t=myt, count= getprrvarname(), limit=1)
            cururl <- buildURL(v= myv, t=myt, limit=1, whichkey=i%%2)
            #   print(cururl)
            #    all_events2 <- getcounts999( session, v= myv, t=myt, count= getprrvarname(), limit=1, counter=i )      
            all_events2 <- fda_fetch_p( session, cururl, message= i )
          }
       
          #    Sys.sleep( .25 )
          
          curcount <- all_events2$meta$results$total
        }else {
          # Refactor
          if (q$v1 == "patient.reaction.reactionmeddrapt"){
            
            # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
            con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
            # drugName<-unlist(strsplit(myt[2], '\\"'))[2]
            drugName<-str_replace_all(realterms[i], "[[:punct:]]", " ")
            
            drugTotalQuery<-totalDrugReportsOriginal(drugName=drugName, input$date1, input$date2)
            totaldrug <- con$aggregate(drugTotalQuery)
            all_events2 <- totaldrug
            
          } else {
            
            # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
            con <- mongo("dict_fda", url = "mongodb://pv_user:DnKrgEBXGR@160.40.71.111:27017/FDAforPVClinical")
            # eventName<-unlist(strsplit(myt[2], '\\"'))[2]
            eventName<- str_replace_all(realterms[i], "[[:punct:]]", " ")
            
            eventTotalQuery<-totalEventReportsOriginal(str_to_sentence(eventName), input$date1, input$date2)
            totalevent <- con$aggregate(eventTotalQuery)
            all_events2 <- totalevent
            
          }
          con$disconnect()
          curcount <- all_events2$safetyreportid
          # Redone
        }
        # browser()
        
        
        # all[i, 'URL'] <- removekey( makelink( cururl ) )
        all[i, 'term'] <- realterms[[i]]
        
        # all[i, 'count'] <- curcount
        if( is.null( curcount ) )
        {
          curcount <- NA
        }
        all[i, 'count'] <- curcount
      }
      
      return(all) 
    } )
  #end calculations
  
  ##
  # tabPanel("PRR and ROR Results"
  
  output$prrtitle <- renderText({ 
    geturlquery()
    return('<h4>Reporting Ratios: Results sorted by PRR</h4>')
  })
  
  prr <- reactive({  
    if (getterm1( session )=="") {
      return(data.frame(Term=i18n()$t(paste('Please enter a', getsearchtype(), 'name')), Count=0, Count=0, PRR=0, ROR=0))
    } else {
      tableout(mydf = getprr()$comb,  
               mynames = NULL,
               error = paste(i18n()$t('No records for'), getterm1( session ))
      )
    }
  } )
  output$prr <- renderTable({  
    prr()
  },  sanitize.text.function = function(x) x)
  
  output$prr2 <- DT::renderDT({  
    prr<-prr()
    #Save json file for the prr dataset
    # if (!is.null(values$urlQuery$hash)){
    #   exportJson <- toJSON(prr)
    #   write( exportJson, paste0(values$urlQuery$hash,"_","prr2.json"))
    # }
    if (!is.null(input$sourceDataframeUI)){
      if (input$sourceDataframeUI){
        write.csv(prr,paste0(cacheFolder,values$urlQuery$hash,"_timeseries_prr.csv"))
        
      }
    }
    
    if(!is.null(values$urlQuery$hash)){
      return(datatable(
        prr,
        options = list(
          autoWidth = TRUE,
          dom = 't', #fltipr default (f: filter, l: length, i: info, p: pages)
          # rowCallback = JS(js_callback),
          # columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
          columnDefs = list(list(className = 'dt-center', targets = c(1, 2))),
          #initComplete = JS('function(setting, json) { alert("done"); }'),
          language = list(
            url = ifelse(input$selected_language=='gr', 
                         'datatablesEnglish.json', 
                         'datatablesGreek.json')
          )
        ),
        escape=FALSE
      )
      )
    } else {
      return ( datatable(
        prr,
        options = list(
          autoWidth = TRUE,
          dom = 'tr', #fltipr default (f: filter, l: length, i: info, p: pages)
          # rowCallback = JS(js_callback),
          # columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
          columnDefs = list(list(className = 'dt-center', targets = c(1, 2))),
          #initComplete = JS('function(setting, json) { alert("done"); }'),
          language = list(
            url = ifelse(input$selected_language=='gr', 
                         'datatablesEnglish.json', 
                         'datatablesGreek.json')
          )
        ),
        escape=FALSE
      )
      )
      
    }
    
    # print(comblist$comb[comblist$comb[,'term']==toupper(input$t2),])
    # comb <- comblist$comb
    
    write.xlsx(prr, "../mydata.xlsx")
    # js_callback = paste0("function( row, data, index ) {
    #       if (data[2] != '", toupper(input$t2),"') {
    #         $(row).hide();
    #       }
    #     }")
    
  },  escape=FALSE)
  
  
  cloudprr <- reactive({  
    mydf <- getprr()$sourcedf
    if( getwhich()=='D')
    {
      mydf <- data.frame(mydf[,2], mydf[,'prr']*10)
    } else {
      mydf <- data.frame(mydf[,3], mydf[,'prr']*10)
    }
    cloudout(mydf, paste('PRR for Events in Reports That Contain', getterm1( session ) ) )  
  })
  output$cloudprr <- renderPlot({  
    cloudprr()  
  }, height=900, width=900)
  
  textplot <- reactive({ 
    if (getterm1( session )!="") {
      mylist <- getprr()
      mydf <- mylist$comb
      y <- mydf[,'PRR']
      x <- mydf[, 'nij']
      w <- getvalvectfromlink( mydf[, mylist$colname ] )
    } else {
      w <- NULL
      y <-NULL
      x <- NULL
    }
    #  browser()
    #plot with no overlap and all words visible
    return ( mytp(x, y, w, myylab='PRR') )
    #cloudout(mydf, paste('PRR for Events in Reports That Contain', getterm1( session ) ) )  
  })
  output$textplot <- renderPlot({ 
    textplot()
  }, height=400, width=900)
  
  output$info <- renderTable({
    mylist <- getprr()
    mydf <- mylist$comb
    mydf2 <- mylist$sourcedf
    #   mydf <- data.frame( Event = mydf[,'term'],
    #                       Count = mydf[,'count.x'],
    #                       PRR = mydf[,'prr'] )
    # With base graphics, need to tell it what the x and y variables are.
    brushedPoints(mydf, input$plot_brush, yvar = "PRR", xvar = 'nij' )
  },  sanitize.text.function = function(x) x)
  
  
  
  
  ##
  # tabPanel("Analyzed Drug/Event Counts for Specified Event/Drug"  
  output$alldrugtext <- renderText({ 
    l <- gettotals()
    return( 
      paste( '<b>Total reports with', getsearchtype(), getterm1( session ) , 'in database:</b>', prettyNum( l['totaldrug'], big.mark=',' ), '<br>') )
  })
  output$queryalldrugtext <- renderText({ 
    l <- gettotals()
    return( 
      paste( '<b>Query:</b>', removekey( makelink(l['totaldrugurl']) ) , '<br>') ) 
  })
  
  output$querytitle <- renderText({ 
    return( paste('<h4>Counts for', getterm1( session ), '</h4><br>') )
  })
  
  cloudquery <- reactive({  
    cloudout(getdrugcountstable()$mydfsource, paste('Terms in Reports That Contain', getterm1( session ) ))
  })
  output$cloudquery <- renderPlot({  
    cloudquery()
  }, height=900, width=900 )
  
  specifieddrug <- reactive({ 
    tableout(mydf = getdrugcountstable()$mydf,  
             mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for"), getterm1( session ) ) ),
             error = paste( 'No results for', getterm1( session ) ) )
  })
  output$specifieddrug <- renderTable({ 
    tableout(mydf = getdrugcountstable()$mydf,  
             mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for"), getterm1( session ) ) ),
             error = paste( 'No results for', getterm1( session ) ) )
  },  height=120, sanitize.text.function = function(x) x)
  
  output$specifieddrug2 <- shiny::renderDataTable({ 
    # if (!is.null(q$hash)){
    #   pin( getdrugcountstable()$mydf, name=paste0(q$hash,"_","specifieddrug2"))
    # }
    tableout(mydf = getdrugcountstable()$mydf,  
             mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for"), getterm1( session ) ) ),
             error = paste( 'No results for', getterm1( session ) ) )
  },  escape=FALSE )
  
  # tabPanel("Event Counts for All Drugs" 'alltext' 'queryalltext' 
  #'alltitle'  'allquerytext' ,'cloudall', 'all'
  output$alltext <- renderText({ 
    l <- gettotals()
    paste( '<b>Total reports with value for', getbestvar1() ,'in database:</b>', prettyNum(l['total'], big.mark=',' ), '(meta.results.total)<br>')
  })
  output$queryalltext <- renderText({ 
    l <- gettotals()
    paste( '<b>Query:</b>', removekey( makelink(l['totalurl'] ) ), '<br>')
  })
  
  output$alltitle <- renderText({ 
    return( ('<h4>Counts for Entire Database</h4><br>') )
  })
  
  cloudall <- reactive({  
    cloudout(geteventtotalstable()$sourcedf, 
             paste('Events in Reports That Contain', getterm1( session ) ) ) 
  })
  output$cloudall <- renderPlot({  
    cloudall()
  }, height=900, width=900)
  
  all <- renderTable({  
    tableout(mydf = geteventtotalstable()$mydf, 
             mynames = c('Term', paste( 'Counts for All Reports'), 'Query' ),
             error = paste( 'No events for', getsearchtype(), getterm1( session ) ) 
    )
  })
  output$all <- renderTable({  
    tableout(mydf = geteventtotalstable()$mydf, 
             mynames = c('Term', paste( 'Counts for All Reports'), 'Query' ),
             error = paste( 'No events for', getsearchtype(), getterm1( session ) ) 
    )
  }, sanitize.text.function = function(x) x)
  
  output$all2 <- shiny::renderDataTable({  
    tableout(mydf = geteventtotalstable()$mydf, 
             mynames = c('Term', paste( 'Counts for All Reports'), 'Query' ),
             error = paste( 'No events for', getsearchtype(), getterm1( session ) ) 
    )
  }, escape=FALSE)
  
  
  # tabPanel("Ranked Drug/Event Counts for Event/Drug 'cotextE' 'querycotextE'  'cotitleE',
  # 'coquerytextE' ,'cloudcoqueryE', 'coqueryE'
  
  
  output$querycotextE <- renderText({ 
    l <- getdrugcountstable()
    paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
  })
  output$cotitleE <- renderText({ 
    return( paste('<h4>Most common events for', getterm1( session ), '</h4><br>') )
  })
  output$cotitleD <- renderText({ 
    return( paste('<h4>Most common drugs for', getterm1( session ), '</h4><br>') )
  })
  
  cloudcoqueryE <- reactive({ 
    cloudout( getdrugcountstable()$mydfallsource, 
              paste('Events in Reports That Contain', getterm1( session ) ) )
    
  })
  output$cloudcoqueryE <- renderPlot({ 
    cloudcoqueryE()
    
  }, height=900, width=900 )
  
  coqueryE <- reactive({  
    out <- tableout(mydf = getdrugcountstable()$mydfAll,  
                    mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for"), getterm1( session ) ) ),
                    error = paste( 'No Events for', getterm1( session ) )
    )
    
    #  browser()
    return(out)
  })
  output$coqueryE <- renderTable({  
    coqueryE()
  }, sanitize.text.function = function(x) x)
  
  output$coqueryE2 <- shiny::renderDataTable({  
    coqueryE()
  }, escape=FALSE)
  
  # tabPanel("Counts For Drugs In Selected Reports"
  #            htmlOutput( 'cotext' ),
  #            htmlOutput_p( 'querycotext' ,
  #                          tt('gquery1'), tt('gquery2'),
  #                          placement='bottom' )
  #          ),
  #          wellPanel(
  #            htmlOutput( 'cotitle' )
  #          ),
  #          htmlOutput_p( 'coquerytext' ,
  #                        tt('gquery1'), tt('gquery2'),
  #                        placement='bottom' ),
  #          wordcloudtabset('cloudcoquery', 'coquery'
  
  
  output$querycotext <- renderText({ 
    l <- getcocounts()
    paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
  })
  output$cotitle <- renderText({ 
    return( ( paste0('<h4>Most Common ', getsearchtype() , 's In Selected Reports</h4><br>') ) )
  })
  
  output$coquery <- renderTable({  
    tableout(mydf = getcocounts()$mydf,  mynames = NULL,
             error = paste( 'No', getsearchtype(), 'for', getterm1( session ) ))
  }, sanitize.text.function = function(x) x)
  
  
  coquery2 <- reactive({  
    
    out <- tableout(mydf = getcocounts()$mydf,  mynames = NULL,
                    error = paste( 'No', getsearchtype(), 'for', getterm1( session ) ))
    return(out)
  } )
  
  output$coquery2 <- shiny::renderDataTable({  
    coquery2()
  },  escape=FALSE )
  
  # tabPanel("Counts For Indications In Selected Reports"
  #            htmlOutput( 'indtext' ),
  #            htmlOutput_p( 'queryindtext' ,
  #                          tt('gquery1'), tt('gquery2'),
  #                          placement='bottom' )
  #          ),
  #          wellPanel(
  #            htmlOutput( 'indtitle' )
  #          ),
  #          wordcloudtabset('cloudindquery', 'indquery'
  
  ##Tables ================================
  
  
  output$indquery <- renderTable({ 
    tableout(mydf = getindcounts()$mydf, mynames = c('Indication',  'Counts' ),
             error = paste( 'No results for', getterm1( session ) ) )
  }, sanitize.text.function = function(x) x)
  
  output$indquery2 <- shiny::renderDataTable({ 
    tableout(mydf = getindcounts()$mydf, mynames = c('Indication',  'Counts' ),
             error = paste( 'No results for', getterm1( session ) ) )
  },  escape=FALSE )
  
  
  
  
  output$coqueryEex <- renderTable({  
    tableout(mydf = getdrugcounts()$excludeddf,  
             #           mynames = c( "Terms that contain '^' or ' ' ' can't be analyzed and are excluded", 'count' ),
             error = paste( 'No Events for', getterm1( session ) )
    )
  }, sanitize.text.function = function(x) x)
  
  
  output$coqueryEex2 <- shiny::renderDataTable({  
    tableout(mydf = getdrugcounts()$excludeddf,  
             #           mynames = c( "Terms that contain '^' or ' ' ' can't be analyzed and are excluded", 'count' ),
             error = paste( 'No Events for', getterm1( session ) )
    )
  }, escape=FALSE )
  
  #Plots========================================================
  # output$cloudquery <- renderPlot({  
  #   cloudout(getdrugcountstable()$mydfsource, paste('Terms in Reports That Contain', getterm1( session ) ))
  # }, height=900, width=900 )
  
  output$cloudcoquery <- renderPlot({  
    cloudout( getcocounts()$sourcedf, 
              paste('Events in Reports That Contain', getterm1( session ) ) )
    
  }, height=900, width=900 )
  
  output$cloudindquery <- renderPlot({  
    cloudout( getindcounts()$sourcedf, 
              paste('Events in Reports That Contain', getterm1( session ) ) )
  }, height=1000, width=1000)
  
  
  
  
  # Text================================================================
  
  
  
  
  
  
  
  
  
  
  
  output$querytext <- renderText({ 
    l <- getdrugcounts()
    return( 
      paste( '<b>Query:</b>', removekey( makelink(l['myurl']) ) , 
             '<br>' ) )
  })
  output$queryalldrugtext <- renderText({ 
    l <- gettotals()
    return( 
      paste( '<b>Query:</b>', removekey( makelink(l['totaldrugurl']) ) , '<br>') ) 
  })
  
  
  
  
  
  
  
  output$indtitle <- renderText({ 
    return( ( paste0('<h4>Most Common Indications In Selected Reports</h4><br>') ) )
  })
  
  output$queryindtext <- renderText({ 
    l <- getindcounts()
    paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
  })
  
  output$date1 <- renderText({ 
    l <- getdaterange()
    paste( '<b>', l[3], 'from', as.Date(l[1],  "%Y%m%d")  ,'to', as.Date(l[2],  "%Y%m%d"), '</b>')
  })
  # URL Stuff =====
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
  
  # Parse the GET query string
  output$queryText <- renderText({
    query <- geturlquery()
    # Return a string with key-value pairs
    paste(names(query), query, sep = "=", collapse=", ")
  })
  
  getcururl <- reactive({
    mypath <- extractbaseurl( session$clientData$url_pathname )
    s <- paste0( session$clientData$url_protocol, "//", session$clientData$url_hostname,
                 ':',
                 session$clientData$url_port,
                 mypath )
    
    return(s)
  })
  
  output$sourcePlotReport<-renderUI({
    if ((!is.null(values$urlQuery$hash)) && ckbx$cb1)
      checkboxInput("sourcePlotReportUI", "Save plot")
  })
  
  observeEvent(input$sourcePlotReportUI,{
    
    if (!is.null(input$sourcePlotReportUI))
      if (!input$sourcePlotReportUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_timeseries.png")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourceDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourceDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourceDataframeUI,{
    
    if (!is.null(input$sourceDataframeUI))
      if (!input$sourceDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_timeseries_prr.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  
  
  output$urlquery <- renderText({ 
    return( getcururl()  )
  })
  
  output$applinks <- renderText({ 
    s <- makeapplinks(  getcururl(), getqueryvars( 1 ) ) 
    #    write(s, file='')
    return( makeapplinks(  getcururl(), getqueryvars( 1 ) )  )
  })
  output$quickview <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("quickview")))

  })
  output$graphpicture <- renderImage({
    
    list(src = "www/graphPicture.png",
         contentType = "image/png",
         alt = "This is alternate text")
    
  },deleteFile = FALSE)
  output$descriptionList <- renderUI(HTML(stri_enc_toutf8(i18n()$t("descriptionList"))))
  # observeEvent(input$countries, {
  #   i18n<-i18n$set_translation_language(input$countries)
  # })
  
  i18n <- reactive({
    selected <- input$selected_language
    if (length(selected) > 0 && selected %in% translator$languages) {
      translator$set_translation_language(selected)
    }
    translator
  })
  
})
      
  

