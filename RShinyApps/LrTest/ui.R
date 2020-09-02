library(shiny)
library(shinyjs)
library(shinycssloaders)
library(plotly)
library(DT)

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

renderNumsims <- function() { 
  
  ( htmlOutput('numsims') )
  
}  

shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
  fluidRow(useShinyjs(), 
           column(width=12,bsAlert("nodata_lrtest"))),
  fluidRow(id="mainrow", useShinyjs(), 
           column(width=12,
                  # titlePanel(uiOutput("LRTSignalAnalysisforaDrug") ),                           
                  
                  hidden(
                    uiOutput('page_content'),
                    
                    selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                  HTML( tt('drugvar1') ), tt('drugvar2'),
                                  placement='top'), 
                    textInput_p("t1", "Drug Name", 'Gadobenate', 
                                HTML( tt('drugname1') ), tt('drugname2'),
                                placement='bottom'), 
                    textInput_p("lang", "lang", '', 
                                HTML( tt('en') ), tt('gr'),
                                placement='bottom'),
                    
                    numericInput_p('limit', 'Maximum number of event terms', 50,
                                   1, 100, step=1, 
                                   HTML( tt('limit1') ), tt('limit2'),
                                   placement='bottom'), 
                    
                    numericInput_p('start', 'Rank of first event', 1,
                                   1, 999, step=1, 
                                   HTML( tt('limit1') ), tt('limit2'),
                                   placement='bottom'),
                    
                    numericInput_p('numsims', 'Number of Simulations', 1000,
                                   1000, 50000, step=1, 
                                   HTML( tt('numsims1') ), tt('numsims2'),
                                   placement='bottom'),
                    renderDrugName(),
                    radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected='any'),
                    renderLimit(),
                    renderStart(),
                    renderNumsims(),
                    
                    
                    
                    textInput_p("drugname", "Name of Drug", 'Gadobenate', 
                                HTML( tt('drugname1') ), tt('drugname2'),
                                placement='left'), 
                    numericInput_p('limit2', 'Maximum number of event terms', 50,
                                   1, 100, step=1, 
                                   HTML( tt('limit1') ), tt('limit2'),
                                   placement='left'),
                    
                    numericInput_p('start2', 'Rank of first event', 1,
                                   1, 999, step=1, 
                                   HTML( tt('limit1') ), tt('limit2'),
                                   placement='left'),
                    
                    numericInput_p('numsims2', 'Number of Simulations', 1000,
                                   1000, 50000, step=1, 
                                   HTML( tt('numsims1') ), tt('numsims2'),
                                   placement='bottom'),
                    
                    radioButtons('format', 'Document format', c('PDF', 'HTML', 'Word'),
                                 inline = TRUE)
                    
                    
                  ),
                  # downloadButton('downloadReport', 'Download LRT Report'),
                  # dateRangeInput('daterange', '',
                  #                # uiOutput('UseReportsBetween'), 
                  #                start = '1989-6-30', end = Sys.Date()),
                  dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                  #uiOutput("daterange"),
                  uiOutput("dtlocator"),
                  
                  tabsetPanel(id="maintabs",
                    tabPanel(uiOutput("LRTResultsbasedonTotalEvents"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr",textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput('prr'))
                             
                    ),
                    tabPanel(uiOutput("SimulationResultsforEventBasedLRT"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlsimplot", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(plotlyOutput( 'simplot'))
                    ),
                    tabPanel(uiOutput("AnalyzedEventCountsforDrugText")   ,
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlAnalyzedEventCountsforDrug", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput('AnalyzedEventCountsforDrug'))
                    ),
                    tabPanel(uiOutput("AnalyzedEventCountsforAllDrugs"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlall", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput( 'all' ))
                    ),
                    tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput('coquery'))
                    ),
                    tabPanel(uiOutput("EventCountsforDrug"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput('coqueryE'))
                    ),
                    tabPanel(uiOutput("CountsForAllEvents"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryA", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput('coqueryA'))
                    ),
                    tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlindquery", textOutput("downloadBtnLbl"))))),
                             ),
                             withSpinner(dataTableOutput('indquery'))
                    )
                    
                  )
           )
  )
)
)
