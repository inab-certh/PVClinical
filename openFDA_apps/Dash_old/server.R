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

# wait <- function(x) {
#   Sys.sleep(x)
# }

#*****************************************************
shinyServer(function(input, output, session) {
  
#  print(session$clientData$url_hostname)
#   mywait <- .0
#   
#   getwaittime <- reactive({ 
#     if(session$clientData$url_hostname == '10.12.207.87')
#     {
#       return( 0.0)
#     } else if(session$clientData$url_hostname == '127.0.0.1') {
#       return (0.5)
#     }
#     return(0.0)
#   })
  
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
  # output$daterange <- renderUI({
  #   query <- parseQueryString(session$clientData$url_search)
  #   selectedLang = tail(query[['lang']], 1)
  #   if(is.null(selectedLang) || (selectedLang!='en' && selectedLang!='gr'))
  #   {
  #     selectedLang='en'
  #   }
  #   
  #   langs = list(gr="el", en="en")
  #   dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language = langs[[selectedLang]])
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
    
  })
  
  getqueryvars <- function( num = 1 ) {
    s <- vector(mode = "character", length = 7)
      #Dashboard
      s[1] <- paste0( input$t1, '&v1=', input$v1 )
      
      #PRR for a Drug
      s[2] <- paste0( input$t1, '&v1=', input$v1 )
      
      #PRR for an Event
      s[3] <- paste0( '', '&v1=', input$v1 )
      
      #Dynamic PRR
      s[4] <- paste0( input$t1 , '&v1=', input$v1 )
      
      #CPA
      s[5] <- paste0( input$t1 , '&v1=', input$v1 )
      
      #Reportview
      s[6] <- paste0( input$t1, '&v1=', input$v1 )
      
      #labelview
      s[7] <- paste0( input$t1, '&v1=', input$v1 )
      
      #LRTest
      s[8] <- paste0( input$t1, '&v1=', input$v1 )
      return(s)
  }
  getdrugname <- reactive({ 
#    print(input$usepopcb)
    s <- toupper(input$t1)
    if  (is.null(s) | s=="" ) {
      return("")
    }
    names <- s
    names <- paste0(names, collapse=' ')
    return(names)
  })
  
  gett1v1 <- reactive({ 
    return( c(t1=input$term1, v1=input$var1) )
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
    return(input$v1)
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
  
  getbestdrugname <- function(quote=TRUE){
    exact <-   ( getdrugcounts999()$exact)
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
  
  anychanged <- reactive({
    a <- input$t1
    b <- input$v1
    c <- input$useexact
    if(!is.null(session$erroralert))
    {
      closeAlert(session, 'erroralert')
    }
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
    geturlquery()
    mydf <- data.frame(Serious=0, Count=0)
    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(), 
                      count='seriousnesscongenitalanomali' )
    conganom <-  fda_fetch_p(session, myurl)$result
    if (length(conganom)==0)
      {
      conganom <- c(1,0)
      }
    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                      count='seriousnessdeath' )
    death <-  fda_fetch_p( session, myurl)$result
    if (length(death)==0)
      {
      death <-  c(1,0)
      }
    
    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                      count='seriousnessdisabling' )
    disable <- fda_fetch_p( session, myurl)$result
    
    if (length(disable)==0)
    {
      disable <- c(1,0)
    }
    
    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                      count='seriousnesshospitalization' )
    hosp <- fda_fetch_p( session, myurl)$result
    
    if (length(hosp)==0)
    {
      hosp <- c(1,0)
    }
    
    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                      count='seriousnesslifethreatening' )
    lifethreat <- fda_fetch_p( session, myurl)$result
    
    if (length(lifethreat)==0)
    {
      lifethreat  <- c(1,0)
    }

    myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                      count='seriousnessother' )
    other <- fda_fetch_p( session, myurl)$result
    
    
    if (length(other)==0)
    {
      other <- c(1,0)
    }
    
    mydf <- rbind(conganom, death, disable, hosp, lifethreat, other)
   mydf[,'term'] <- c(i18n()$t("Congenital Anomaly"), i18n()$t("Death"), i18n()$t("Disability"), i18n()$t("Hospitalization"),
                      i18n()$t("Life Threatening"), i18n()$t("Other"))
    
    mydf <- mydf[order(mydf[,2]), ]
    return( mydf )
  })    
  
#************************************
# Get Sex Query
#*********************

getsexcounts <- reactive({
  
  
  geturlquery()
  
  myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                    count="patient.patientsex" )
  mydf <- fda_fetch_p( session, myurl)$result
  mydf[,3] <- mydf[,1]
  mydf[ mydf[,1]==2 , 1] <- i18n()$t("Female") 
  mydf[ mydf[,1]==1 , 1] <- i18n()$t("Male")
  mydf[ mydf[,1]==0 , 1] <- i18n()$t("Unknown") 
  mydf <- mydf[order(mydf[,2]), ]
  
  return( mydf )
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
  
  geturlquery()
  myurl <- buildURL(v= getbestdrugvarname(), t=getbestdrugname(),
                    count="primarysource.qualification" )
  mydf <- fda_fetch_p( session, myurl)$result
  if(is.null(mydf)){
    return(NULL)
  }
  mydf[,3] <- mydf[,1]
  mydf[ mydf[,1]==1 , 1] <- i18n()$t("Physician") 
  mydf[ mydf[,1]==2 , 1] <- i18n()$t("Pharmacist") 
  mydf[ mydf[,1]==3 , 1] <- i18n()$t("Other Health Professional") 
  mydf[ mydf[,1]==4 , 1] <- i18n()$t("Lawyer")
  mydf[ mydf[,1]==5 , 1] <- i18n()$t("Consumer or non-health...") 
  mydf <- mydf[order(mydf[,2]), ]
  
  return( mydf )
})    

  #************************************
  # Get Drug-Event Query
  #*********************
  
  getdrugcounts999 <- reactive({
    
    geturlquery()
    mylist <- getcounts999 ( session, v= getexactdrugvarname(), t= getterm1( session, quote = FALSE ), 
                             count=geteventvarname(), limit=999, exactrad=input$useexact, counter=1 )
    return( list(mydf=mylist$mydf, myurl=(mylist$myurl), exact = mylist$exact  ) )
  })    
  
  # Only use the first value of limit rows
  getdrugcounts <- reactive({
    mylist <-  getdrugcounts999()
    mydf <-  mylist$mydf
    totdf <- gettotals()
    percents <- 100*mydf[,2]/totdf$totaldrug
    mydf <- data.frame( mydf[], percents)
    return( list(mydf=mydf, myurl=mylist$myurl  ) )
  })  
  
  
  #Build table containing drug-event pairs
  getdrugcountstable <- reactive({
    geturlquery()
    mydf <- getdrugcounts()
    myurl <- mydf$myurl
    
    mydf <- mydf$mydf
    sourcedf <- mydf
    
    # mydf <- data.frame( rep('M', nrow(mydf) ), mydf )
    # mydf[,1] <- makemedlinelink(mydf[,2], mydf[,1])
    names <- c('v1','t1' ,'v2', 't2')
    values <- c(getbestdrugvarname(), getbestdrugname(), geteventvarname() )
    
    if(is.data.frame(mydf) && nrow(mydf)!=0) {
      mydf[,3] <- numcoltohyper(mydf[ , 3], sourcedf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
      mydf[,2] <- coltohyper(mydf[,2], 'E', mybaseurl = getcururl(),
                             append= paste0( "&v1=", input$v1) ) 
      
    }
    
    # else  {
    #   return(list(mydf=))
    # }
    return( list(mydf=mydf, myurl=(myurl),  sourcedf=sourcedf  ) )
  })  
  
#**************************
# Concomitant drug table
getcocounts <- reactive({
  geturlquery()
  if ( is.null( getdrugname() ) ){
    return(data.frame( c(paste('Please enter a drug name'), '') ) )
  }
  myurl <- buildURL( v= getbestdrugvarname(), t=getbestdrugname(), 
                     count= getexactdrugvarname(), limit=999 )
  mydf <- fda_fetch_p( session, myurl)
  mydf <- mydf$result
  myrows <- min(nrow(mydf), 999)
  mydf <- mydf[1:myrows,]
#   print(myrows)
#   print(mydf)
  sourcedf<- mydf
  mydf <- data.frame( rep('L', myrows) , mydf )
  mydf <- mydf[!is.na(mydf[,3]), ]

  if (input$v1 != 'patient.drug.medicinalproduct')
    {
      drugvar <- gsub( "patient.drug.","" ,input$v1, fixed=TRUE)
      drugvar <- paste0( "&v1=",URLencode(drugvar, reserved = TRUE )   )
      medlinelinks <- coltohyper( sourcedf[,1], 'L', 
                                  mybaseurl = getcururl(), 
                                  display= rep('L', nrow( sourcedf ) ), 
                                  append= drugvar )
      mydf[,1] <- medlinelinks
    }
  names <- c('v1','t1', 'v2', 't2')
  values <- c(getbestdrugvarname(), getbestdrugname(), getexactdrugvarname() ) 
  mydf[,3] <- numcoltohyper(mydf[ , 3], mydf[ , 2], names, values, mybaseurl = getcururl(), addquotes=TRUE )
  mydf[,2] <- coltohyper(mydf[,2], 'D', mybaseurl = getcururl(), 
                         append= paste0( "&v1=", input$v1) )
  return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
})     

#Indication table
getindcounts <- reactive({
  geturlquery()
  if ( is.null( getdrugname() ) ){
    return(data.frame( c(paste('Please enter a', getsearchtype(), 'name'), '') ) )
  }
  myurl <- buildURL( v= getbestdrugvarname(), t=getbestdrugname(), 
                     count= paste0( 'patient.drug.drugindication', '.exact'), limit=999)
  mydf <- fda_fetch_p( session, myurl)
  mydf <- mydf$result
  myrows <- min(nrow(mydf), 999)
  mydf <- mydf[1:myrows,]
  mydf <- mydf[!is.na(mydf[,2]), ]
  sourcedf <- mydf
  medlinelinks <- makemedlinelink(sourcedf[,1], 'M')
  names <- c('v1','t1', 'v2', 't2')
  values <- c( getbestdrugvarname(), getbestdrugname(), paste0( 'patient.drug.drugindication', '.exact') )
  # mydf[,2] <- numcoltohyper(mydf[ , 2], mydf[ , 1], names, values, mybaseurl = getcururl(), addquotes=TRUE )
  # mydf[,1] <- makemedlinelink(sourcedf[,1], mydf[,1])
  
  return( list( mydf=mydf, myurl=(myurl), sourcedf=sourcedf ) )
})   

#  
  #Get total counts in database for each event and Total reports in database
  gettotals<- reactive({
    geturlquery()
    
    
    v <- c( '_exists_', '_exists_' )
    t <- c( geteventvarname(), getexactdrugvarname() )
    totalurl <- buildURL(v, t,  count='', limit=1)
    totalreports <- fda_fetch_p( session, totalurl)    
    total <- totalreports$meta$results$total
    v <- c( '_exists_', getbestdrugvarname() )
    t <- c( geteventvarname(), getbestdrugname() )
    totaldrugurl <- buildURL( v, t, count='', limit=1)
    totaldrugreports <- fda_fetch_p( session, totaldrugurl)    
    if ( length( totaldrugreports )==0 )
    {
      totaldrugurl <- buildURL( v= getdrugvarname(), t=getdrugname(), count='', limit=1)
      totaldrugreports <- fda_fetch_p( session, totaldrugurl)
    }
    
    totaldrug <- totaldrugreports$meta$results$total
    
    adjust <- total/totaldrug
    out <- list(total=total, totaldrug=totaldrug, adjust=adjust, 
                totalurl=(totalurl), totaldrugurl=(totaldrugurl) )
  }) 
  
  output$downloadDataLbl <- renderText({
    return(i18n()$t("Download Data in Excel format"))
  })
  
  output$downloadBtnLbl <- renderText({
    return(i18n()$t("Download"))
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
  
  fig
}
else{
  # s1 <- calccpmean()
  geturlquery()
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


# output$query <- renderTable({
#   mydf <- getdrugcountstable()$mydf
#   if ( is.data.frame(mydf) )
#   {
#     names(mydf) <- c(  stri_enc_toutf8(i18n()$t("Preferred Term")), paste( stri_enc_toutf8(i18n()$t("Case Counts for")), getdrugname()), paste('%', stri_enc_toutf8(i18n()$t("Count") )))
#     return(mydf)
#   } else  {return(data.frame(Term=paste( 'No results for', getdrugname() ), Count=0))}
# },  sanitize.text.function = function(x) x)
# 

output$query <- DT::renderDT({
  grlang<-'datatablesGreek.json'
  enlang<-'datatablesEnglish.json'
  mydf <- getdrugcountstable()$mydf
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
  # else  {
  #   mydfIndatatable<- data.frame(Term=paste( 'No Events for', getterm1( session) ) ) }
  # datatable(
  #   mydfIndatatable,
  #   options = list(
  #     autoWidth = TRUE,
  #     columnDefs = list(list(className = 'dt-right', targets = c(1,2))),
  #     language = list(
  #       url = ifelse(selectedLang=='gr',
  #                    grlang,
  #                    enlang)
  #     )
  #   )
  #   ,  escape=FALSE,rownames= FALSE)},  escape=FALSE)

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

# output$coquery <- renderTable({  
#   codrugs <- getcocounts()$mydf
#   if ( is.data.frame(codrugs) )
#   { 
#     names(codrugs) <- c('L', i18n()$t("Drug"),  i18n()$t("Counts") )
#     return(codrugs) 
#   } else  {
#     return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
#   }  
#   
# }, sanitize.text.function = function(x) x)


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
      columnDefs = list(list(className = 'dt-right', targets = c(1, 2))),
      language = list(
        url = ifelse(selectedLang=='gr', 
                     'datatablesGreek.json',
                     'datatablesEnglish.json')
      )
    ),  escape=FALSE,rownames= FALSE)
},  escape=FALSE)


#addTooltip(session, 'cocloud', tt('cocloud'), placement='top')
output$cocloud <- renderPlot({  
  codrugs <- getcocounts()$sourcedf
  if ( is.data.frame(codrugs) )
  { 
    names(codrugs) <- c(i18n()$t("Drug"),  i18n()$t("Counts") )
    mytitle <- paste('Medications in Reports That Contain', getdrugname() )
    return( getcloud(codrugs, title=mytitle ) ) 
  } else  {
    return( data.frame(Term=paste( 'No events for', getdrugname() ) ) )
  }  
  
}, height=900, width=900)

# output$indquery <- renderTable({  
#   # if ( getdrugname() =='') {return(data.frame(Term=paste('Please enter a', getsearchtype(), 'name'), Count=0, URL=''))}
#   codinds <- getindcounts()$mydf
#   if ( is.data.frame(codinds) )
#   { 
#     names(codinds) <- c(i18n()$t("Indication"),  i18n()$t("Counts") )
#     return(codinds) 
#   } else  {
#     return( data.frame(Term=paste( 'No', getsearchtype(), 'for', getdrugname() ) ) )
#   }  
#   
# }, sanitize.text.function = function(x) x)

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

# output$usepop <- renderUI({
#   p( input$usepopcb )
# })

geturlquery <- reactive({
  q <- parseQueryString(session$clientData$url_search)
#  browser()
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
output$productsummary <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Product Summary")))
  
})
output$table <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Table")))
  
})
output$dotchart <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Dotchart")))
  
})
output$piechart <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Piechart")))
  
})
output$table2 <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Table")))
  
})
output$dotchart2 <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Dotchart")))
  
})
output$piechart2 <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Piechart")))
  
})
output$table3 <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Table")))
  
})
output$dotchart3 <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Dotchart")))
  
})
output$piechart3 <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Piechart")))
  
})
output$AdverseEventsConcomitantMedications <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Adverse Events and Concomitant Medications")))
  
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
output$OtherApps <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Other Apps")))
  
})
output$DataReference <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("Data Reference")))
  
})
output$About <- renderUI({ 
  HTML(stri_enc_toutf8(i18n()$t("About")))
  
})
getTranslatedNames <- function(){
  return (c( i18n()$t("Tables"),i18n()$t("Word Cloud")))
}
output$wordcloudtabset <- renderUI({
  wordcloudtabset('eventcloud', 'query', 
                  popheads=c( tt('event1'), tt('word1') ), poptext=c( tt('event2'), tt('word2') ),names=getTranslatedNames())
})
# getTranslatedWordCloud <- function(){
#   return (i18n()$t("WordCloud"))
# }
# output$Tables <- renderText({
#   browser()
#   HTML(stri_enc_toutf8(i18n()$t("Tables")))
#   
# })
# output$WordCloud <- renderText({ 
#   browser()
#   HTML(stri_enc_toutf8(i18n()$t("Word Cloud")))
#   
# })
#addPopover(session, 'applinks', "", tt('applinks'), placement='top')
})
