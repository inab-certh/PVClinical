library(shiny)
library(shinyjs)
library(shinycssloaders)
library(plotly)
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
                           column(width=12, bsAlert("nodata_lrteste"))),
                  fluidRow(id="mainrow", useShinyjs(),
                           column(width=12),
                                  # titlePanel(uiOutput("LRTSignalAnalysisforanEvent") ),                           
                                  
                                  hidden(
                                    uiOutput('page_content'),
                                    selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                                  HTML( tt('drugvar1') ), tt('drugvar2'),
                                                  placement='top'), 
                                    
                                    textInput_p("t1", "Event Name", 'NEPHROGENIC SYSTEMIC FIBROSIS', 
                                                HTML( tt('drugname1') ), tt('drugname2'),
                                                placement='bottom'), 
                                    textInput_p("lang", "lang", '', 
                                                HTML( tt('en') ), tt('gr'),
                                                placement='bottom'),
                                    
                                    numericInput_p('limit', 'Maximum number of event terms', 50,
                                                   1, 100, step=1, 
                                                   HTML( tt('limit1') ), tt('limit2'),
                                                   placement='bottom'), 
                                    
                                    numericInput_p('start', 'Rank of first drug', 1,
                                                   1, 999, step=1, 
                                                   HTML( tt('limit1') ), tt('limit2'),
                                                   placement='bottom'),
                                    
                                    numericInput_p('numsims', 'Number of Simulations', 1000,
                                                   1000, 50000, step=1, 
                                                   HTML( tt('numsims1') ), tt('numsims2'),
                                                   placement='bottom'),
                                    
                                    
                                    renderDrugName(),
                                    radioButtons('useexact', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected='any'),
                                    renderLimit(),
                                    renderStart(),
                                    renderNumsims(),
                                    
                                    
                                    
                                    textInput_p("drugname", "Name of Event", 'NEPHROGENIC SYSTEMIC FIBROSIS', 
                                                HTML( tt('drugname1') ), tt('drugname2'),
                                                placement='left'), 
                                    numericInput_p('limit2', 'Maximum number of event terms', 50,
                                                   1, 100, step=1, 
                                                   HTML( tt('limit1') ), tt('limit2'),
                                                   placement='left'),
                                    
                                    numericInput_p('start2', 'Rank of first drug', 1,
                                                   1, 999, step=1, 
                                                   HTML( tt('limit1') ), tt('limit2'),
                                                   placement='left'),
                                    
                                    numericInput_p('numsims2', 'Number of Simulations', 1000,
                                                   1000, 50000, step=1, 
                                                   HTML( tt('numsims1') ), tt('numsims2'),
                                                   placement='bottom'),
                                    
                                    radioButtons('format', 'Document format', c('PDF', 'HTML', 'Word'),
                                                 inline = TRUE),
                                    downloadButton('downloadReport', 'Download LRT Report')
                                  ),
                                  dateRangeInput('daterange', uiOutput('UseReportsBetween'), start = '1989-6-30', end = Sys.Date()),
                                  
                                  tabsetPanel(
                                    tabPanel(
                                      uiOutput("LRTResultsbasedonTotalDrugs"),
                                      wellPanel(
                                        column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr", "Download")))),
                                        style="background-color:white;height:60px;border:none",uiOutput("prrtitle", style = "position:absolute;right:40px;z-index:10")
                                      ),
                                        withSpinner(dataTableOutput("prr")
                                      )
                                      
                                    ),
                                    tabPanel(uiOutput("SimulationResultsforDrugBasedLRT"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlsimplot", "Download")))),
                                             ),
                                             plotlyOutput( 'simplot')
                                    ),
                                    tabPanel(uiOutput("AnalyzedDrugCountsforEventText")   ,
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlAnalyzedEventCountsforDrug", "Download")))),
                                             ),
                                             withSpinner(dataTableOutput( 'AnalyzedEventCountsforDrug' ))
                                    ),
                                    tabPanel(uiOutput("AnalyzedDrugCountsforAllEvents"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlall", "Download")))),
                                             ),
                                             withSpinner(dataTableOutput( 'all' ))
                                    ),
                                    tabPanel(uiOutput("CountsForEventsInSelectedReports"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery", "Download")))),
                                             ),
                                             withSpinner(dataTableOutput( 'coquery' ))
                                    ),
                                    tabPanel(uiOutput("DrugCountsforEvent"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE", "Download")))),
                                             ),
                                             withSpinner(dataTableOutput( 'coqueryEex' ))
                                    ),
                                    tabPanel(uiOutput("CountsForAllDrugs"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryA", "Download")))),
                                             ),
                                             withSpinner(dataTableOutput( 'coqueryA' ))
                                    ),
                                    tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlindquery", "Download")))),
                                             ),
                                             withSpinner(dataTableOutput( 'indquery' ))
                                    ),
                                    tabPanel(uiOutput("OtherApps"),  
                                             wellPanel( 
                                               htmlOutput( 'applinks' )
                                             )
                                    ),
                                    tabPanel(uiOutput('DataReference'), HTML( renderiframe('https://open.fda.gov/drug/event/')   )  ),
                                    tabPanel(uiOutput('About'), 
                                             img(src='l_openFDA.png'),
                                             HTML( (loadhelp('about') ) )  )
                                    
                                  )
                           )
                  )
)

