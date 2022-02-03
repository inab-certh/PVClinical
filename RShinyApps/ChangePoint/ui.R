library(plotly)
library(shiny)
require(shinyBS)
library(shinyjs)
library(shinycssloaders)
library(DT)
source( 'sourcedir.R')
library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)

options(encoding = 'UTF-8')
# getdrugvarchoices <- function(){
#   openfdavars <- c( 
#     'generic_name',
#     'substance_name',
#     'brand_name')
#   openfdavars <-  paste0( 'patient.drug.openfda.', openfdavars )
#   s <- c( openfdavars, 'patient.drug.medicinalproduct')
#   return(s)
# }
renderDrugName <- function() { 
  
  ( htmlOutput('drugname') )
  
} 
renderEventName <- function() { 
  
  ( htmlOutput('eventname') )
  
}  
rendermaxcp <- function() { 
  
  ( htmlOutput('maxcp') )
  
} 



shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
                  fluidRow(useShinyjs(),style = "margin-top:15px;",
                           column(width=12, bsAlert("nodata_changepoint"))),
  fluidRow(id="mainrow", useShinyjs(),style = "margin-top:15px;",
           column(width=12,
                  hidden(
                    # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
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
                 numericInput_p('maxcp', "Maximum Number of Change Points", 3, 1, step=1,
                                HTML( tt('cplimit1') ), tt('cplimit2'),
                                placement='bottom'),
                  
                 
                 radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                 radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any' ),
                 
                 
                 textInput_p("drugname", "Name of Drug", '', HTML( tt('drugname1') ), tt('drugname2'), placement='left'), textInput_p("eventname", "Adverse Events", '', 
                                      HTML( tt('eventname1') ), tt('eventname2'),
                                      placement='left'),              
                 numericInput_p('maxcp2', "Maximum Number of Change Points", 3, 1, step=1,
                               HTML( tt('cplimit1') ), tt('cplimit2'),
                               placement='left')
                
                  ),
                 # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                 # # uiOutput("daterangeout"),
                 # uiOutput("dtlocator"),
                 fluidRow( useShinyjs(),
                           style="margin-bottom: 0.3rem",
                           column(width=2, dateInput("date1", "", value ='1989-6-30') ),
                           column(width=1, p("to"),
                                  style="margin-top: 2.45rem; text-align: center;"),
                           column(width=2, dateInput("date2", "", value = Sys.Date()) ),
                           column(id="xlsrow", width=2, style="float:right; margin-top: 1rem;",
                                  #                           # style="display:inline-block",
                                  #                           #     div(id="downloadExcelColumn",
                                  #                           #         textOutput("downloadDataLbl"))),
                                  #                           # div(style="display:inline-block; margin-left:20px;",
                                  downloadButton("dlChangeinMeanAnalysis", textOutput("downloadBtnLbl"))),
                           ),

      tabsetPanel(
                 tabPanel(uiOutput("ChangeinMeanAnalysis"), 
                          uiOutput("sourcePlotReport", style = "display:inline-block; margin-left:20px;"),
                          wellPanel(
                            # column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl1"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlChangeinMeanAnalysis", textOutput("downloadBtnLbl1"))))),
                            
                            style="background-color:white;height:60px;border:none",uiOutput("infocpmeantext", style = "position:absolute;margin-bottom:20px;right:40px;z-index:10")
                          ),
                            withSpinner(plotlyOutput( 'cpmeanplot' )) 
                          ),
                tabPanel(uiOutput("ChangeinVarianceAnalysis"),
                         uiOutput("sourceVarPlotReport", style = "display:inline-block; margin-left:20px;"),
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn2",textOutput("downloadDataLbl2"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlChangeinVarianceAnalysis", textOutput("downloadBtnLbl2"))))),
                           style="background-color:white;height:60px;border:none",uiOutput("infocpvartext", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(plotlyOutput( 'cpvarplot' ) )
                         ),
                 tabPanel(uiOutput("BayesianChangepointAnalysis"), 
                          uiOutput("sourceBayesPlotReport", style = "display:inline-block; margin-left:20px;"),
                          wellPanel(
                            column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn3",textOutput("downloadDataLbl3"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlBayesianChangepointAnalysis", textOutput("downloadBtnLbl3"))))),
                            style="background-color:white;height:60px;border:none",uiOutput("infocpbayestext", style = "position:absolute;right:40px;z-index:10")
                          ),
                          withSpinner(plotlyOutput( 'cpbayesplot' ))
                            # verbatimTextOutput( 'cpbayestext' )
                          ),
                tabPanel(uiOutput("ReportCountsbyDate"),  
                         uiOutput("sourceYearPlotReport", style = "display:inline-block; margin-left:20px;"),
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn4",textOutput("downloadDataLbl4"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlReportCountsbyDate", textOutput("downloadBtnLbl4"))))),
                           style="background-color:white;height:60px;border:none",uiOutput("infoReportCountsbyDate", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(plotlyOutput('queryplot'))
                         
                ),
                tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                         uiOutput("sourceCoDataframe", style = "display:inline-block; margin-left:20px;"),
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn5",textOutput("downloadDataLbl5"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlCountsForDrugsInSelectedReports", textOutput("downloadBtnLbl5"))))),
                           style="background-color:white;height:60px;border:none",uiOutput("infoCountsForDrugsInSelectedReports", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(dataTableOutput('coquery'))
                ),
                tabPanel(uiOutput("CountsForEventsInSelectedReports"),
                         uiOutput("sourceEvDataframe", style = "display:inline-block; margin-left:20px;"),
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn6",textOutput("downloadDataLbl6"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlCountsForEventsInSelectedReports", textOutput("downloadBtnLbl6"))))),
                           style="background-color:white;height:60px;border:none",uiOutput("infoCountsForEventsInSelectedReports", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(dataTableOutput('coqueryE'))
                ),
              id='maintabs', selected = uiOutput("ChangeinMeanAnalysis")
            )
          )
        )
      )
    )

