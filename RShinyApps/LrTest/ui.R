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
                  dateRangeInput('daterange', '',
                                 # uiOutput('UseReportsBetween'), 
                                 start = '1989-6-30', end = Sys.Date()),
                  
                  
                  tabsetPanel(
                    tabPanel(uiOutput("LRTResultsbasedonTotalEvents"),
                             dataTableOutput('prr')
                             
                    ),
                    tabPanel(uiOutput("SimulationResultsforEventBasedLRT"),
                             plotlyOutput( 'simplot')
                    ),
                    tabPanel(uiOutput("AnalyzedEventCountsforDrugText")   ,
                             dataTableOutput('AnalyzedEventCountsforDrug')
                    ),
                    tabPanel(uiOutput("AnalyzedEventCountsforAllDrugs"),
                             dataTableOutput( 'all' )
                    ),
                    tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                             dataTableOutput('coquery')
                    ),
                    tabPanel(uiOutput("EventCountsforDrug"),
                             dataTableOutput('coqueryE')
                    ),
                    tabPanel(uiOutput("CountsForAllEvents"),
                             dataTableOutput('coqueryA')
                    ),
                    tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                             dataTableOutput('indquery')
                    )
                    
                  )
           )
  )
)
)
