library(shiny)
library(shinyjs)
library(shinycssloaders)
source('sourcedir.R')
library(shinyalert)
library(DT)

options(encoding = 'UTF-8')


renderDrugName <- function() { 
  
  ( htmlOutput('drugname') )
  
} 
renderEventName <- function() { 
  
  ( htmlOutput('eventname') )
  
} 
  
renderEventText <- function() { 
  
  return( verbatimTextOutput('geteventtext') )
  
}    
shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
  fluidRow(useShinyjs(),useShinyalert(),
           column(width=12, bsAlert("nodata_dynprr"),
                  hidden(
                    uiOutput('page_content'),
                 selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                             HTML( tt('drugvar1') ), tt('drugvar2'),
                                             placement='top'), 
                 selectInput_p("v2", 'Time Variable' , c('receivedate', 'receiptdate'), 
                               HTML( tt('drugvar1') ), tt('drugvar2'),
                               placement='top', selected='receiptdate'), 
                 
                 textInput_p("t1", "Name of Drug", '', 
                             HTML( tt('drugname1') ), tt('drugname2'),
                             placement='bottom'), 
                 textInput_p("t2", "Adverse Events", '', 
                             HTML( tt('eventname1') ), tt('eventname2'),
                             placement='bottom'),
                 textInput_p("lang", "lang", '', 
                             HTML( tt('en') ), tt('gr'),
                             placement='bottom'),
                 renderEventText(),
                 
                   renderDrugName(),
                   radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                   renderEventName(),
                   radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                 
                 
                 
                          textInput_p("drugname", "Name of Drug", '', 
                                      HTML( tt('drugname1') ), tt('drugname2'),
                                      placement='left'), 
                          textInput_p("eventname", "Adverse Events", '', 
                                      HTML( tt('eventname1') ), tt('eventname2'),
                                      placement='left')
                 ),
                 dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                 #uiOutput("daterange"),
                 uiOutput("dtlocator"),
                          
                 tabsetPanel(
                   tabPanel(uiOutput('PRROverTime'),  
                            wellPanel(
                              column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr", textOutput("downloadBtnLbl")))), id="dlprrxlsrow"),
                              style="background-color:white;height:30px;border:none",uiOutput("infoprrplot", style = "position:absolute;right:40px;z-index:10")
                            ),
                            withSpinner(plotOutput_p( 'prrplot'))
                            
                   ),
                   tabPanel(uiOutput('ReportCountsandPRR'), 
                            wellPanel(
                              column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlquery_counts2", "Download"))), id="dlquery_counts2xlsrow"),
                              style="background-color:white;height:30px;border:none",uiOutput("infoquery_counts2", style = "position:absolute;right:40px;z-index:10")
                            ),
                            withSpinner(makeDataTableOutput( 'query_counts2' ))
                   ),
                   tabPanel(uiOutput('CountsForDrugsInSelectedReports'),
                            wellPanel(
                              column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery2", "Download"))), id="dlcoquery2xlsrow"),
                              style="background-color:white;height:30px;border:none",uiOutput("infocoquery2", style = "position:absolute;right:40px;z-index:10")
                            ),
                            withSpinner(makeDataTableOutput( 'coquery2' ))
                            
                            
                   ),
                   tabPanel(uiOutput('CountsForEventsInSelectedReports'),
                            wellPanel(
                              column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE2", "Download"))), id="dlcoqueryE2xlsrow"),
                              style="background-color:white;height:30px;border:none",uiOutput("infocoqueryE2", style = "position:absolute;right:40px;z-index:10")
                            ),
                            withSpinner(makeDataTableOutput( 'coqueryE2' ))
                   ),
                   id='maintabs'
                   
                 )
           )
  )
)
)
