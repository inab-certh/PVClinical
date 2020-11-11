require(shiny)
require(shinyBS)
library(shiny.i18n)
library(DT)
library(xlsx)
translator <- Translator$new(translation_json_path = "../sharedscripts/translation.json")
translator$set_translation_language('en')

#*****************************************************
shinyServer(function(input, output, session) {
  # observe({
  #   query <- parseQueryString(session$clientData$url_search)
  #   if (!is.null(query[['t1']])) {
  #     isolate( {
  #       query <- getQueryString()
  #       updateTextInput(session, "t1", value=( query[['t1']] ) )
  #       updateTextInput(session, "v1", value=( query[['v1']] ) )
  #     })
  #   }
  #   if (!is.null(query[['t2']])) {
  #     isolate( {
  #       query <- getQueryString()
  #       updateTextInput(session, "t2", value=( query[['t2']] ) )
  #       updateTextInput(session, "v2", value=( query[['v2']] ) )
  #     })
  #   }
  # })
  
  #Getters ===============================================================
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
  getqueryvars <- function( num = 1 ) {
   #browser()
   
   s <- getemptyapplist()
   if (getwhich() == 'D')
     {
     #Dashboard
     s['DA'] <- paste0( input$t1, '&v1=', input$v1 )
     
     #PRR for a Drug
     s['D'] <- paste0( input$t1, '&v1=', input$v1, gettimeappend() )
     
     #PRR for an Event
     s['E'] <- paste0( '', '&v1=', input$v1, gettimeappend() )
     
     #Dynamic PRR
     s['P'] <- paste0( input$t1 , '&v1=', input$v1 )
     
     #CPA
     s['Z'] <- paste0(input$t1 , '&v1=', input$v1 )
     
     #Reportview
     s['R'] <- paste0( input$t1, '&v1=', input$v1 )
     
     #labelview
     s['L'] <- paste0( input$t1, '&v1=', input$v1 )
     
     #LRTest
     s['LR'] <- paste0( input$t1, '&v1=', input$v1, gettimeappend() )
     
     #LRTestE
     s['LRE'] <- paste0( '', '&v1=', input$v1 , gettimeappend())
     
     #Enforcement report
     s['ENFFD'] <- paste0( input$t1 )
     
     s['LRDAS'] <- paste0( input$t1 )
     s['DAS'] <- paste0( input$t1 )
     
     
   } else {
     #Dashboard
     s['DA'] <- paste0( '', '&v1=', input$v1 )
     
     #PRR for a Drug
     s['D'] <- paste0( '', '&v1=', input$v1 , gettimeappend())
     
     #PRR for an Event
     s['E'] <- paste0( input$t1, '&v1=', input$v1, gettimeappend() )
     
     #Dynamic PRR
     s['P'] <- paste0( '' , '&v1=', input$v1, '&v2=', getbestvar1(), '&t2=', input$t1 )
     
     #CPA
     s['Z'] <- paste0( '' , '&v1=', input$v1, '&v2=', getbestvar1(), '&t2=', input$t1 )
     
     #Reportview
     s['R'] <- paste0( '', '&v1=', input$v1, '&v2=', getbestvar1() , '&t2=', input$t1 )
     
     #labelview
     s['L'] <- paste0( '', '&v1=', input$v1, '&v2=', getbestvar1() , '&t2=', input$t1)
     
     #LRTest
     s['LR'] <- paste0( input$t1, '&v1=', input$v1, gettimeappend() )  
     
     #LRTestE
     s['LRE'] <- paste0( '', '&v1=', input$v1, gettimeappend() )
     s['LREAS'] <- paste0( input$t1 )
     s['EAS'] <- paste0( input$t1 )
     }
   
   
   return(s)
 }
  
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
    exact <-   ( getdrugcounts()$exact)
    if (exact){
      return( getexactvar1() )
    } else {
      return( getvar1() )
    }
  }
  
  getbestterm1 <- function(quote=TRUE){
    exact <-   ( getdrugcounts()$exact)
    if (exact)
    {
      s <- getterm1( session, quote = TRUE )
      s <- gsub(' ', '%20', s, fixed=TRUE)
      return( s )
    } else {
      return( getterm1( session ) )
    }
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
    start <- input$daterange[1]
    end <- input$daterange[2]
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
  
  geturlquery <- reactive({
    q <- parseQueryString(session$clientData$url_search)
    #q<-NULL
    #q$v1<-"patient.drug.openfda.generic_name"
    # q$v2<-"patient.reaction.reactionmeddrapt"
    #q$t1<-"Omeprazole"
    # q$t2<-"Hypokalaemia"
    updateNumericInput(session, "limit", value = q$limit)
    updateNumericInput(session, "limit2", value = q$limit)
    if( getwhich()== 'D'){
      updateSelectizeInput(session, 't1', selected= q$drug)
      updateSelectizeInput(session, 't1', selected= q$t1)
      updateSelectizeInput(session, 'drugname', selected= q$drug)
      updateSelectizeInput(session, 'drugname', selected= q$t1)   
    } else {
      updateSelectizeInput(session, 't1', selected= q$event)
      updateSelectizeInput(session, 't1', selected= q$t1)
      updateSelectizeInput(session, 'drugname', selected= q$event)
      updateSelectizeInput(session, 'drugname', selected= q$t1)    
    }
    updateSelectizeInput(session, inputId = "v1", selected = q$drugvar)
    updateSelectizeInput(session, inputId = "v1", selected = q$v1)
    updateRadioButtons(session, 'useexact',
                       selected = if(length(q$useexact)==0) "exact" else q$useexact)
    updateRadioButtons(session, 'useexactD',
                       selected = if(length(q$useexactD)==0) "exact" else q$useexactD)
    updateRadioButtons(session, 'useexactE',
                       selected = if(length(q$useexactE)==0) "exact" else q$useexactE)
    updateDateRangeInput(session, 'daterange', start = q$start, end = q$end)
    updateTabsetPanel(session, 'maintabs', selected=q$curtab)
    return(q)
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
    geturlquery()
    v <- c('_exists_' , getexactvar1(), gettimevar() )
    t <- c(  getexactvar1() ,getterm1( session, quote = TRUE ), gettimerange() )
    #browser()
    mylist <-  getcounts999( session, v= v, t= t, 
                                 count=getprrvarname(), exactrad = input$useexact )
    mydfAll <- mylist$mydf
    start <- getstart( session )
    last <- min(getlimit( session ) + start - 1, nrow(  mydfAll ) )
    #If Not enough event terms to start at start, look at last limit values
    if( last < start )
    {
      start <- last - getlimit( session )
    }
    mydf <- mydfAll[ start:last,]
    return( list(mydf=mydf, mydfAll= mydfAll, myurl=mylist$myurl, excludeddf = mylist$excludeddf, exact = mylist$exact   ) )
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
  
  
  #**************************
  # Concomitant drug table
  getcocounts <- reactive({
    geturlquery()
#     if ( is.null( getterm1( session ) ) ){
#       return(data.frame( c(paste('Please enter a', getsearchtype(), 'name'), '') ) )
#     }
    
    v <- c( getbestvar1(), gettimevar() )
    t <- c(  getbestterm1(), gettimerange() )
#     mylist <- getcounts999( session, v= getexactvar1(), t= getterm1( session, quote = FALSE ), 
#                             count=getexactvar1(), exactrad = input$useexact )
    mylist <- getcounts999( session, v= v, t= t, count=getexactvar1(), exactrad = input$useexact )
    if (length(mylist)==0)
      {
      return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
      }
    myurl <- mylist$myurl
    mydf <- mylist$mydf
    mydf <- mydf[!is.na(mydf[,2]), ]
    sourcedf <- mydf
    if (length( mydf )==0)
    {
      return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
    }
    if (getwhich() =='D'){
      colname <- i18n()$t("Drug Name")
      if (input$v1 != 'patient.drug.medicinalproduct')
        {
        drugvar <- gsub( "patient.drug.","" , input$v1, fixed=TRUE)
        drugvar <- paste0( "&v1=", drugvar )
        medlinelinks <- coltohyper( sourcedf[,1], 'L', 
                                  mybaseurl = getcururl(), 
                                  display= rep('Label', nrow( sourcedf ) ), 
                                  append= drugvar )
        
        drugvar <- paste0( "&v1=", input$v1 )
        dashlinks <- coltohyper( sourcedf[, 1 ], 'DA', 
                                 mybaseurl = getcururl(), 
                                 display= rep('Dashboard', nrow( sourcedf ) ), 
                                 append= drugvar )
        # mydf <- data.frame(D=dashlinks, L=medlinelinks, mydf)
        mynames <- c(  colname, i18n()$t("Count")) 
        }
      else {
        medlinelinks <- rep(' ', nrow( sourcedf ) )
        mydf <- data.frame(L=medlinelinks, mydf)
        mynames <- c('-', colname, i18n()$t("Count")) 
      }
    } else {
      colname <- i18n()$t("Preferred Term")
      mynames <- c(colname, i18n()$t("Count")) 
      medlinelinks <- makemedlinelink(sourcedf[,1], i18n()$t("Definition"))          
      mydf <- data.frame( mydf) 
    }
    names <- c('v1','t1','v3', 't3', 'v2', 't2')
    values <- c(getbestvar1(), getbestterm1(), gettimevar(), gettimerange(), getexactvar1() ) 
    mydf[,'count'] <- numcoltohyper(mydf[ , 'count' ], mydf[ , 'term'], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,'term'] <- coltohyper(mydf[,'term'], getwhich() , mybaseurl = getcururl(), 
                           append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend()) )
  names(mydf) <- mynames
   return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
  })    
  
  #Indication table
  getindcounts <- reactive({
    geturlquery()
    if ( is.null( getterm1( session ) ) ){
      
      return(data.frame( c(paste('Please enter a', getsearchtype(), 'name'), '') ) )
    }
    v <- c( getbestvar1(), gettimevar() )
    t <- c( getbestterm1(), gettimerange() )
#     mylist <- getcounts999( session, v= getbestvar1(), t=getbestterm1(), 
#                             count= paste0( 'patient.drug.drugindication', '.exact'), exactrad = input$useexact )
    mylist <- getcounts999( session, v= v, t=t, count= paste0( 'patient.drug.drugindication', '.exact'), exactrad = input$useexact )
    mydf <- mylist$mydf
    mydf <- mydf[!is.na(mydf[,2]), ]
    sourcedf <- mydf
    myurl <- mylist$myurl
    if (length( mydf )==0)
    {
      return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
    }
    names <- c('v1','t1','v3', 't3', 'v2', 't2')
    values <- c( getbestvar1(), getbestterm1(), gettimevar(), gettimerange(), paste0( 'patient.drug.drugindication', '.exact') )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    # mydf[,1] <- makemedlinelink(sourcedf[,1], mydf[,1])
    return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
  })   
  

#Get total counts in database for each event and Total reports in database
  gettotals<- reactive({
    geturlquery()
    v <- c( '_exists_', '_exists_', gettimevar() )
    t <- c( getprrvarname(), getbestvar1(), gettimerange() )
    totalurl <- buildURL(v, t,  count='', limit=1)

    totalreports <- fda_fetch_p( session, totalurl, flag=NULL) 
    total <- totalreports$meta$results$total
    v <- c( '_exists_', '_exists_', getbestvar1(), gettimevar() )
    t <- c( getbestvar1(), getprrvarname(), getbestterm1(), gettimerange() )
    totaldrugurl <- buildURL( v, t, count='', limit=1)
    totaldrugreports <- fda_fetch_p( session, totaldrugurl, flag=paste( 'No Reports for',
                                    ifelse(getwhich()=='D', 'drug', 'event' ), getterm1( session ), '<br>' ) ) 
#     if ( length( totaldrugreports )==0 )
#       {
#       totaldrugurl <- buildURL( v= getvar1(), t=getterm1( session ), count='', limit=1)
# 
#       totaldrugreports <- fda_fetch_p( session, totaldrugurl, flag= paste( 'No Reports of Drug', getterm1( session ) ) )
#       }
    
    totaldrug <- totaldrugreports$meta$results$total
    
    adjust <- total/totaldrug
    out <- list(total=total, totaldrug=totaldrug, adjust=adjust, 
                totalurl=(totalurl), totaldrugurl=(totaldrugurl) )
  }) 

  #Calculate PRR and put in merged table
  getprr <- reactive({
    geturlquery()
    #    totals <- gettotals()
#    browser()
    comblist <- makecomb(session, getdrugcounts()$mydf, geteventtotals(), gettotals(), getsearchtype())
    comb <- comblist$comb
    if(is.null(comb)){
      return(NULL)
    }
    if (length(comb) < 1)
    {
      return(NULL)
      # tmp <- data.frame( Error=paste('No results for', input$useexact, getterm1(session), '.'),
      #                    count=0 )
      # return( list( comb=tmp, sourcedf=tmp) )
    }
    # ror <- comblist$ror
    comb$ror <- round(comb$ror, 2)
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
      iname <- i18n()$t("Definition")
      medlinelinks <- makemedlinelink(sourcedf[,2], iname)
    } else { 
      names <- c('exactD', 'exactE','v2','term2', 'v1','term1')
      values <- c('exact', input$useexact, getvar1(), gsub( '"', '', getbestterm1(), fixed=TRUE  ), input$v1 )
      exacttext <- paste0(  '&exactD=exact', '&exactE=', input$useexact )
      links <-getcpalinks(comb[ , 1], names, values, getcururl(), appendtext =  exacttext )
      comb <- data.frame(D='D', M='L' , comb, links$dynprr, links$cpa,  comb$ror, comb$nij)
      sourcedf <- comb
      colname <- i18n()$t("Drug Name")
      #browser()
      iname <- c( i18n()$t("Dashboard"), i18n()$t("Label"))
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
   
    countname <- paste( i18n()$t("Counts for"), getterm1( session ))
    names(comb) <-  c( iname, colname,countname, 
                       'Counts for All Reports','PRR', 'RRR',  'a', 'b', 'c', 'd', 'Dynamic PRR', 'Change Point Analysis', 'ROR', 'nij')
    # keptcols <-  c( iname, colname,countname, 
    #                                 'Counts for All Reports', 'PRR',  'Dynamic PRR', 'Change Point Analysis', 'ROR', 'nij')
    keptcols <-  c(  colname, countname, 
                     'PRR', 'ROR')

    #    mydf <- mydf[, c(1:4, 7,8,9)]
    return( list( comb=comb[, keptcols], sourcedf=sourcedf, countname=countname, colname=colname) )
  })
  
  geteventtotalstable <- reactive({
    geturlquery()
    mydf <- geteventtotals()
    if(is.null(mydf)){
      
      return(NULL)
    }
    sourcedf <- mydf
    names <- c('v1','t1','v3', 't3' ,'v2', 't2')
    values <- c('_exists_', getvar1( ), gettimevar(), gettimerange()  , getprrvarname() )
    mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
    mydf[,1] <- coltohyper(mydf[,1], ifelse( getwhich()=='D', 'E', 'D'), 
                           mybaseurl = getcururl(), append= paste0( "&v1=", input$v1, "&useexact=", 'exact', gettimeappend() ) )
    #print(head(mydf))
    return( list(mydf=mydf, sourcedf=sourcedf) )
  })  
  
geteventtotals <- reactive(
  {
  geturlquery()
  mydf <- getdrugcounts()$mydf
  if ( !is.data.frame(mydf) ) 
  {
    return(NULL)
    }
  realterms <- mydf[,1]
  foundtermslist <- mydf[,1]
  foundtermslist <- paste('"', foundtermslist, '"', sep='')
  foundtermslist <- gsub(' ', '%20',foundtermslist, fixed=TRUE )
  
  all <- data.frame(term=rep(URL='u', 'a', length(foundtermslist)), count=0L,  stringsAsFactors = FALSE)
  for (i in seq_along(foundtermslist))
    {
    eventvar <- gsub('.exact', '', getprrvarname(), fixed=TRUE)
#    myv <- c('_exists_', eventvar)
    myv <- c('_exists_', getprrvarname(), '_exists_', gettimevar() )
    myt <- c( getbestvar1(),  foundtermslist[[i]], getprrvarname(), gettimerange()  )
#    cururl <- buildURL(v= myv, t=myt, count= getprrvarname(), limit=1)
    cururl <- buildURL(v= myv, t=myt, limit=1, whichkey=i%%2)
    #print(cururl)
#    all_events2 <- getcounts999( session, v= myv, t=myt, count= getprrvarname(), limit=1, counter=i )      
    all_events2 <- fda_fetch_p( session, cururl, message= i )
#    Sys.sleep( .25 )
    all[i, 'URL'] <- removekey( makelink( cururl ) )
    all[i, 'term'] <- realterms[[i]]
    curcount <- all_events2$meta$results$total
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

output$prrtitle <- renderUI({ 
  geturlquery()
  return(HTML(paste('<h4>',i18n()$t("Reporting Ratios: Results sorted by PRR"),'</h4>',sep='')))
})
output$prrtitleBlank <- renderUI({ 
  geturlquery()
  return(HTML(''))
})

prr <- reactive({  
  if (getterm1( session )=="") {
    return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, Count=0, PRR=0, ROR=0))
  } else {
    prr<-getprr()
    prrForExcel<<-prr
    if(is.null(prr)){
      mydf1<-NULL
      return (NULL)
    }
    else{
      mydf1<-prr$comb
    }
    tableout(mydf = mydf1,  
             mynames = NULL,
             error = paste('No records for', getterm1( session ))
    )
  }
} )
output$prr <- renderTable({  
 prr()
},  sanitize.text.function = function(x) x)


# output$dataTableOutput_p_withpopover_prr2 <- renderUI
# {
#   browser()
#   s <- getpopstrings( 'prr2', NULL, NULL)
#   pophead <- s['pophead']
#   poptext <- s['poptext']
#   addPopover(session=session, id="prr2", title="Application Info", 
#              content='paok', placement = "left",
#              trigger = "hover", options = list(html = "true"))
#   if( !is.null(pophead) )
#   {
#     
#     popify(
#       dataTableOutput('prr2'),
#       HTML( pophead ), HTML(poptext),
#       placement='top')
#   }
#   else
#   {
#     dataTableOutput('prr2')
#   }
# }
output$prr2 <- DT::renderDT({  
  
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  translator$set_translation_language(selectedLang)
  mydf<-prr()
  prr2ForExcel<<-mydf
  #comblista <- makecomb(session, getdrugcounts(), geteventtotals(), gettotals(), getsearchtype())
  #print(comblista)
  if (!is.null(mydf) )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    if(getsearchtype() == 'Drug') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug"), append = FALSE)
    } else if(getsearchtype() == 'Reaction') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Event"), append = FALSE)
    } else {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    }
    hide("maintabs")
    hide("daterange")
    hide("downloadExcelColumn")
    hide("dlprr2")
    return(NULL)
  }
  datatable(
    mydf,
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2,3))),
      language = list(
        url = ifelse(selectedLang=='gr', 
                     'datatablesGreek.json', 
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
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

output$downloadDataLbl1 <- output$downloadDataLbl2 <- output$downloadDataLbl3 <-
  output$downloadDataLbl4 <- output$downloadDataLbl5 <- output$downloadDataLbl6 <-
  renderText({
  return(i18n()$t("Download Data in Excel format"))
})

output$downloadBtnLbl1 <- output$downloadBtnLbl2 <- output$downloadBtnLbl3 <-
  output$downloadBtnLbl4 <- output$downloadBtnLbl5 <- output$downloadBtnLbl6 <-
  renderText({
  return(i18n()$t("Download"))
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

output$querytitle <- renderUI({ 
  return( html(paste('<h4>',i18n()$t("Counts for"), getterm1( session ), '</h4><br>') ))
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

output$specifieddrug2 <- DT::renderDT({
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  translator$set_translation_language(selectedLang)
  mydf1 = getdrugcountstable()$mydf
  specifieddrug2ForExcel<<-mydf1
  if (length(mydf1) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    if(getsearchtype() == 'Drug') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug"), append = FALSE)
    } else if(getsearchtype() == 'Reaction') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Event"), append = FALSE)
    } else {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    }
    hide("maintabs")
    hide("daterange")
    hide("downloadExcelColumn")
    hide("dlprr2")
    return(NULL)
  }
  datatable(
    tableout(mydf = mydf1,  
             mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for"), getterm1( session ) ) ),
             error = paste( 'No results for', getterm1( session ) )),
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr',
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
},  escape=FALSE)

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
  return(paste('<h4>',i18n()$t("Counts for Entire Database"),'</h4><br>',sep='') )
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
           mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for All Reports")), i18n()$t("Query") ),
           error = paste( 'No events for', getsearchtype(), getterm1( session ) ) 
  )
})
output$all <- renderTable({  
  tableout(mydf = geteventtotalstable()$mydf, 
           mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for All Reports")), i18n()$t("Query") ),
           error = paste( 'No events for', getsearchtype(), getterm1( session ) ) 
  )
}, sanitize.text.function = function(x) x)

output$all2 <- DT::renderDT({
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  translator$set_translation_language(selectedLang)
  eventTotals<-geteventtotalstable()
  
  if (length(eventTotals) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    if(getsearchtype() == 'Drug') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug"), append = FALSE)
    } else if(getsearchtype() == 'Reaction') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Event"), append = FALSE)
    } else {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    }
    hide("maintabs")
    hide("daterange")
    hide("downloadExcelColumn")
    hide("dlprr2")
    return(NULL)
  }
  mydf1<-eventTotals$mydf[,c(1,2)]
  all2ForExcel<<-mydf1
  datatable(
    tableout(mydf = mydf1,  
             mynames = c(i18n()$t("Term"), paste( i18n()$t("Counts for All Reports"))),
             error = paste( 'No events for', getsearchtype(), getterm1( session ) ) ),
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr',
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
},  escape=FALSE)


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



output$coqueryE2 <- DT::renderDT({
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  translator$set_translation_language(selectedLang)
  mydf<-coqueryE()
  coqueryE2ForExcel<<-mydf
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    if(getsearchtype() == 'Drug') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug"), append = FALSE)
    } else if(getsearchtype() == 'Reaction') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Event"), append = FALSE)
    } else {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    }
    hide("maintabs")
    hide("daterange")
    hide("downloadExcelColumn")
    hide("dlprr2")
    return(NULL)
  }
  datatable(
    mydf,
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr',
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
},  escape=FALSE)

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


output$coquery2 <- DT::renderDT({
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  translator$set_translation_language(selectedLang)
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  mydf<-coquery2()
  if (length(mydf) > 0 )
  {
    if(!is.null(session$nodataAlert))
    {
      closeAlert(session, "nodataAlert")
    }
  }
  else{
    if(getsearchtype() == 'Drug') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug"), append = FALSE)
    } else if(getsearchtype() == 'Reaction') {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Event"), append = FALSE)
    } else {
      createAlert(session, "nodata_rrd", "nodataAlert", title = i18n()$t("Info"),
                  content = i18n()$t("No data for the specific Drug-Event combination"), append = FALSE)
    }
    hide("maintabs")
    hide("daterange")
    hide("downloadExcelColumn")
    hide("dlprr2")
    return(NULL)
  }
  datatable(
    mydf,
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr',
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
  
},  escape=FALSE)

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



output$dlprr2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(prr2ForExcel, file, sheetName="prr")
  }
)
output$dlspecifieddrug2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(specifieddrug2ForExcel, file, sheetName="Simulation Results for Event Based LRT")
  }
)
output$dlall2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(all2ForExcel, file, sheetName="All")
  }
)
output$dlcoqueryE2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coqueryE2ForExcel, file, sheetName="coquery")
  }
)
output$dlcoquery2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(coquery2ForExcel, file, sheetName="coqueryE")
  }
)
output$dlindquery2 <- downloadHandler(
  filename = function() { "Data.xlsx"},
  content = function(file) {
    write.xlsx(indquery2ForExcel, file, sheetName="indquery")
  }
) 

output$indquery <- renderTable({ 
  tableout(mydf = getindcounts()$mydf, mynames = c(i18n()$t("Indication"),  i18n()$t("Counts") ),
           error = paste( 'No results for', getterm1( session ) ) )
}, sanitize.text.function = function(x) x)

output$indquery2 <- DT::renderDT({
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  mydf1<-getindcounts()$mydf
  indquery2ForExcel<<-mydf1
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  translator$set_translation_language(selectedLang)
  datatable(
    tableout(mydf = mydf1, mynames = c(i18n()$t("Indication"),  i18n()$t("Counts") ),
             error = paste( 'No results for', getterm1( session ) ) ),
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr',
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
},  escape=FALSE)




output$coqueryEex <- renderTable({  
  tableout(mydf = getdrugcounts()$excludeddf,  
#           mynames = c( "Terms that contain '^' or ' ' ' can't be analyzed and are excluded", 'count' ),
           error = paste( 'No Events for', getterm1( session ) )
  )
}, sanitize.text.function = function(x) x)


output$coqueryEex2 <- DT::renderDT({
  datatable(
    tableout(mydf = getdrugcounts()$excludeddf,  
             #           mynames = c( "Terms that contain '^' or ' ' ' can't be analyzed and are excluded", 'count' ),
             error = paste( 'No Events for', getterm1( session ) )
    ),
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2,3))),
      language = list(
        url = ifelse(input$selected_language=='gr',
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE
  )
},  escape=FALSE)

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


  output$urlquery <- renderText({ 
    return( getcururl()  )
  })
  
  output$applinks <- renderText({ 
    s <- makeapplinks(  getcururl(), getqueryvars( 1 ) ) 
#    write(s, file='')
    return( makeapplinks(  getcururl(), getqueryvars( 1 ) )  )
  })
  i18n <- reactive({
    selected <- input$selected_language
    if (length(selected) > 0 && selected %in% translator$languages) {
      translator$set_translation_language(selected)
    }
    translator
  })
  output$UseReportsBetween <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("UseReportsBetween")))
    
  })
  output$PRRRORResults <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("PRR and ROR Results")))
    
  })
  
  
  
  output$AnalyzedEventCountsforSpecifiedDrug <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Analyzed Event Counts for Specified Drug")))
    
  })
  
  output$AnalyzedDrugCountsforSpecifiedEvent <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Analyzed Drug Counts for Specified Event")))
    
  })
  output$AnalyzedEventCountsforAllDrugs <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Analyzed Event Counts for All Drugs")))
    
  })
  output$AnalyzedDrugCountsforAllEvents <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Analyzed Drug Counts for All Events")))
    
  })
  output$RankedEventCountsforDrug <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Ranked Event Counts for Drug")))
    
  })
  output$RankedDrugCountsforEvent <- renderUI({ 
    HTML(stri_enc_toutf8(i18n()$t("Ranked Drug Counts for Event")))
    
  })
  output$CountsForDrugsInSelectedReports <- renderUI({ 
    # HTML(stri_enc_toutf8(i18n()$t("Counts for drugs in selected reports")))
    HTML(stri_enc_toutf8(i18n()$t("Drugs in scenario reports")))
    
  })
  output$CountsForEventsInSelectedReports <- renderUI({ 
    # HTML(stri_enc_toutf8(i18n()$t("Counts for events in selected reports")))
    HTML(stri_enc_toutf8(i18n()$t("Events in scenario reports")))
    
  })
  output$CountsForIndicationsInSelectedReports <- renderUI({ 
    # HTML(stri_enc_toutf8(i18n()$t("Counts for indications in selected reports")))
    HTML(stri_enc_toutf8(i18n()$t("Indications in scenario reports")))
    
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
  getTranslatedTabsetNamesWithTextPlot <- function(){
    return (c( i18n()$t("Tables"),i18n()$t("Word Cloud"),i18n()$t("text Plot")))
  }
  output$maketabsetPRRRORResults <- renderUI({ 
    maketabset( c('prr2', 'cloudprr', 'textplot'), 
                types=c('datatable', "plot", 'plot'),
                names=getTranslatedTabsetNamesWithTextPlot(), 
                popheads = c(tt('prr1'), tt('word1'), tt('textplot1') ), 
                poptext = c( tt('prr5'), tt('wordPRR'), tt('textplot2') ) )
    
  })
  output$infoprr2<-renderUI({
    addPopover(session=session, id="infoprr2", title=paste(i18n()$t("Metrics"), "PRR - ROR"), 
               content=paste(i18n()$t("prr explanation"),"<br><br><br>",i18n()$t("ror explanation")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  
  output$infospecifieddrug2<-renderUI({
    addPopover(session=session, id="infospecifieddrug2", title="Frequency Table", 
               content=stri_enc_toutf8(i18n()$t("rr_explanation")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infospecdrug<-renderUI({
    addPopover(session=session, id="infospecdrug", title=i18n()$t("Counts Table"),
               content=stri_enc_toutf8(i18n()$t("infospecdrug")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infospecevent<-renderUI({
    addPopover(session=session, id="infospecevent", title=i18n()$t("Counts Table"),
               content=stri_enc_toutf8(i18n()$t("infospecevent")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoall2<-renderUI({
    addPopover(session=session, id="infoall2", title="Frequency Table", 
               content=stri_enc_toutf8(i18n()$t("rr explanation")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoeventcountsalldrugs<-renderUI({
    addPopover(session=session, id="infoeventcountsalldrugs", title=i18n()$t("Counts Table"),
               content=stri_enc_toutf8(i18n()$t("infoeventcountsalldrugs")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infodrugcountsallevents<-renderUI({
    addPopover(session=session, id="infodrugcountsallevents", title=i18n()$t("Counts Table"),
               content=stri_enc_toutf8(i18n()$t("infodrugcountsallevents")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infocoqueryE2<-renderUI({
    addPopover(session=session, id="infocoqueryE2", title="Concomitant Medications", 
               content=paste(i18n()$t("rr explanation"),"<br><br>",i18n()$t("Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations. \"L\" is linked to SPL labels for Drug in openFDA. \"D\" is linked to a dashboard display for a drug.")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoRankedDrugCounts<-renderUI({
    addPopover(session=session, id="infoRankedDrugCounts", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoRankedDrugCounts"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoRankedEventCounts<-renderUI({
    addPopover(session=session, id="infoRankedEventCounts", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoRankedEventCounts"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infocoquery2<-renderUI({
    addPopover(session=session, id="infocoquery2", title="Concomitant Medications", 
               content=paste(i18n()$t("rr explanation"),"<br><br>",i18n()$t("Frequency table for drugs found in selected reports. Drug name is linked to LRT results for drug \"L\" is linked to SPL labels for drug in openFDA. \"D\" is linked to a dashboard display for the drug.")), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoCountsForDrugsInSelectedReports<-renderUI({
    addPopover(session=session, id="infoCountsForDrugsInSelectedReports", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoCountsForDrugsInSelectedReports"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoCountsForEventsInSelectedReports<-renderUI({
    addPopover(session=session, id="infoCountsForEventsInSelectedReports", title=i18n()$t("Counts Table"), 
               content=i18n()$t("infoCountsForEventsInSelectedReports"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  output$infoindquery2<-renderUI({
    addPopover(session=session, id="infoindquery2", title=i18n()$t("Counts Table"),
               content=i18n()$t("infoindquery2"), placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  })
  
  
  
  
   
})
