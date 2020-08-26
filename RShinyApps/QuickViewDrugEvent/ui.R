library(plotly)
library(rsconnect)
library(shinyjs)
library(shiny)
library(shinyWidgets)
library(DT)
library(shinycssloaders)
library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)


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
                  fluidRow(useShinyjs(),
                           column(id="xlsrow", width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dl", textOutput("downloadBtnLbl"))))),
                           # column(width=4,bsAlert("nodata_qvde"),uiOutput("infocpmeantext",style = "position:absolute;right:40px;z-index:10")
                           #        )
                           ),
                  fluidRow(useShinyjs(),
                           column(width=12, uiOutput("daterange"),
                                  fluidRow( bsAlert("nodata_qvde"),
                                            wellPanel(
                                              style="background-color:white;height:30px;border:none",uiOutput("infocpmeantext", style = "position:absolute;margin-bottom:20px;right:40px;z-index:10")
                                            ),
                                            # withSpinner(plotOutput( 'cpmeanplot' ))
                                            withSpinner(plotlyOutput( 'cpmeanplot'))
                                            )
                                  
                                  
                                  
                                 # wellPanel(
                                 #   plotOutput_p( 'cpmeanplot' ),
                                 #   htmlOutput_p( 'cpmeantext' )
                                 # )
                           ),
                                  
                           hidden(
                             # numericInput_p('limit', 'Maximum number of event terms', 50,
                             #                1, 100, step=1, 
                             #                HTML( tt('limit1') ), tt('limit2'),
                             #                placement='bottom'), 
                             # 
                             # numericInput_p('start', 'Rank of first event', 1,
                             #                1, 999, step=1, 
                             #                HTML( tt('limit1') ), tt('limit2'),
                             #                placement='bottom'),
                             
                             
                             
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
                             numericInput_p(
                               'limit',
                               'Maximum number of drugs',
                               50,
                               1,
                               100,
                               step = 1,
                               HTML(tt('limit1')),
                               tt('limit2'),
                               placement = 'bottom'
                             ),
                             radioButtons(
                               'useexact',
                               'Match Event Term:',
                               c('Exactly' = 'exact', 'Any Term' = 'any'),
                               selected = 'any'
                             ),
                             radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                             radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any' ),
                             
                             
                             textInput_p("drugname", "Name of Drug", '', HTML( tt('drugname1') ), tt('drugname2'), placement='left'), textInput_p("eventname", "Adverse Events", '', 
                                                                                                                                                  HTML( tt('eventname1') ), tt('eventname2'),
                                                                                                                                                  placement='left'),              
                             numericInput_p(
                               'start',
                               'Rank of first event',
                               1,
                               1,
                               999,
                               step = 1,
                               HTML(tt('limit1')),
                               tt('limit2'),
                               placement = 'bottom'
                             ),
                             numericInput_p('maxcp2', "Maximum Number of Change Points", 3, 1, ,  step=1,
                                            HTML( tt('cplimit1') ), tt('cplimit2'),
                                            placement='left')
                             
                           )
                           
                    
                    
                  
                    ),
                  
                                  
                                  
                                  
                                  tabsetPanel(
                                    tabPanel(uiOutput("PRRRORResults"),
                                             wellPanel(
                                               style="background-color:white;height:60px;border:none",uiOutput( 'prrtitleBlank' ),uiOutput("infoprr2",style = "position:absolute;right:40px;z-index:10")
                                             ),
                                             DTOutput( 'prr2' )
                                    ),
                                    # tabPanel(uiOutput("ChangeinVarianceAnalysis"), 
                                    #          wellPanel(
                                    #            style="background-color:white;height:60px;border:none",uiOutput("infocpvartext", style = "position:absolute;right:40px;z-index:10")
                                    #          ),
                                    #          withSpinner(plotlyOutput( 'cpvarplot' ) )
                                    # ),
                                    # tabPanel(uiOutput("BayesianChangepointAnalysis"),  
                                    #          wellPanel(
                                    #            style="background-color:white;height:60px;border:none",uiOutput("infocpbayestext", style = "position:absolute;right:40px;z-index:10")
                                    #          ),
                                    #          withSpinner(plotlyOutput( 'cpbayesplot' ))
                                    #          # verbatimTextOutput( 'cpbayestext' )
                                    # ),
                                    # tabPanel(uiOutput("ReportCountsbyDate"),  
                                    #          wellPanel(
                                    #            style="background-color:white;height:60px;border:none",uiOutput("infoReportCountsbyDate", style = "position:absolute;right:40px;z-index:10")
                                    #          ),
                                    #          withSpinner(plotlyOutput('queryplot'))
                                    #          
                                    # ),
                                    # tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                                    #          wellPanel(
                                    #            style="background-color:white;height:60px;border:none",uiOutput("infoCountsForDrugsInSelectedReports", style = "position:absolute;right:40px;z-index:10")
                                    #          ),
                                    #          withSpinner(dataTableOutput('coquery'))
                                    # ),
                                    # tabPanel(uiOutput("CountsForEventsInSelectedReports"),
                                    #          wellPanel(
                                    #            style="background-color:white;height:60px;border:none",uiOutput("infoCountsForEventsInSelectedReports", style = "position:absolute;right:40px;z-index:10")
                                    #          ),
                                    #          withSpinner(dataTableOutput('coqueryE'))
                                    # ),
                                    id='PRRRORPanel', selected = uiOutput("PRRRORResults")
                                  )
        )
      )

