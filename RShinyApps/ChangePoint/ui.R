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
                 numericInput_p('maxcp2', "Maximum Number of Change Points", 3, 1, , step=1,
                               HTML( tt('cplimit1') ), tt('cplimit2'),
                               placement='left')
                
                  ),
                 uiOutput("daterange"),
    # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date() ),

      tabsetPanel(
                 tabPanel(uiOutput("ChangeinMeanAnalysis"), 
                          wellPanel(
                            column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlChangeinMeanAnalysis", textOutput("downloadBtnLbl"))))),
                            
                            style="background-color:white;height:60px;border:none",uiOutput("infocpmeantext", style = "position:absolute;margin-bottom:20px;right:40px;z-index:10")
                          ),
                            withSpinner(plotlyOutput( 'cpmeanplot' )) 
                          ),
                tabPanel(uiOutput("ChangeinVarianceAnalysis"), 
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn2","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlChangeinVarianceAnalysis", "Download")))),
                           style="background-color:white;height:60px;border:none",uiOutput("infocpvartext", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(plotlyOutput( 'cpvarplot' ) )
                         ),
                 tabPanel(uiOutput("BayesianChangepointAnalysis"),  
                          wellPanel(
                            column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn3","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlBayesianChangepointAnalysis", "Download")))),
                            style="background-color:white;height:60px;border:none",uiOutput("infocpbayestext", style = "position:absolute;right:40px;z-index:10")
                          ),
                          withSpinner(plotlyOutput( 'cpbayesplot' ))
                            # verbatimTextOutput( 'cpbayestext' )
                          ),
                tabPanel(uiOutput("ReportCountsbyDate"),  
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn4","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlReportCountsbyDate", "Download")))),
                           style="background-color:white;height:60px;border:none",uiOutput("infoReportCountsbyDate", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(plotlyOutput('queryplot'))
                         
                ),
                tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn5","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlCountsForDrugsInSelectedReports", "Download")))),
                           style="background-color:white;height:60px;border:none",uiOutput("infoCountsForDrugsInSelectedReports", style = "position:absolute;right:40px;z-index:10")
                         ),
                         withSpinner(dataTableOutput('coquery'))
                ),
                tabPanel(uiOutput("CountsForEventsInSelectedReports"),
                         wellPanel(
                           column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn6","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlCountsForEventsInSelectedReports", "Download")))),
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

