require(shiny)
require(shinyBS)
require('lubridate')
require('bcp')
require('changepoint')
require('zoo')
library(shiny.i18n)
library(DT)
library(tableHTML)
library("ggplot2")

library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)

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
    #browser()
    # if (!is.null(query[['lang']])) {
    #   updateSelectInput(session, "selected_language",
    #                     i18n()$t("Change language"),
    #                     choices = c("en","gr"),
    #                     selected = selectedLang
    #   )
    # }
    
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
  geturlquery()
  toggleModal(session, 'updatemodal', 'close')
  v1 <- getbestdrugvar()
  t1 <- c(getbestterm1() ) 
  myurl <- buildURL(v1, t1, count='', limit=5 )
  mydf <- fda_fetch_p( session, myurl, wait = getwaittime())
  # print(mydf)
  mydf <- list(result=mydf$result, url=myurl, meta=mydf$meta)
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
  start <- input$daterange[1]
  end <- input$daterange[2]
  return( c(start, end))
}

getqueryde <- reactive({
  geturlquery()
  v <- c( getbestdrugvar(), getbestaevar() , gettimevar() )
  t <- c( getbestterm1(), getbestterm2(), gettimerange() )  
  myurl <- buildURL(v, t, count=gettimevar() )
  out <- fda_fetch_p( session, myurl, wait = getwaittime(), reps=5 )
  return( list(out=out, myurl=myurl ) )
})

getquerydata <- reactive({
  mydf <- getqueryde()
  tmp <- mydf$out$result    
  createAlert(session, 'alert', 'calcalert',
              title='Calculating...', 
              content = 'Calculating Time Series...', 
              dismiss = FALSE)
  mydfin <- gettstable( tmp )
  if(!is.null(session$calcalert))
  {
    closeAlert(session,  'calcalert')
  }
  return( list( mydfin= mydfin, mydf=mydf, myurl= mydf$myurl, mysum = mydfin$total ) )
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
  query <- parseQueryString(session$clientData$url_search)
  selectedLang = tail(query[['lang']], 1)
  if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  {
    selectedLang='en'
  }
  datatable(
    if ( is.data.frame(codrugs) )
    { 
      return(codrugs) 
    } else  {
      return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )},
    options = list(
      autoWidth = TRUE,
      columnDefs = list(list(width = '50', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr', 
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ))
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


output$coquery <- DT::renderDT({
  codrugs <- getcocountsE()$mydf
  datatable(
    if ( is.data.frame(codrugs) )
    { 
      return(codrugs) 
    } else  {
      return( data.frame(Term=paste( 'No Events for', getterm1( session) ) ) )})
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
output$queryplot <- renderDygraph({  
  fetchalldata()
  #   if (input$term1=='') {return(data.frame(Drug='Please enter drug name', Count=0))}
  mydf <- getquerydata()$mydfin
  Dates2<-lapply(mydf$display['Date'], function(x) {
    # x <- as.Date(paste(x,'-01',sep = ''), "%Y-%m-%d")
    x <- paste(x,'-01',sep = '')
    x
  })
  Dates2<-unlist(Dates2, use.names=FALSE)
  if ( is.data.frame(mydf$display) )
  {
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
    
    data <- read.table("https://python-graph-gallery.com/wp-content/uploads/bike.csv", header=T, sep=",") %>% head(300)
    
    # Check type of variable
    # str(data)
    
    # Since my time is currently a factor, I have to convert it to a date-time format!
    #data$datetime <- ymd_hms(data$datetime)
    browser()
    datetime <- ymd(Dates2)
    
    # Then you can create the xts necessary to use dygraph
    don <- xts(x = Counts, order.by = datetime)
    
    # Finally the plot
    p <- dygraph(don) %>%
      dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="grey") %>%
      # dySeries("V1", drawPoints = TRUE, pointShape = "square", color = "blue")
      dyRangeSelector() %>%
      dyCrosshair(direction = "vertical") %>%
      dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
      dyRoller(rollPeriod = 1)
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
  browser
  if ( is.data.frame(codrugs) )
  { 
    # names(codrugs) <- c(  stri_enc_toutf8(i18n()$t("Preferred Term")), stri_enc_toutf8(i18n()$t("Case Counts for")), paste('%', stri_enc_toutf8(i18n()$t("Count") )))
    # names(codrugs) <- c(  stri_enc_toutf8('??????'),stri_enc_toutf8('??????'),stri_enc_toutf8('????????'))
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
             content=out, placement = "left",
             trigger = "hover", options = list(html = "true"))
    #attr(session, "cpmeanplottext") <- out
    # browser()
    # l <- append( l, c('cpmeanplottext' =  out ) )
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
  
})

output$cpmeanplot <- renderPlot ({
  
  mydf <-getquerydata()$mydfin$result
  if (length(mydf) > 0)
    {
    s <- calccpmean()
    labs <-    index( getts() )
    pos <- seq(1, length(labs), 3)
    
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
    plot(s, xaxt = 'n', ylab=i18n()$t("Count"), xlab='', main=mytitle)
    axis(1, pos,  labs[pos], las=2  )
    grid(nx=NA, ny=NULL)
    abline(v=pos, col = "lightgray", lty = "dotted",
           lwd = par("lwd") )
    }
})

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
               content=out, placement = "left",
               trigger = "hover", options = list(html = "true"))
    return(HTML('<button type="button" class="btn btn-info">i</button>'))
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
    browser()
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
    outb<-paste(outb,"<br><br>",i18n()$t("Bayesian change point explanation")," ")
    
    
    
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
output$cpbayesplot <- renderPlot ({
  mydf <-getquerydata()$mydfin$result
  if (length(mydf) > 0)
    {
    browser()
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
  updateDateRangeInput(session,'daterange',  start = q$start, end = q$end)
  updateNumericInput(session,'maxcp', value=q$maxcps)
  updateNumericInput(session,'maxcp2', value=q$maxcps)
  updateRadioButtons(session, 'useexactD', selected = q$exactD)
  updateRadioButtons(session, 'useexactE', selected = q$exactE)
  return(q)
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
  HTML(stri_enc_toutf8(i18n()$t("Counts for drugs in selected reports")))
  
})
output$CountsForEventsInSelectedReports <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Counts for events in selected reports")))
  
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




i18n <- reactive({
  selected <- input$selected_language
  if (length(selected) > 0 && selected %in% translator$languages) {
    translator$set_translation_language(selected)
  }
  translator
})




})