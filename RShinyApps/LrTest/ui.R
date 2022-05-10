library(shiny)
library(shinyjs)
library(shinycssloaders)
library(plotly)
library(DT)
library(tidyverse)

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
           tags$head(tags$script(src="code.js")),
           column(width=12,
                  # titlePanel(uiOutput("LRTSignalAnalysisforaDrug") ),                           
                  
                  hidden(
                    uiOutput('page_content'),
                    
                    selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                  HTML( tt('drugvar1') ), tt('drugvar2'),
                                  placement='top'), 
                    textInput_p("t1", "Drug Name", '',
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
                    
                    
                    # 
                    # textInput_p("drugname", "Name of Drug", 'Gadobenate', 
                    #             HTML( tt('drugname1') ), tt('drugname2'),
                    #             placement='left'), 
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
                  # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                  fluidRow( useShinyjs(),
                            style="margin-bottom: 0.3rem",
                            column(width=2, dateInput("date1", "", value = (Sys.Date()-365)) ),
                            # column(width=2, dateInput("date1", "", value = '2014-1-01') ),
                            column(width=1, p("to"),
                                   style="margin-top: 2.45rem; text-align: center;"),
                            column(width=2, dateInput("date2", "", value = Sys.Date()) ),
                            column(id="xlsrow", width=2, style="float:right; margin-top: 1rem;",
                                   #                           # style="display:inline-block",
                                   #                           #     div(id="downloadExcelColumn",
                                   #                           #         textOutput("downloadDataLbl"))),
                                   #                           # div(style="display:inline-block; margin-left:20px;",
                                   downloadButton("dlprr", textOutput("downloadBtnLbl"))),
                            ),
                            # column(width=2, dateInput("date2", "", value = Sys.Date()) ),),
                            
                  # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                  # uiOutput("dtlocator"),
                  # uiOutput("daterange"),
                
                  #uiOutput("daterange"),
                  # uiOutput("dtlocator"),
                  
                  tabsetPanel(id="maintabs",
                    tabPanel(uiOutput("LRTResultsbasedonTotalEvents"),
                             uiOutput("sourcePRRDataframe", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                # column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl1"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr",textOutput("downloadBtnLbl1"))))),
                                uiOutput("inforrandllr",style = "position:absolute;right:40px;z-index:10")),
                             withSpinner(dataTableOutput('prr'))
                             
                    ),
                    tabPanel(uiOutput("SimulationResultsforEventBasedLRT"),
                             uiOutput("sourceLLRPlotReport", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl2"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlsimplot", textOutput("downloadBtnLbl2"))))),
                             ),
                             withSpinner(plotlyOutput( 'simplot'))
                    ),
                    tabPanel(uiOutput("AnalyzedEventCountsforDrugText"),
                             uiOutput("sourceResDataframe", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl3"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlAnalyzedEventCountsforDrug", textOutput("downloadBtnLbl3"))))),
                                       uiOutput("infospecdrug",style = "position:absolute;right:40px;z-index:10")),
                             withSpinner(dataTableOutput('AnalyzedEventCountsforDrug'))
                    ),
                    tabPanel(uiOutput("AnalyzedEventCountsforAllDrugs"),
                             uiOutput("sourceInDataframe", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl4"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlall", textOutput("downloadBtnLbl4"))))),
                                       uiOutput("infoeventcountsalldrugs",style = "position:absolute;right:40px;z-index:10")),
                             withSpinner(dataTableOutput( 'all' ))
                    ),
                    tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                             uiOutput("sourcePrrInDataframe", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl5"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery", textOutput("downloadBtnLbl5"))))),
                                       uiOutput("infoCountsForDrugsInSelectedReports",style = "position:absolute;right:40px;z-index:10")),
                             withSpinner(dataTableOutput('coquery'))
                    ),
                    # tabPanel(uiOutput("EventCountsforDrug"),
                    #          uiOutput("sourceCoDataframe", style = "display:inline-block; margin-left:20px;"),
                    #          wellPanel(style="background-color:white;height:30px;border:none",
                    #                    column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl6"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE", textOutput("downloadBtnLbl6"))))),
                    #                    uiOutput("infoRankedEventCounts",style = "position:absolute;right:40px;z-index:10")),
                    #          withSpinner(dataTableOutput('coqueryE'))
                    # ),
                    tabPanel(uiOutput("CountsForAllEvents"),
                             uiOutput("sourceAcDataframe", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl7"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryA", textOutput("downloadBtnLbl7"))))),
                                       uiOutput("infoCountsForAllEvents",style = "position:absolute;right:40px;z-index:10")),
                             withSpinner(dataTableOutput('coqueryA'))
                    ),
                    tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                             uiOutput("sourceInqDataframe", style = "display:inline-block; margin-left:20px;"),
                             wellPanel(style="background-color:white;height:30px;border:none",
                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl8"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlindquery", textOutput("downloadBtnLbl8"))))),
                                       uiOutput("infoindquery2",style = "position:absolute;right:40px;z-index:10")),
                             withSpinner(dataTableOutput('indquery'))
                    )
                    
                  )
           )
  )
)
)
