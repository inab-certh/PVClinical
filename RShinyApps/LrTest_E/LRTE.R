require(shiny)
require(shinyBS)
library(shiny.i18n)
library(DT)
library(plotly)
library(xlsx)
translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')
library(tidyverse)

popcoquery <- function()
{
  text <- 'Frequency table for events found in selected reports. Event name is linked to LRT results for event. \"M\" is linked to defintion of term.'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}
#*****************************************************
shinyServer(function(input, output, session) {
  
  cacheFolder<-"/var/www/html/openfda/media/"
  # cacheFolder<- "C:/Users/dimst/Desktop/work_project/"
  
  values<-reactiveValues(urlQuery=NULL)
  
  mywait <- 0.5
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
# Getters ======  
  getwaittime <- reactive({ 
    if(session$clientData$url_hostname == '10.12.207.87')
    {
      return( 0)
    } else if(session$clientData$url_hostname == '127.0.0.1') {
      return (.5)
    }
    return(0.0)
  })
  
  getqueryvars <- function( num = 1 ) {
   s <- vector(mode = "character", length = 7)
   if (getwhich() == 'E')
     {
     #Dashboard
     s[1] <- paste0( values$urlQuery$t1, '&v1=', input$v1 )
     
     #PRR for a Drug
     s[2] <- paste0( values$urlQuery$t1, '&v1=', input$v1 )
     
     #PRR for an Event
     s[3] <- paste0( '', '&v1=', input$v1 )
     
     #Dynamic PRR
     s[4] <- paste0( values$urlQuery$t1 , '&v1=', input$v1 )
     
     #CPA
     s[5] <- paste0(values$urlQuery$t1 , '&v1=', input$v1 )
     
     #Reportview
     s[6] <- paste0( values$urlQuery$t1, '&v1=', input$v1 )
     
     #labelview
     s[7] <- paste0( values$urlQuery$t1, '&v1=', input$v1 )
     
     #LRTest
     s[8] <- paste0( values$urlQuery$t1, '&v1=', input$v1, gettimeappend() )
     
     #LRTestE
     s[9] <- paste0( '', '&v1=', input$v1 , gettimeappend())
     
   } else {
     #Dashboard
     s[1] <- paste0( '', '&v1=', input$v1 )
     
     #PRR for a Drug
     s[2] <- paste0( '', '&v1=', input$v1 )
     
     #PRR for an Event
     s[3] <- paste0( values$urlQuery$t1, '&v1=', input$v1 )
     
     #Dynamic PRR
     s[4] <- paste0( '' , '&v1=', input$v1, '&v2=', getbestterm1var(), '&t2=', values$urlQuery$t1 )
     
     #CPA
     s[5] <- paste0( '' , '&v1=', input$v1, '&v2=', getbestterm1var(), '&t2=', values$urlQuery$t1 )
     
     #Reportview
     s[6] <- paste0( '', '&v1=', input$v1, '&v2=', getbestterm1var() , '&t2=', values$urlQuery$t1 )
     
     #labelview
     s[7] <- paste0( '', '&v1=', input$v1, '&v2=', getbestterm1var() , '&t2=', values$urlQuery$t1)
     
     #LRTest
     s[8] <- paste0( values$urlQuery$t1, '&v1=', input$v1, gettimeappend() )
     
     #LRTestE
     s[9] <- paste0( '', '&v1=', input$v1 , gettimeappend())
     
     }
   return(s)
 }
#   getterm1 <- reactive({ 
#     q <- geturlquery()
#     s <- toupper( input$t1 )
#     if  (is.null(s) | s=="" ) {
#       return("")
#     }
#     names <- s
#     names <- paste0(names, collapse=' ')
#     return(names)
#   })
  
  getquotedterm1 <- reactive({ 
    q <- geturlquery()
    browser()
    s <- toupper( q$t1 )
    if  (is.null(s) | s =="" ) {
      return("")
    }
    s <- gsub(' ', '%20', s, fixed=TRUE)
    s <- paste0('%22', s, '%22')
    s <- paste0(s, collapse=' ')
    return(s)
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
  
  getterm1var <- reactive({ 
    q <- geturlquery()
    anychanged()
    return(   "patient.reaction.reactionmeddrapt" )
    if (getwhichprogram() == 'D'){
      return(   "patient.reaction.reactionmeddrapt" )
    } else {
      return(input$v1)
    }
  })
  
  getprrvarname <- reactive({ 
    q <- geturlquery()
    return( paste0(input$v1, '.exact') )
    if (getwhichprogram() != 'D'){
      #PRR table of reactions
      return(   "patient.reaction.reactionmeddrapt.exact" )
    } else {
      #PRR table of drugs
      return( paste0(input$v1, '.exact') )
    }
  })
  
  getexactterm1var <- reactive({ 
    q <- geturlquery()
    s <- getterm1var()
    return(   paste0(s, ".exact") )
  })
  
  getbestterm1var <- function(){
    # exact <-   ( getdrugcounts999()$exact)
    # if (exact){
    #   return( getexactterm1var() )
    # } else {
      return( getterm1var() )
    # }
  }
  
  getbestterm1 <- function(quote=TRUE){
    # exact <-   ( getdrugcounts999()$exact)
    # if (exact)
    # {
    #   return( getquotedterm1() )
    # } else {
      return( getterm1(session) )
    # }
  }
  
  
  gettimevar <- function(){
    return ('receivedate')
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
  
#   getlimit <- reactive({ 
#     q <- geturlquery()
#     return(input$limit)
#   })
#   
#   getstart <- reactive({ 
#     q <- geturlquery()
#     return(input$start)
#   })
  
  updatevars <- reactive({
    q <- geturlquery()
    input$update
    isolate( {
      updateTextInput(session, "t1", value=( toupper(q$t1)  ) )
      updateNumericInput(session, "limit", value= ( input$limit2 ) )
      updateNumericInput(session, "start", value= ( input$start2 ) )
      updateNumericInput(session, "numsims", value= ( input$numsims2 ) )
    })
  })
  
  
  anychanged <- reactive({
    
    a <- values$urlQuery$t1
    b <- input$v1
    c <- input$useexact
    if(!is.null(session$erroralert))
    {
      closeAlert(session, 'erroralert')
    }
  })
  
  output$downloadDataLbl1 <- output$downloadDataLbl2 <- output$downloadDataLbl3 <- output$downloadDataLbl4 <- 
    output$downloadDataLbl5 <- output$downloadDataLbl6 <- output$downloadDataLbl7 <- output$downloadDataLbl8 <- renderText({
    return(i18n()$t("Download Data in Excel format"))
  })
  
  output$downloadBtnLbl1 <- output$downloadBtnLbl2 <- output$downloadBtnLbl3 <- output$downloadBtnLbl4 <- 
    output$downloadBtnLbl5 <- output$downloadBtnLbl6 <- output$downloadBtnLbl7 <- output$downloadBtnLbl8 <- renderText({
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
  
  #end getters
# Queries =======
  
  output$drugname <- renderText({
    s <- getterm1(session)
    if(s == '') {
      s <- 'None'
    }
    out <- paste( '<br><b>Event Name:<i>', s, '</i></b><br><br>' )
    return(out)
  })
  
  output$eventname <- renderText({
    s <- getterm1(session)
    if(s == '') {
      s <- 'None'
    }
    out <- paste( '<b>Event Term:<i>', s, '</i></b><br><br>' )
    return(out)
  })
  
  output$limit <- renderText({ renderterm( getlimit( session ), 'Limit Analysis to', 'most frequent drugs') } )
  output$start <- renderText({ 
    startfont <- '<i><font color="dodgerblue" size="4">'
    endfont <- '</font></i>'
    renderterm( getstart( session ), 'Start analysis at ranked frequency count # ',
                label2=paste( '<br>Analyzing counts with ranked frequencies from',
                              startfont, getstart( session ) , endfont,
                              'to', 
                              startfont, getstart( session )+getlimit( session )-1, endfont  ) ) 
  } )
  
  output$numsims <- renderText({ renderterm( getnumsims( session ), 'Number of simulations:', '' ) } )
  
#   output$limit <- renderText({
#     s <- getlimit( session )
#     if(s == '') {
#       s <- 'None'
#     }
#     out <- paste( '<b>Max # of Events:<i>', s, '</i></b><br><br>' )
#     return(out)
#   })
#   
#   output$start <- renderText({
#     s <- getstart( session )
#     mylist <-  getdrugcounts999( )
#     mydf <- mylist$mydf
#     counts <- mydf$count
#     if(s == '') {
#       s <- 'None'
#     }
#     out <- paste( '<b>Rank of first event:<i>', s, '</i></b><br>
#                   Analyzing counts with ranks from', s , 'to',s+getlimit( session )-1 ,'<br>' )
#     return(out)
#   })
#************************************
# Get Drug-Event Query
#*********************
  
  getdrugcounts999 <- reactive({

    if ( is.null( getterm1(session) ) ){
      return(data.frame( c( paste('Please enter a', getsearchtype(), 'name') , '') ) )
    }
    q <- geturlquery()
    # browser()
    
    v <- c( '_exists_','_exists_' , getexactterm1var(), gettimevar() )
    t <- c(  input$v1, getexactterm1var() ,q$t1, gettimerange()  )
    
    # browser()
    if (q$concomitant == TRUE){
      t[3] <-  toupper(q$dename)
      # browser()
      mylist <-  getcounts999fda( session, v= v, t=t, 
                               count=getprrvarname(), exactrad = input$useexact )
    } else {
      v <- c( '_exists_',getexactterm1var() , getexactterm1var(), gettimevar() )
      t <- c(  input$v1, q$t1, gettimerange()  )
      mylist <-  getcounts999( session, v= v, t= t, 
                               count=getprrvarname(), exactrad = input$useexact )
    }
    
    return( list(mydf=mylist$mydf   ) )
  })    
  
#============================  
#getdrugcounts
# Get counts of events or reports for a specified drug  
  getdrugcounts <- reactive({
    #
    geturlquery()
#    mylist <-  getdrugcounts999()
   mylist <-  getdrugcounts999(  )
#How many events in first 999?
    totalevents <- sum(mylist$mydf$count )
    #    print(totalevents)
# How many are we evaluting? 
    start <- getstart( session )
    last <- min(getlimit( session ) + start - 1, nrow(  mylist$mydf ) )
    #If Not enough event terms to start at start, look at last limit values
    if( last < start )
    {
      start <- last - getlimit( session )
    }
    #Create two copies of events to study that only contain terms to analyze
    #mydfE will have counts based on events
    #mydfR will have counts based on reports
    mydfE <- mylist$mydf[start:last,]
    mydfR <- mylist$mydf[start:last,]
      s <- mydfR$term
      s<- paste0('%22', s, '%22', collapse='+')
      # v <- c( getbestterm1var() , getprrvarname(), gettimevar() )
      # t <- c( getbestterm1() ,s, gettimerange() )
      v <- c( '_exists_', getbestterm1var() , getprrvarname(), gettimevar() )
      t <- c( input$v1, getbestterm1() , s,  gettimerange() )
      
#      myurl2 <- buildURL(v= v, t=t, addplus=FALSE )
#     myquery <- fda_fetch_p( session, myurl2)
#      mydfR <- rbind( mydfR, c('Other', as.numeric( gettotals()$totaldrug  - myquery$meta$results$total ) ) )
      mydfR <- rbind( mydfR, c('Other', as.numeric( totalevents  - sum(mydfE$count ) ) ) )
      mydfR[,2] <- as.numeric(mydfR[,2])
      mydfE <- rbind(mydfE, c('Other', as.numeric( totalevents  - sum(mydfE$count) ) ) )
      mydfE[,2] <- as.numeric(mydfE[,2])
    return( list(mydfE=mydfE, mydfR = mydfR, myurl=mylist$myurl  ) )
  })  
  
  
  #Build table containing drug-event pairs
  getdrugcountstable <- reactive({
    geturlquery()
    mydf <- getdrugcounts()
    myurl <- mydf$myurl
    mydf <- mydf$mydfE
    mydfsource <- mydf
#     names <- c('v1','t1' ,'v2', 't2', gettimevar())
#     values <- c(getbestterm1var(), getbestterm1(), getprrvarname() )
    names <- c('v1','t1' ,'v3', 't3', 'v2', 't2' )
    values <- c(getbestterm1var(), getbestterm1(), gettimevar(), gettimerange(),  getprrvarname() )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    if (getwhich()=='E')
      {
      mydf[,1] <- coltohyper(mydf[,1],  'LRE',
                           mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
      } else {
        mydf[,1] <- coltohyper(mydf[,1],  'LRE',
                               mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend()  ) )
      }
    return( list(mydfE=mydf, myurl=(myurl), mydfsource = mydfsource  ) )
  })  
  
  
  getcodruglist <- reactive({
    v <- c('_exists_', '_exists_',getbestterm1var(), gettimevar() )
    t <- c( input$v1, getbestterm1var(), getbestterm1(), gettimerange() )
    myurl <- buildURL( v, t, 
                       count= getexactterm1var(), limit=1000 )
    mydf <- fda_fetch_p( session, myurl)
    mydf <- mydf$result[1:1000,]
    mydf <- mydf[!is.na(mydf[,2]), ]
    mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
    return( list( mydf=mydf, myurl=myurl) )
  })
  
  getcoeventlist <- reactive({
    # browser()
    q<-geturlquery()
    
    if (q$concomitant == TRUE){
      v <- c( '_exists_', '_exists_',getbestterm1var(), gettimevar() )
      t <- c( input$v1, getbestterm1var(), getbestterm1(), gettimerange() )
      t[3] <- toupper(q$dename)
      myurl <- buildURL( v, t,
                         count= getprrvarname(), limit=1000 )
      mydf <- fda_fetch_p( session, myurl)
      mydf <- mydf$result[1:1000,]
    } else {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      
      totaleventQuery<-createConEventQuery(q$t1, input$date1, input$date2)
      totaleventResult <- con$aggregate(totaleventQuery)
      # eventReport<-totaleventResult$safetyreportid
      colnames(totaleventResult)[1]<-"term"
      con$disconnect()
      
      mydf <- totaleventResult[1:1000,]
    }
    
    mydf <- mydf[!is.na(mydf[,2]), ]
    mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
    
    return( list( mydf=mydf) )
  })
  
  getalleventlist <- reactive({
    q<-geturlquery()
    
    # browser()
    if (q$concomitant == TRUE){
      v <- c('_exists_', '_exists_', '_exists_', gettimevar())
      t <- c( input$v1, getterm1var(),"patient.reaction.reactionmeddrapt", gettimerange())
      myurl <- buildURL( v, t,
                         count= "patient.reaction.reactionmeddrapt.exact", limit=1000 )
      mydf <- fda_fetch_p( session, myurl)
      mydf <- mydf$result[1:1000,]
    } else {
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      
      totaleventQuery<-totalEventInReports(input$date1, input$date2)
      totaleventResult <- con$aggregate(totaleventQuery)
      # eventReport<-totaleventResult$safetyreportid
      colnames(totaleventResult)[1]<-"term"
      con$disconnect()
      
      
      mydf <- totaleventResult[1:1000,]
      
    }
    
    mydf <- mydf[!is.na(mydf[,2]), ]
    mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
    # browser()
    return( list( mydf=mydf) )
  })
  # getalleventlist <- reactive({
  #   v <- c('_exists_', '_exists_', '_exists_', gettimevar())
  #   t <- c( input$v1, getterm1var(),"patient.reaction.reactionmeddrapt", gettimerange() )
  #   myurl <- buildURL( v, t, 
  #                      count= "patient.reaction.reactionmeddrapt.exact", limit=1000 )
  #   mydf <- fda_fetch_p( session, myurl)
  #   mydf <- mydf$result[1:1000,]
  #   mydf <- mydf[!is.na(mydf[,2]), ]
  #   mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
  #   return( list( mydf=mydf, myurl=myurl) )
  # })
  # 
  getcocountsE <- reactive({
    
    return( getcocounts('E') )
  })
  
  getcocountsD <- reactive({
    
    return( getcocounts('D') )
  })
  
  #**************************
  # Concomitant drug table
  getcocounts <- function(whichcount = 'E'){
    geturlquery()
    # browser()
    if ( is.null( getterm1(session) ) ){
      return(data.frame( c(paste('Please enter a drug and event name'), '') ) )
    }
    if( whichcount=='D')
    {
      mylist <- getcodruglist()
    } else (
      mylist <- getcoeventlist()
    )
    mydf <- mylist$mydf
    myurl <- mylist$myurl
    if(length(mydf[,"cumsum"])==0)
    {
      return (NULL);
    }
    sourcedf <- mydf
    #    print(names(mydf))
    #Drug Table
    if (whichcount =='E'){
      whichapp <- 'LRT'
      colname <- 'Drug Name'
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
        
        mydf <- data.frame(D=dashlinks, L=medlinelinks, mydf)
        mynames <- c( 'D', 'L', i18n()$t(colname), i18n()$t('Count'), i18n()$t('Cum Sum')) 
      }
      else {
        medlinelinks <- rep(' ', nrow( sourcedf ) )
        mynames <- c('-', i18n()$t(colname), i18n()$t('Count'), i18n()$t('Cum Sum')) 
      }
      #Event Table
    } else {
      whichapp <- 'LRE'
      colname <- i18n()$t("Preferred Term")
      # mynames <- c('M', i18n()$t(colname), i18n()$t('Count'), i18n()$t('Cum Sum')) 
      mynames <- c( i18n()$t(colname), i18n()$t('Count'), i18n()$t('Cum Sum'))
      medlinelinks <- makemedlinelink(sourcedf[,1], 'M') 
      mydf <- data.frame(mydf) 
    }
#     names <- c('v1','t1')
#     values <- c(getbestterm1var() )
    names <- c('v1','v3', 't3','t1'  )
    values <- c(getbestterm1var(), gettimevar(), gettimerange() ) 
    mydf[,'count'] <- numcoltohyper(mydf[ , 'count' ], mydf[ , 'term'], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,'term'] <- coltohyper(mydf[,'term'], whichapp , mybaseurl = getcururl(), 
                                append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    names(mydf) <- mynames
    return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
  }   
getindcounts <- reactive({
    q <- geturlquery()
    if ( is.null( getterm1(session) ) ){
      return(data.frame( c(paste('Please enter a', getsearchtype(), 'name'), '') ) )
    }
    v <- c('_exists_', getbestterm1(), gettimevar() )
    t <- c( input$v1, getterm1var(), gettimerange() )
    
    if (q$concomitant == TRUE){
      myurl <- buildURL( v= getbestterm1var(), t=toupper(q$dename),
                         count= paste0( 'patient.drug.drugindication', '.exact'), limit=1000)
      mydf <- fda_fetch_p( session, myurl)
      mydf <- mydf$result[1:1000,]
    } else {
      
      con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
      drugQuery <- SearchEventReports(q$t1, input$date1, input$date2)
      ids <- con$aggregate(drugQuery)
      con$disconnect()
      
      loops <- ceiling(length(ids$safetyreportid)/100)

      mydf <- data.frame(matrix(ncol = 2, nrow = 0))
      x <- c("term", "count")
      colnames(mydf) <- x
      
      for (i in 1:loops){
        if (i==1){
          start = i
          end = i*100
          myurl <- buildURL(v= 'safetyreportid', t=paste(ids$safetyreportid[start:end], collapse=', ' ),
                            count=paste0( 'patient.drug.drugindication', '.exact') )
          result <-  fda_fetch_p(session, myurl)$result
          
          if (!is.null(result)){
            for (i in result[['term']]){
              if (!(i %in% mydf$term)){
                value <- 0
                mydf[i,] = c(i, as.numeric(value))
              }
              mydf[mydf$term==i,]$count <-as.numeric(mydf[mydf$term==i,]$count) + result[result$term==i,]$count
            }
          }
          
        } else {
          start = (i-1)*100 + 1
          end = i*100
          myurl <- buildURL(v= 'safetyreportid', t=paste(ids$safetyreportid[!is.na(ids$safetyreportid[start:end])][start:end], collapse=', ' ),
                            count=paste0( 'patient.drug.drugindication', '.exact') )
          result <- fda_fetch_p(session, myurl)$result
          
          if (!is.null(result)){
            for (i in result[['term']]){
              if (!(i %in% mydf$term)){
                value <- 0
                mydf[i,] = c(i, value)
              }
              mydf[mydf$term==i,]$count <- as.numeric(mydf[mydf$term==i,]$count)  + result[result$term==i,]$count
            }
          }
        }
      }
      mydf <- mydf[1:1000,]
    }
    
    # browser()
   
    
    if(length(mydf)==0)
    {
      return(NULL)
    }
    
    mydf <- mydf[!is.na(mydf[,2]), ]
    mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
    sourcedf <- mydf
    
#    medlinelinks <- makemedlinelink(sourcedf[,1], '?')
    names <- c('v1','t1' ,'v3', 't3', 'v2', 't2'  )
    values <- c(getbestterm1var(), getbestterm1(), gettimevar(), gettimerange(), paste0( 'patient.drug.drugindication', '.exact') )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,1] <- makemedlinelink(sourcedf[,1], mydf[,1])
    
    return( list( mydf=mydf, sourcedf=sourcedf ) )
  })   
  

#Get total counts in database for each event and Total reports in database
gettotals<- reactive({
  q <- geturlquery()
  
  if (q$concomitant == TRUE){
    v <- c('_exists_', '_exists_', '_exists_', gettimevar() )
    t <- c( input$v1, getprrvarname(), getbestterm1var(), gettimerange() )
    totalurl <- buildURL(v, t,  count='', limit=1)
    totalreports <- fda_fetch_p( session, totalurl)
    total <- totalreports$meta$results$total

    v <- c( '_exists_', '_exists_', getbestterm1var(), gettimevar() )
    t <- c( input$v1, getprrvarname(), getbestterm1(), gettimerange() )
    t[3] <- toupper(q$dename)
    totaldrugurl <- buildURL( v, t, count='', limit=1)
    totaldrugreports <- fda_fetch_p( session, totaldrugurl)
        if ( length( totaldrugreports )==0 )
          {
          totaldrugurl <- buildURL( v= getterm1var(), t=getterm1(session), count='', limit=1)

          totaldrugreports <- fda_fetch_p( session, totaldrugurl)
          }

    totaldrug <- totaldrugreports$meta$results$total
  } else {
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    
    totalQuery<-totalreports(input$date1, input$date2)
    totalResult <- con$aggregate(totalQuery)
    total<-totalResult$safetyreportid
    
    totaleventQuery<-totalEventReports(q$t1)
    totaleventResult <- con$aggregate(totaleventQuery)
    totaldrug<-totaleventResult$safetyreportid
    con$disconnect()
  }

  
  adjust <- total/totaldrug
  out <- list(total=total, totaldrug=totaldrug, adjust=adjust )
}) 
#   gettotals<- reactive({
#     geturlquery()
#     
#     
#     v <- c(  '_exists_', '_exists_', '_exists_', gettimevar() )
#     t <- c(  input$v1, getprrvarname(), getbestterm1var(), gettimerange()  )
#     totalurl <- buildURL(v, t,  count='', limit=1)
#     totalreports <- fda_fetch_p( session, totalurl)    
#     total <- totalreports$meta$results$total
#     
#     v <- c( '_exists_', '_exists_', getbestterm1var(), gettimevar() )
#     t <- c( input$v1, getprrvarname(), getbestterm1(), gettimerange()  )
#     totaldrugurl <- buildURL( v, t, count='', limit=1)
#     totaldrugreports <- fda_fetch_p( session, totaldrugurl)    
# #     if ( length( totaldrugreports )==0 )
# #       {
# #       totaldrugurl <- buildURL( v= getterm1var(), t=getterm1(session), count='', limit=1)
# # 
# #       totaldrugreports <- fda_fetch_p( session, totaldrugurl)
# #       }
#     
#     totaldrug <- totaldrugreports$meta$results$total
#     
#     adjust <- total/totaldrug
#     out <- list(total=total, totaldrug=totaldrug, adjust=adjust, 
#                 totalurl=(totalurl), totaldrugurl=(totaldrugurl) )
#   }) 
  #end queries
# Calculations =========
  #Calculate PRR and put in merged table
  getprr <- reactive({
    geturlquery()
    # browser()
    drug1_event <- getdrugcounts()$mydfE
#    drug2_event <- getdrugcounts()$mydfR
    if ( !is.data.frame(drug1_event) )  {
      return(data.frame(Error=paste( 'No events for', getsearchtype(),  getterm1(session) ), Count=0 , Count=0,Count2=0, PRR='prr'))
    }
    allevent <- geteventtotals()$alleventsdf
    alldrug <- geteventtotals()$allreportsdf
#    print( alldrug)
    
    totals <- gettotals()
    mytitle <- 'Calculating Statistics'
    createAlert(session, 'alert', 'simalert',
                title=mytitle, content = 'This may take a while.', dismiss = FALSE)
    comb <- merge(drug1_event, allevent[, c('term', 'count')], by.x='term', by.y='term')
#    comb2 <- merge(drug2_event, alldrug[, c('term', 'count')], by.x='term', by.y='term')
#    print(totals)
    if (getwhich()=='E')
      {
#       #Total number of reports
#       rn.. <- totals$total
#       #Total reporst for drug j
#       rn.j <- totals$totaldrug
#       #Total reports for DE combination
#       rnij <-  comb2$count.x
#       #Total report forevent i
#       rni. <- comb2$count.y
#      print(rn..)
      
      
      #Total number of Events
      alleventdf <- getalleventlist()$mydf
      allevents <- sum(alleventdf$count)
      n.. <- sum(alleventdf$count)
      #Total reporst for drug j
      n.j <- sum(comb$count.x)
      n.. <- sum(alleventdf$count)
      #Total reports for DE combination
      nij <-  comb$count.x
      #Total report for event i
      ni. <- comb$count.y
      

      pi. <- ni./n..
#      rpi. <- rni./rn..
      a <- nij
      b <- ni. - nij
      c <- n.j - nij
      d <- n.. - ni. - n.j + nij
#       PRRE <- prre( n.., ni., n.j, nij )
#       PRRD <- prrd( rn.., rni., rn.j, rnij )
#       LLR <- LLR( n.., ni., n.j, nij )
#       LLR[PRRE < 1] <- 0       
#Total number of Events
      alleventdf <- getalleventlist()$mydf
      allevents <- sum(alleventdf$count)
      mystats <- calcLRTstats(totals, comb, NULL, allevents)
      comb <- data.frame(comb, sigcol="NS",  LLR=mystats$LLRE, rrr=mystats$RR, stringsAsFactors = FALSE)
#      comb2 <- data.frame(comb2, sigcol="NS",  LLR=mystats$LLRR, rrr=mystats$PRRD, stringsAsFactors = FALSE)
      
      } 
    comb <- data.frame(comb, a, b, c, d, pi., nij,  n.j, ni.,  n..)
#    comb2 <- data.frame(comb2, a, b, c, d, rpi., rnij,  rn.j, rni.,  rn..)
#    print(  comb2[, 'rn..'])
    if (getwhich() =='E'){ 
      names <- c('v1', 'term1','term2')
      values <- c(getterm1var(), gsub( '"', '', getbestterm1(), fixed=TRUE  ) )
      cpa <- numcoltohyper( paste(comb[ , 1], 'CPA'), comb[ , 1], names, values, type='C', 
                            mybaseurl =getcururl() )
      
      dynprr <- numcoltohyper( paste(comb[ , 1], 'PRR'), comb[ , 1], names, values, type='P',
                               mybaseurl =getcururl() )
      comb <- data.frame(  comb, dynprr, cpa,  mystats$RR)
#      comb2 <- data.frame( M='M' , comb2, dynprr, cpa,  mystats$RR)
#      print(  comb2[, 'rn..'])
      comb<- data.frame(comb,
                        LLR= mystats$LLRE,
                        RR= mystats$RR,
                        PRRD= mystats$PRRD
      )
#       comb2 <- data.frame(comb2,
#                         LLR= mystats$LLRE,
#                         RR= mystats$RR,
#                         PRRD= mystats$PRRD
#      )
#      print(  comb2[, 'rn..'])
#      print( names(comb) )
      sourcedf <- comb
#      sourcedf2 <- comb2
      colname <- i18n()$t("Preferred Term")
      iname <- 'M'
      medlinelinks <- makemedlinelink(sourcedf[,2], iname)
    }
    # comb[,'M'] <- medlinelinks
#    comb2[,'M'] <- medlinelinks
    names <- c('v1','t1' ,'v2', 't2')
    values <- c(getbestterm1var(), getbestterm1(), getprrvarname() )
#    comb[,'count.x'] <- numcoltohyper(comb[ , 'count.x'], comb[ , 'term'], names, values, mybaseurl =getcururl(), addquotes=TRUE )
    names <- c('v1','t1' ,'v2', 't2')
    values <- c('_exists_', getterm1var()  , getprrvarname() )
#    comb[, 'count.y' ] <- numcoltohyper(comb[ , 'count.y' ], comb[ , 'term'], names, values , mybaseurl = getcururl(), addquotes=TRUE)
    comb[,'term'] <- coltohyper( comb[,'term'], 'LR' , 
                            mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    comb <- comb[order(comb$LLR, decreasing = TRUE),]
    sourcedf <- sourcedf[order(sourcedf$LLR, decreasing = TRUE),]
    row.names(comb)<- seq(1:nrow(comb))
#    row.names(comb2)<- seq(1:nrow(comb2))
    countname <- paste( 'nij for', getterm1(session))
#    print(head(comb2))
    names(comb) <-  c(  colname, countname, 
                       'ni.', "Significant?", 'LLR',
                       'RR',  'a', 'b', 'c', 'd', 'pi.',
                       'nij',  'n.j', 'ni.',  'n..',
                       'Dynamic PRR', 'Change Point Analysis', 'PRR2', 'LLR', 'PRRE', 'PRRD' )
#     names(comb2) <-  c( iname, colname, countname, 
#                        'ni.', "Significant?", 'LLR',
#                        'PRR',  'a', 'b', 'c', 'd', 'pi.',
#                        'nij',  'n.j', 'ni.',  'n..',
#                        'Dynamic PRR', 'Change Point Analysis', 'PRR2', 'LLR', 'PRRE', 'PRRD' )
#    print(  comb2[, 'n..'])
 #   print((comb2$pri.))
    keptcols1 <-  c(  colname, "Significant?", 'LLR',
                    'RR',  'nij' )
#     keptcols2 <-  c( iname, colname, "Significant?", 'LLR',
#                      'PRR' )
    #    mydf <- mydf[, c(1:4, 7,8,9)]
#      print(comb[, keptcols])
#      print(comb2[, keptcols])
    if(!is.null(session$simalert))
    {
      closeAlert(session, 'simalert')
    }
    
    numsims <- getnumsims( session )
    mycritval <- getCritVal2(session, numsims, comb$n.j[1], comb$ni., comb$n..[1], comb$pi., .95)
    critval05 <- mycritval$critval
#     mycritval2 <- getCritVal2(numsims, comb2$n.j[1], comb2$ni., comb2$n..[1], comb2$pi., .95)
#     critval052 <- mycritval2$critval
    comb[ comb$LLR > critval05  , "Significant?"] <- "p < 0.05"
 #   comb2[ comb2$LLR > critval052  , "Significant?"] <- "p < 0.05"
#    comb[, 'nij'] <- prettyNum(comb[, 'nij'] , big.mark=',', drop0trailing = TRUE)
    comb[, 'n.j'] <- prettyNum(comb[, 'n.j'] , big.mark=',', drop0trailing = TRUE)
    comb[, 'ni.'] <- prettyNum(comb[, 'ni.'] , big.mark=',', drop0trailing = TRUE)
    comb[, 'n..'] <- prettyNum(comb[, 'n..'] , big.mark=',', drop0trailing = TRUE)
#     comb2[, 'nij'] <- prettyNum(comb2[, 'nij'] , big.mark=',', drop0trailing = TRUE)
#     comb2[, 'n.j'] <- prettyNum(comb2[, 'n.j'] , big.mark=',', drop0trailing = TRUE)
#     comb2[, 'ni.'] <- prettyNum(comb2[, 'ni.'] , big.mark=',', drop0trailing = TRUE)
#     comb2[, 'n..'] <- prettyNum(comb2[, 'n..'] , big.mark=',', drop0trailing = TRUE)
 #   print(comb2[, keptcols])
    return( list( comb=comb[, keptcols1], sourcedf=sourcedf, 
                  maxLRT = max(comb$LLR), critval=mycritval, numsims=numsims, colname=colname ) )
  })
  
  geteventtotalstable <- reactive({
    geturlquery()
    if(is.null(geteventtotals())){
      return(NULL)
    }
    mydf <- geteventtotals()$alleventsdf
    mydf2 <- geteventtotals()$allreportsdf
    sourcedf <- mydf
#     names <- c('v1','t1' ,'v2', 't2')
#     values <- c('_exists_', getterm1var()  , getprrvarname() )
    names <- c('v1','t1' ,'v3', 't3', 'v2', 't2'  )
    values <- c('_exists_', getterm1var() , gettimevar(), gettimerange(), getprrvarname() )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,1] <- coltohyper(mydf[,1], 'LR', 
                           mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    return( list(mydf=mydf, mydf2= mydf2 , sourcedf=sourcedf) )
  })  
  
geteventtotals <- reactive(
  {
  q <- geturlquery()
  # browser()
  starttime <- Sys.time()
  mydf <- getdrugcounts()$mydfE
  if ( !is.data.frame(mydf) ) {return(NULL)}
  realterms <- mydf[,1]
  foundtermslist <- mydf[,1]
  foundtermslist <- paste('"', foundtermslist, '"', sep='')
  foundtermslist <- gsub(' ', '%20',foundtermslist, fixed=TRUE )
  myrows <- length(foundtermslist)
#   if (getlimit( session ) < 35)
#     {
#      myrows <- myrows +1 
#     }
  allevent <- data.frame(term=rep(URL='u', 'a', myrows ), count=0L,  stringsAsFactors = FALSE)
  allreport <- data.frame(term=rep(URL='u', 'a', myrows ), count=0L,  stringsAsFactors = FALSE)
  
  for (i in seq_along(foundtermslist))
    {
    if ( realterms[[i]] =='Other')
    {
      allreport[i, 'URL'] <- 'removekey( makelink( myurl3 )'
      allreport[i, 'term'] <- 'Other'
#      allreport[i, 'count'] <- as.numeric(gettotals()$total - myquery3$meta$results$total) 
      allreport[i, 'count'] <- as.numeric(gettotals()$total - sum(allevent$count) ) 
      # End find exact      
      allevent[i, 'URL'] <- '-' 
      allevent[i, 'term'] <- 'Other'
      mydf <- getalleventlist()$mydf
      allevent[i, 'count'] <- as.numeric( sum(mydf$count) - sum(allevent$count) )
    } else {
      if (q$concomitant == TRUE){
        # eventvar <- gsub('.exact', '', getprrvarname(), fixed=TRUE)
        # #      myv <- c('_exists_', eventvar)
        # myv <- c('_exists_', '_exists_', getprrvarname(), gettimevar() )
        # myt <- c( input$v1, getterm1var(),  str_replace_all(foundtermslist[[i]], "[[:punct:]]", " "), gettimerange()   )
        # #      cururl <- buildURL(v= myv, t=myt, count= getprrvarname(), limit=1)
        # cururl <- buildURL(v= myv, t=myt, limit=1)
        # #Sys.sleep( .25 )
        # all_events2 <- fda_fetch_p( session, cururl, message= i )
        # # browser()
        # if( length( all_events2) != 0 )
        # {
        #   allevent[i, 'count'] <- all_events2$meta$results$total
        #   allevent[i, 'term'] <- realterms[[i]]
        # } else {
        #   allevent[i, 'count'] <- 0
        #   allevent[i, 'term'] <- realterms[[i]]
        # }
        eventvar <- gsub('.exact', '', getprrvarname(), fixed=TRUE)
        #      myv <- c('_exists_', eventvar)
        myv <- c('_exists_', '_exists_', getprrvarname(), gettimevar() )
        myt <- c( input$v1, getterm1var(),  foundtermslist[[i]], gettimerange()   )
        #      cururl <- buildURL(v= myv, t=myt, count= getprrvarname(), limit=1)
        cururl <- buildURL(v= myv, t=myt, limit=1)
        #Sys.sleep( .25 )
        all_events2 <- fda_fetch_p( session, cururl, message= i )
        allevent[i, 'URL'] <- removekey( makelink( cururl ) )
        allevent[i, 'term'] <- realterms[[i]]
        allevent[i, 'count'] <- all_events2$meta$results$total
        #       allreport[i, 'URL'] <- removekey( makelink( cururl ) )
        #       allreport[i, 'term'] <- realterms[[i]]
        #       allreport[i, 'count'] <- all_events2$meta$results$total
      } else {
        # browser()
        # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
        con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
        # drugName<-unlist(strsplit(myt[2], '\\"'))[2]
        drugName<-realterms[i]
        
        drugTotalQuery<-totalDrugReportsOriginal(str_replace_all(drugName, "[[:punct:]]", " "), input$date1, input$date2)
        totaldrug <- con$aggregate(drugTotalQuery)
        all_events2 <- totaldrug
        if( !is.null( all_events2$safetyreportid ) )
        {
          allevent[i, 'count'] <- all_events2$safetyreportid
          allevent[i, 'term'] <- realterms[[i]]
        }
       
      }  
      
      # allevent[i, 'URL'] <- removekey( makelink( cururl ) )
      # browser()
      
      # if (length(totaldrug) != 0){
      #   allevent[i, 'term'] <- realterms[[i]]
      #   
      # }
      
      # allevent[i, 'count'] <- all_events2$meta$results$total 
#       allreport[i, 'URL'] <- removekey( makelink( cururl ) )
      
      # allreport[i, 'term'] <- realterms[[i]]
#       allreport[i, 'count'] <- all_events2$meta$results$total
      }
    }
  # browser()
#  print( as.double(Sys.time()-starttime ) )
  return( list( alleventsdf = allevent, allreportsdf = allreport )  )
} )
 #end calculations

# setters ======

# setters ======
#Tab 1: LRT Results based on Total Events
prr <- reactive({  
  getcururl()
  if (getterm1(session)=="") {
    return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, Count=0, PRR=0, ROR=0))
  }
  checkdf( getprr()[['comb']], getsearchtype() )
})

prrnohyper <- reactive({  
  myprr <- prr()
  mysource <- getprr()[['sourcedf']]
  myprr[,2] <- mysource[,2]
  out <- myprr[, -1]
  return(out)
})

# output$prr <- renderTable({  
#   prr()
# },  sanitize.text.function = function(x) x)


output$dlprr <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(prrForExcel, file, sheetName="prr")
  }
)
output$dlsimplot <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(simForExcel, file, sheetName="Simulation Results for Event Based LRT")
  }
)
output$dlAnalyzedEventCountsforDrug <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(AnalyzedEventCountsforDrugForExcel, file, sheetName="Analyzed Event Counts for Drug")
  }
)
output$dlall <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(allForExcel, file, sheetName="All")
  }
)
output$dlcoquery <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryForExcel, file, sheetName="coquery")
  }
)
output$dlcoqueryE <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryEForExcel, file, sheetName="coqueryE")
  }
)
output$dlcoquery2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coquery2ForExcel, file, sheetName="Counts For Drugs")
  }
)
output$dlcoqueryA <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryAForExcel, file, sheetName="coqueryA")
  }
)
output$dlindquery <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(indqueryForExcel, file, sheetName="indquery")
  }
) 


output$prr <- DT::renderDT({
  if(getterm1( session)!=""){
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- prr()
  prrForExcel<<-res
  
  if ("Error" %in% colnames(res) )
  {
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
    
  }
  else{
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    PRRResIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  
  if (!is.null(input$sourcePRRDataframeUI)){
    if (input$sourcePRRDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Eprres.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        dom = 't',
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
  } else {
    return ( datatable(
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }
  
  }
  else{
    # s1 <- calccpmean()
    geturlquery()
    return (NULL)
  }
},
escape=FALSE)

getcloudprrscale <- reactive({
  scale <- getcloud_try(getprr()$sourcedf, name=2, freq='LLR',  scale1=9 )
  return(scale)
})
cloudprr <- function(){ 
  scale <- getcloudprrscale()
  cloudplot( mydf = getprr()$sourcedf, session, scale1=9, 
             name=2, freq = 'LLR', stattext='LLR')
}

output$cloudprr <- renderPlot({  
  cloudprr()
}, height=900, width=900)


textplot <- function(){ 
  if (getterm1( session )!="") {
    mylist <- getprr()
    mydf <- mylist$comb
    mydf <- mydf[ which(mydf[,'LLR'] > 0 ),]
    y <- mydf[,'LLR']
    x <- mydf[, 'nij']
    w <- getvalvectfromlink( mydf[, mylist$colname ] )
    refline <- mylist$critval$critval
  } else {
    w <- NULL
    y <-NULL
    x <- NULL
    refline <- 1
  }
  #plot with no overlap and all words visible
  return ( mytp(x, y, w, refline ) )
  #cloudout(mydf, paste('PRR for Events in Reports That Contain', getterm1( session ) ) )  
}
output$textplot <- renderPlot({ 
  textplot()
}, height=400, width=900)

output$prrtitle <- renderUI({ 
  maxLRT <- getprr()$maxLRT
  critval <- getprr()$critval$critval
  out=paste( '<h4>Results sorted by LRR</h4><h4>Reporting Ratios</h4>',
             'Critical Value =',  round( critval, 2),
             '<br># of Simulations =',  getprr()$numsims
  )
  addPopover(session=session, id="prrtitle", title=i18n()$t("Application Info"), 
             content=out, placement = "left",
             trigger = "hover", options = list(html = "true"))
  
  return( HTML('<button type="button" class="btn btn-info">i</button>') )
})
# output$prrtitle <- renderText({ 
#   prrtitle()
# })

info <- reactive(
  { 
    mylist <- getprr()
    mydf <- mylist$comb
    brushedPoints(mydf, input$plot_brush, yvar = "LLR", xvar = 'nij' )
  }
)
output$info <- renderTable({
  info()
},  sanitize.text.function = function(x) x)
##
# Tab 2: Simulation Results for Event Based LRT

simplot <- function(){  
  getcururl()
  if (getterm1(session)=="") {
    return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, Count=0, PRR=0, ROR=0))
  } else {
    mydf <- getprr()
    simForExcel<<-mydf
    if ("Error" %in% colnames(mydf) )
    {
      createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Event"), append = FALSE)
      plot.new()
      hide("mainrow")
      return(NULL)
      
    }
    else{
      if(!is.null(session$nodataAlert))
      {
        closeAlert(session, "nodataAlert")
      }
    }
    mycrit <- mydf$critval$critval
    vals <- mydf$critval$mymax
    myrange <- range(vals)
    interval <- (mycrit - myrange[1])/20
    mybreaks <- c( seq(myrange[1], mycrit, interval ),  seq(mycrit+interval,  myrange[2] + interval, interval ) )
    # truehist(vals , breaks=mybreaks, 
    #          main=i18n()$t("Histogram of Simulated Distribution of LLR"), 
    #          xlab=i18n()$t("Loglikelihood Ratio"), xaxt='n' )
    # text(mycrit,.3, paste(i18n()$t("Rejection Region, LLR >"), round(mycrit, 2) ), pos=4, col='red')
    # smallbreaks <- seq(0, max(mybreaks), 1)
    # 
    # smallbreaks <-  c( round(mycrit, 2), smallbreaks )
    # axis(1, smallbreaks, las=3 )
    # abline(v=mycrit, col='red', lwd=2)
    # if ( is.data.frame(mydf) ) 
    # {
    # } else {
    #   return(data.frame(Term= paste(i18n()$t("No records for"), getterm1(session)), Count=0))
    # }
    fig <- plot_ly(x = ~vals, nbinsx = 20,type = "histogram",histnorm='probability')
    fig <- fig %>% layout(title = i18n()$t("Histogram of Simulated Distribution of LLR"),yaxis=list(type='linear'), xaxis = list(title = i18n()$t("Likelihood Ratio"), zeroline = FALSE))
    fig
  }
}
output$simplot <- renderPlotly({  
  getcururl()
  if (!is.null(input$sourceLLRPlotReportUI)){
    if (input$sourceLLRPlotReportUI){
      withr::with_dir("/var/www/html/openfda/media", orca(simplot(), paste0(values$urlQuery$hash,"_Ehistogram.png")))
    }
    
  }
  simplot()
} )

#Tab 3 AnalyzedEventCountsforDrug

AnalyzedEventCountsforDrug <- reactive(
  {
    mydf <- getdrugcountstable()$mydfE
    checkdf(mydf, getterm1(session),
            names=c(i18n()$t("Term"), paste( i18n()$t("Counts for"), i18n()$t(getterm1(session))) ),
            changecell = c( row=nrow(mydf), column='Term', val='Other (# of Events)' ) )
  }
)

AnalyzedEventCountsforDrugnohyper <- reactive(
  {
    mydf <- AnalyzedEventCountsforDrug()
    mysource <- getdrugcountstable()$mydfsource
    mydf[, 1] <- mysource[,1]
    mydf[, 2] <- mysource[,2]
    return(mydf)
  }
)

# output$AnalyzedEventCountsforDrug <- renderTable({  
#   AnalyzedEventCountsforDrug()
# },  sanitize.text.function = function(x) x)


output$AnalyzedEventCountsforDrug <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- AnalyzedEventCountsforDrug()
  allForExcel<<-res
  if ("Error" %in% colnames(res))
  {
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
    
  }
  else{
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    PRRResIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  
  if (!is.null(input$sourceResDataframeUI)){
    if (input$sourceResDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Eresindata.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      resIndatatable,
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
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }
  
},
escape=FALSE)

getcloudAnalyzedEventCountsforDrugscale <- reactive({
  scale <- getcloud_try(getdrugcountstable()$mydfsource,   scale1=9 )
  return(scale)
})

cloudAnalyzedEventCountsforDrug <- function()
{ 
  scale <- getcloudAnalyzedEventCountsforDrugscale()
  cloudplot( mydf = getdrugcountstable()$mydfsource, session )
}
output$cloudAnalyzedEventCountsforDrug <- renderPlot({  
  cloudAnalyzedEventCountsforDrug()
}, height=900, width=900 )

queryAnalyzedEventCountsforDrug <- reactive(
  { 
    l <- getdrugcounts()
    return( 
      paste( '<b>Query:</b>', removekey( makelink(l['myurl']) ) , 
             '<br>' ) )
  }
)
output$queryAnalyzedEventCountsforDrug <- renderText({ 
  queryAnalyzedEventCountsforDrug()
}
)

titleAnalyzedEventCountsforDrug <- reactive(
  { 
    return( paste('<h4>Counts for', getterm1(session), '</h4>') )
  }
)
output$titleAnalyzedEventCountsforDrug <- renderText({ 
  titleAnalyzedEventCountsforDrug()
})

alldrugtextAnalyzedEventCountsforDrug  <- reactive({ 
  l <- gettotals()
  return( 
    paste( '<b>Total reports with', getsearchtype(), getterm1(session) , 'in database:</b>', prettyNum( l['totaldrug'], big.mark=',' ), '<br>') )
})
output$alldrugtextAnalyzedEventCountsforDrug  <- renderText({ 
  alldrugtextAnalyzedEventCountsforDrug()
})


alldrugqueryAnalyzedEventCountsforDrug <- reactive({ 
  l <- gettotals()
  mysum <- sum( getalleventlist( )$mydf$count )
  return( 
    paste( '<b>Query:</b>', removekey( makelink(l['totaldrugurl']) ) ) ) 
})
output$alldrugqueryAnalyzedEventCountsforDrug <- renderText({ 
  alldrugqueryAnalyzedEventCountsforDrug()
})

##
#Tab 4 Analyzed Event Counts for All Drugs

queryalltext <- function(){ 
  l <- gettotals()
  paste( '<b>Query:</b>', removekey( makelink(l['totalurl'] ) ), '<br>')
}
output$queryalltext <- renderText({ 
  queryalltext()
})



alltext <- function(){ 
  l <- gettotals()
  paste( '<b>Total reports with value for', getbestterm1var() ,'in database:</b>', prettyNum(l['total'], big.mark=',' ), '(meta.results.total)<br>')
}
output$alltext <- renderText({ 
  alltext()
})

alltitle <- function(){ 
  return( ('<h4>Counts for Entire Database</h4><br>') )
}
output$alltitle <- renderText({ 
  alltitle()
})

all <- function(){  
  all <- geteventtotalstable()$mydf[,c(1,2)]
  checkdf(all, paste(getsearchtype(), getterm1(session)), 
          names=c(i18n()$t("Term"), paste( i18n()$t("Counts for All Reports")) ), 
          changecell=c( row=nrow(all), column='Term', val='Other (# of Events)' ) )
}
allnohyper <- function(){  
  all <- geteventtotalstable()$mydf
  mysource <- geteventtotalstable()$sourcedf
  all[, 1] <- mysource[, 1]
  all[, 2] <- mysource[, 2]
  all[, 3] <- mysource[, 3]
  return (all)
}

# output$all <- renderTable({  
#   all()
# }, sanitize.text.function = function(x) x)


output$all <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- all()
  allForExcel<<-res
  if (length(res) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    PRRResIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  if (!is.null(input$sourceInDataframeUI)){
    if (input$sourceInDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Eallindata.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(  datatable(
      resIndatatable,
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
    return (   datatable(
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }

},
escape=FALSE)

getcloudallscale <- reactive({
  scale <- getcloud_try( geteventtotalstable()$sourcedf,   scale1=9 )
  return(scale)
})
cloudall <- function(){  
  scale <- getcloudallscale()
  cloudplot( mydf = geteventtotalstable()$sourcedf, session,
             termtype='Events', intype='Drug')
}
output$cloudall <- renderPlot({  
  cloudall()
}, height=900, width=900)

#End Tab 4 Analyzed Event Counts for All Drugs
##


##
# Tab 5: Counts For Drugs In Selected Reports
output$cotitleD <- renderText({ 
  return( ( paste0('<h4>Most Common Drugs In Selected Reports</h4><br>') ) )
})
output$cotitle <- renderText({ 
  return( ( paste0('<h4>Most Common Events In Selected Reports</h4><br>') ) )
})

popcoquery <- function() {
  text <- 'Frequency table for events found in selected reports. Event name is linked to LRT results for event \"m\" is linked to medline dictionary definition for event term'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}


popcoquery <- function() {
  #text <- 'Frequency table for events found in selected reports. Event name is linked to LRT results for event \"m\" is linked to medline dictionary definition for event term'
  text <- 'a'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}
coquery <- function(){  
  #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
  codrugs <- getcocountsE()$mydf
  checkdf(codrugs, getterm1(session))
} 
# output$coquery <- renderTable({  
#   coquery()
# }, sanitize.text.function = function(x) x)  

output$coquery <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- coquery()
  coqueryForExcel<<-res
  if ("Error" %in% colnames(res) )
  {
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
    
  }
  else{
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    resIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  resIndatatable <- resIndatatable[,1:(length(resIndatatable)-1)]
  
  if (!is.null(input$sourcePrrInDataframeUI)){
    if (input$sourcePrrInDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Eprrindata.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(datatable(
      resIndatatable,
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
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }
  
},
escape=FALSE)

querycotext <- function(){ 
  l <- getcocounts()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
}
output$querycotext <- renderText({ 
  querycotext()
})

cloudcoquery <- function(){   
  scale <- getcloudprrscale()
  cloudplot( mydf = getcocountsE()$sourcedf, session,
             termtype='Events', intype='Drugs' )
}

output$cloudcoquery <- renderPlot({  
  cloudcoquery()
}, height=900, width=900 )

##
# End Tab 5: Counts For Drugs In Selected Reports

##
# Tab 6 Event Counts for Drug

cotitleE <- function(){ 
  return( ( paste0('<h4>Most Common Events In Selected Reports</h4><br>') ) )
}
output$cotitleE <- renderText({ 
  return( ( paste0('<h4>Most Common Events In Selected Reports</h4><br>') ) )
})

querycotextE <- function(){ 
  l <- getcocountsE()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
}
output$querycotextE <- renderText({ 
  l <- getcocountsE()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
})

coqueryE <- function(){  
  #if ( getterm1() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
  codrugs <- getcocountsE()$mydf
  checkdf(codrugs, getterm1(session))
}
# output$coqueryE <- renderTable({  
#   coqueryE()
# }, sanitize.text.function = function(x) x)


output$coqueryE <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- coqueryE()
  if (is.null(res) )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    PRRResIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  datatable(
    resIndatatable,
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

coqueryEex <- function(){  
  codrugs <- getdrugcounts999()$excludeddf
  checkdf(codrugs, getterm1(session))
}
# output$coqueryEex <- renderTable({  
#   coqueryEex()
# }, sanitize.text.function = function(x) x)

output$coqueryEex <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- coqueryEex()
  coqueryEexForExcel<<-res
  if (length(res) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    resIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  
  if (!is.null(input$sourceCoDataframeUI)){
    if (input$sourceCoDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Ecoqevdata.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(  datatable(
      resIndatatable,
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
    return (   datatable(
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }

},
escape=FALSE)

cloudcoqueryE <- function(){  
  cloudplot( mydf = getcocountsE()$sourcedf, session,termtype='Events', intype='Drug' )
}
output$cloudcoqueryE <- renderPlot({  
  cloudcoqueryE()
}, height=900, width=900 )
##
# End Tab 6 Event Counts for Drug

output$cotitleA <- renderText({ 
  return( ( paste0('<h4>Most Common Events In All Reports</h4><br>') ) )
})





output$querycotextA <- renderText({ 
  l <- getalleventlist()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
})




# output$coqueryA <- renderTable({  
#   codrugs <-  getalleventlist( )$mydf
#   checkdf(codrugs, getterm1(session))
# }, sanitize.text.function = function(x) x)

output$coqueryA <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  res <- getalleventlist( )$mydf
  coqueryAForExcel<<-res
  if (length(res) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    resIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  resIndatatable <- resIndatatable[,1:(length(resIndatatable)-1)]
  
  
  if (!is.null(input$sourceAcDataframeUI)){
    if (input$sourceAcDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Ecoqadata.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(    datatable(
      resIndatatable,
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
    return (   datatable(
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }
  

},
escape=FALSE)




output$cloudcoqueryA <- renderPlot({  
  cloudplot( mydf = getalleventlist()$mydf, session, termtype='Events', intype='Drug' )
}, height=900, width=900 )
#***************Events in report
output$indtitle <- renderText({ 
  return( ( paste0('<h4>Most Common Indications In Selected Reports</h4><br>') ) )
})

output$queryindtext <- renderText({ 
  l <- getindcounts()
  paste( '<b>Query:</b>', removekey( makelink( l['myurl'] ) ), '<br>')
})

# output$indquery <- renderTable({  
#   codinds <- getindcounts()$mydf
#   checkdf(codinds, getterm1(session), names=c('Indication',  'Counts', 'Cum Sum' ))
# }, sanitize.text.function = function(x) x)

output$indquery <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  indcounts<-getindcounts()
  indqueryForExcel<<-indcounts
  if (length(indcounts) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    createAlert(session, "nodata_lrteste", "nodataAlert", title = i18n()$t("Info"),
                content = i18n()$t("No data for the specific Event"), append = FALSE)
    hide("mainrow")
    return(NULL)
  }
  res <- indcounts$mydf
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  if ( is.data.frame(res) )
  { 
    resIndatatable=res
  } else  {
    resIndatatable= data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  resIndatatable <- resIndatatable[,1:(length(resIndatatable)-1)]
  if (!is.null(input$sourceInqDataframeUI)){
    if (input$sourceInqDataframeUI){
      write.csv(resIndatatable,paste0(cacheFolder,values$urlQuery$hash,"_Einqprr.csv"))
      
    }
  }
  
  if(!is.null(values$urlQuery$hash)){
    return(   datatable(
      resIndatatable,
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
    return (    datatable(
      resIndatatable,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(className = 'dt-right', targets = c(1))),
        language = list(
          url = ifelse(selectedLang=='gr', 
                       'datatablesGreek.json',
                       'datatablesEnglish.json')
        )
      ),  escape=FALSE,rownames= FALSE)
    )
    
  }

},
escape=FALSE)

output$cloudindquery <- renderPlot({  
  cloudplot( mydf = getindcounts()$sourcedf, session, termtype='Indication', intype='Drug' )
}, height=1000, width=1000)




output$date1 <- renderText({ 
  l <- getdaterange()
  paste( '<b>Reports from', as.Date(l[1],  "%Y%m%d")  ,'to', as.Date(l[2],  "%Y%m%d"), '</b>')
})

# URL Stuff =====
geturlquery <- reactive({
  q <- parseQueryString(session$clientData$url_search)
  
  # q<-NULL
  # q$v1<-"patient.drug.openfda.generic_name"
  # q$v2<-"patient.reaction.reactionmeddrapt"
  # q$t1<-"Omeprazole"
  # q$drug<-toupper(q$t1)
  # q$t2<-"Anaemia"
  # q$v1<-"patient.drug.openfda.generic_name"
  # q$v1<-"patient.reaction.reactionmeddrapt"
  # q$t1<-"D10AD04"
  # q$t1<-"10019211"
  # q$hash <- "ksjdhfksdhfhsk"
  # q$concomitant <- TRUE
  # browser()
  updateNumericInput(session, "limit", value = q$limit)
  updateNumericInput(session, "limit2", value = q$limit)
  if( getwhich()== 'E'){
    updateSelectizeInput(session, 't1', selected= q$drug)
    updateSelectizeInput(session, 't1', selected= q$t1)
    # updateSelectizeInput(session, 'drugname', selected= q$drug)
    # updateSelectizeInput(session, 'drugname', selected= q$t1)
} else {
  updateSelectizeInput(session, 't1', selected= q$event)
  updateSelectizeInput(session, 't1', selected= q$t1)
  # updateSelectizeInput(session, 'drugname', selected= q$event)
  # updateSelectizeInput(session, 'drugname', selected= q$t1)    
}
  updateSelectizeInput(session, inputId = "v1", selected = q$drugvar)
  updateSelectizeInput(session, inputId = "v1", selected = q$v1)
  updateDateRangeInput(session, 'daterange', start = input$date1, end = input$date2)
  updateRadioButtons(session, 'useexact',
                     selected = if(length(q$useexact)==0) "exact" else q$useexact)
  updateRadioButtons(session, 'useexactD',
                     selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
  updateRadioButtons(session, 'useexactE',
                     selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
  
  con_medra <- mongo("medra", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
  event <- con_medra$find(paste0('{"code" : "',q$t1,'"}'))
  con_medra$disconnect()
  
  q$dename <- event$names[[1]][1]
  
  values$urlQuery<-q
  return(q)
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
  
  
  output$downloadReport <- downloadHandler(
    filename = function() {
      paste('my-report', sep = '.', switch(
        input$format, PDF = 'pdf', HTML = 'html', Word = 'docx'
      ))
    },
    
    content = function(file) {
      
      rmdfile <- 'report.Rmd'
      src <- normalizePath( rmdfile )
      
      # temporarily switch to the temp dir, in case you do not have write
      # permission to the current working directory
      owd <- setwd(tempdir())
      on.exit(setwd(owd))
      file.copy(src, rmdfile, overwrite = TRUE)
      
      library(rmarkdown)
      out <- render(rmdfile, switch(
        input$format,
        PDF = pdf_document(), HTML = html_document(), Word = word_document()
      ))
      file.rename(out, file)
    }
  )
  
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
  
  
  output$inforrandllr<-renderUI({
    addPopover(session=session, id="inforrandllr", title=paste(i18n()$t("Metrics"), "RR - LLR"), 
               content=i18n()$t("rr explanation"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infospecevent<-renderUI({
    addPopover(session=session, id="infospecevent", title=i18n()$t("Counts Table"),
               content=stri_enc_toutf8(i18n()$t("infospecevent")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infodrugcountsallevents<-renderUI({
    addPopover(session=session, id="infodrugcountsallevents", title=i18n()$t("Counts Table"),
               content=stri_enc_toutf8(i18n()$t("infodrugcountsallevents")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoCountsForEventsInSelectedReports<-renderUI({
    addPopover(session=session, id="infoCountsForEventsInSelectedReports", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoCountsForEventsInSelectedReports"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoRankedDrugCounts<-renderUI({
    addPopover(session=session, id="infoRankedDrugCounts", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoRankedDrugCounts"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoCountsForAllDrugs<-renderUI({
    addPopover(session=session, id="infoCountsForAllDrugs", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoCountsForAllDrugs"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoindquery2<-renderUI({
    addPopover(session=session, id="infoindquery2", title=i18n()$t("Counts Table"),
               content=i18n()$t("infoindquery2"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  output$LRTResultsbasedonTotalDrugs <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("LRT results based on total Drugs")))
    
  })
  output$SimulationResultsforDrugBasedLRT <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Simulation results for drug based LRT")))
    
  })
  output$AnalyzedDrugCountsforEventText <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Analyzed drug counts for event")))
    
  })
  output$AnalyzedDrugCountsforAllEvents <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Analyzed drug counts for all events")))
    
  })
  output$CountsForEventsInSelectedReports <- renderUI({ 
    # HTML(stri_enc_toutf8(i18n()$t("Counts for events in selected reports")))
    HTML(stri_enc_toutf8(i18n()$t("Events in scenario reports")))
    
  })
  output$DrugCountsforEvent <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Drug counts for event")))
    
  })
  output$CountsForAllDrugs <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Counts for all drugs")))
    
  })
  output$CountsForIndicationsInSelectedReports <- renderUI({ 
    # HTML(stri_enc_toutf8(i18n()$t("Counts for indications in selected reports")))
    HTML(stri_enc_toutf8(i18n()$t("Indications in scenario reports")))
    
  })
  output$LRTSignalAnalysisforaDrug <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("LRT signal analysis for a drug")))
    
  })
  output$LRTSignalAnalysisforanEvent <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("LRT signal analysis for an event")))
    
  })
  output$makeTabsetLRTResultsbasedonTotalDrugs <- renderUI({ 
    maketabset( c('prr', 'cloudprr', 'textplot'), 
                names=getTranslatedTabsetNamesWithTextPlot(),
                types=c('html', "plot", 'plot') )
    
  })
  
  
  output$sourcePRRDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourcePRRDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourcePRRDataframeUI,{
    
    if (!is.null(input$sourcePRRDataframeUI))
      if (!input$sourcePRRDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Eprres.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourcePrrInDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourcePrrInDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourcePrrInDataframeUI,{
    
    if (!is.null(input$sourcePrrInDataframeUI))
      if (!input$sourcePrrInDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Eprrindata.csv")
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
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Ecoqevdata.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourceAcDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourceAcDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourceAcDataframeUI,{
    
    if (!is.null(input$sourceAcDataframeUI))
      if (!input$sourceAcDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Ecoqadata.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourceInDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourceInDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourceInDataframeUI,{
    
    if (!is.null(input$sourceInDataframeUI))
      if (!input$sourceInDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Eallindata.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourceInqDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourceInqDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourceInqDataframeUI,{
    
    if (!is.null(input$sourceInqDataframeUI))
      if (!input$sourceInqDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Einqprr.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourceResDataframe<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourceResDataframeUI", "Save data values")
  })
  
  observeEvent(input$sourceResDataframeUI,{
    
    if (!is.null(input$sourceResDataframeUI))
      if (!input$sourceResDataframeUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Eresindata.csv")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  output$sourceLLRPlotReport<-renderUI({
    if (!is.null(values$urlQuery$hash))
      checkboxInput("sourceLLRPlotReportUI", "Save plot")
  })
  
  observeEvent(input$sourceLLRPlotReportUI,{
    
    if (!is.null(input$sourceLLRPlotReportUI))
      if (!input$sourceLLRPlotReportUI){
        fileName<-paste0(cacheFolder,values$urlQuery$hash,"_Ehistogram.png")
        if (file.exists(fileName)) {
          #Delete file if it exists
          file.remove(fileName)
        }
      }
  })
  
  
  getTranslatedTabsetNamesWithTextPlot <- function(){
    return (c( i18n()$t("Tables"),i18n()$t("Word Cloud"),i18n()$t("text Plot")))
  }
  
  i18n <- reactive({
    selected <- input$selected_language
    if (length(selected) > 0 && selected %in% translator$languages) {
      translator$set_translation_language(selected)
    }
    translator
  })
  
  
})
