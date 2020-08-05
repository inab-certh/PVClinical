
library(rsconnect)
library(shinyjs)
library(shiny)
library(shinyWidgets)
library(shinycssloaders)
library(shinyalert)
library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)
library(plotly)

options(encoding = 'UTF-8')


source('sourcedir.R')

renderDrugName <- function() { 
  
  ( htmlOutput('drugname') )
  
} 
renderLimit <- function() { 
  
  ( htmlOutput('limit') )
  
}  

renderStart <- function() { 
  

  ( htmlOutput('start') )
  
}  

renderStart2 <- function() { 
  ( htmlOutput('start2') )
  
}  

getcurtab <- function() { 
#  browser()
#  print( textOutput('curtab') )
  
#  browser()
   s<-( textOutput('limit') )
   print(s)
#   ss <- strsplit( as.character(s), ">" , fixed=TRUE)
#   ss <- strsplit( as.character(ss[[1]][2]), "<" , fixed=TRUE)
#   print(ss[[1]][1])
  return(  "PRR and ROR Results" )
  
}  
countries <- c("en", "gr")

flags <- c(
  "https://cdn.rawgit.com/lipis/flag-icon-css/master/flags/4x3/gb.svg",
  "https://cdn.rawgit.com/lipis/flag-icon-css/master/flags/4x3/gr.svg"
)

shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
                  fluidRow( useShinyjs(),useShinyalert(),
                            column(width=12,bsAlert("nodata_qvd"),uiOutput("info",style = "position:absolute;right:40px;z-index:10"))),
                  fluidRow( useShinyjs(),useShinyalert(),
                            column(id="xlsrow", width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dl", "Download"))))),
                            # column(width=4,bsAlert("nodata_qvd"),uiOutput("info",style = "position:absolute;right:40px;z-index:10"))),
                                   # pickerInput("countries", "countries",
                                   # 
                                   #             choices = countries,
                                   # 
                                   #             choicesOpt = list(content =
                                   #                                 mapply(countries, flags, FUN = function(country, flagUrl) {
                                   #                                   HTML(paste(
                                   #                                     tags$img(src=flagUrl, width=20, height=15),
                                   #                                     country
                                   #                                   ))
                                   #                                 }, SIMPLIFY = FALSE, USE.NAMES = FALSE)
                                   # 
                                   #             )),
                                   # uiOutput('page_content'),
                            # ,uiOutput( "quickview" )),
                            
                            
                  fluidRow(useShinyjs(),
                           column(width=6,
                                  # fluidRow( withSpinner(plotOutput_p("seriousplot",HTML( tt('dot1') ), tt('dot2')))),
                                  fluidRow( column(width=10,offset=1,withSpinner(plotlyOutput("seriousplot")))),
                                  fluidRow( column(width=10,offset=1,withSpinner(plotlyOutput( 'cpmeanplot') )))
                                  
                                  
                                  
                                 # wellPanel(
                                 #   plotOutput_p( 'cpmeanplot' ),
                                 #   htmlOutput_p( 'cpmeantext' )
                                 # )
                           ),
                                  
                    column(width=5,offset=1,
                           fluidRow( align="center",style="width:90%; margin-top:60px;",
                                     # uiOutput('PRRTitle',style="font-weight:bold" ),
                                     withSpinner(makeDataTableOutput( 'prr2' ))),
                           #htmlOutput( 'prrtitle' ),
                           
                    hidden(
                      uiOutput('page_content'),
                      radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected='any'),
                      radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                      radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any' ),
                      
                      renderDates(),
                      
                      textInput_p("t2", "Adverse Events", '', 
                                  HTML( tt('eventname1') ), tt('eventname2'),
                                  placement='bottom'),
                      selectInput_p("v2", 'Time Variable' , c('receivedate', 'receiptdate'), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top', selected='receiptdate'), 
                      selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top'), 
                      textInput_p("t1", "Drug Name", '', 
                                  HTML( tt('drugname1') ), tt('drugname2'),
                                  placement='bottom'),
                      textInput_p("lang", "lang", '', 
                                  HTML( tt('en') ), tt('gr'),
                                  placement='bottom'),
                      numericInput_p('maxcp', "Maximum Number of Change Points", 3, 1, step=1,
                                     HTML( tt('cplimit1') ), tt('cplimit2'),
                                     placement='bottom'),
                      
                      numericInput_p('limit', 'Maximum number of event terms', 50,
                                     1, 100, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom'), 
                      
                      numericInput_p('start', 'Rank of first event', 1,
                                     1, 999, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom'),
                      textInput_p("drugname", "Name of Drug", '', HTML( tt('drugname1') ), tt('drugname2'), placement='left'), textInput_p("eventname", "Adverse Events", '', 
                                                                                                                                           HTML( tt('eventname1') ), tt('eventname2'),
                                                                                                                                           placement='left'),              
                      numericInput_p('maxcp2', "Maximum Number of Change Points", 3, 1, , step=1,
                                     HTML( tt('cplimit1') ), tt('cplimit2'),
                                     placement='left'),
                      dateRangeInput('daterange', 'Use Reports Between: ', start = '1989-6-30', end = Sys.Date())
                    ),
                    
                    
                    
                      
                      
                      
                    )
                  
                  
                  
        )
      )
    )
