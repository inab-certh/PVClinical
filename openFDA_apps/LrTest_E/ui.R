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
                                    
                                    textInput_p("t1", "Event Name", '',
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
                                    
                                    
                                    
                                    # textInput_p("drugname", "Name of Event", 'NEPHROGENIC SYSTEMIC FIBROSIS', 
                                    #             HTML( tt('drugname1') ), tt('drugname2'),
                                    #             placement='left'), 
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
                           # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                           fluidRow( useShinyjs(),
                                     style="margin-bottom: 0.3rem; margin-left: 0.3rem;",
                                     column(width=2, dateInput("date1", "", value = (Sys.Date()-365)) ),
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
                                  #uiOutput("daterange"),
                           # uiOutput("dtlocator"),
                                  
                                  tabsetPanel(
                                    tabPanel(
                                      uiOutput("LRTResultsbasedonTotalDrugs"),
                                      uiOutput("sourcePRRDataframe", style = "display:inline-block; margin-left:20px;"),
                                      wellPanel(
                                        # column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl1"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr",  textOutput("downloadBtnLbl1"))))),
                                        style="background-color:white;height:60px;border:none",uiOutput("prrtitle", style = "position:absolute;right:40px;z-index:10"),
                                        uiOutput("inforrandllr",style = "position:absolute;right:40px;z-index:10")),
                                        withSpinner(dataTableOutput("prr")
                                      )
                                      
                                    ),
                                    tabPanel(uiOutput("SimulationResultsforDrugBasedLRT"),
                                             uiOutput("sourceLLRPlotReport", style = "display:inline-block; margin-left:20px;"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl2"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlsimplot", textOutput("downloadBtnLbl2"))))),
                                             ),
                                             plotlyOutput( 'simplot')
                                    ),
                                    tabPanel(uiOutput("AnalyzedDrugCountsforEventText"),
                                             uiOutput("sourceResDataframe", style = "display:inline-block; margin-left:20px;"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl3"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlAnalyzedEventCountsforDrug", textOutput("downloadBtnLbl3"))))),
                                                       uiOutput("infospecevent",style = "position:absolute;right:40px;z-index:10")),
                                             withSpinner(dataTableOutput( 'AnalyzedEventCountsforDrug' ))
                                    ),
                                    tabPanel(uiOutput("AnalyzedDrugCountsforAllEvents"),
                                             uiOutput("sourceInDataframe", style = "display:inline-block; margin-left:20px;"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl4"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlall", textOutput("downloadBtnLbl4"))))),
                                                       uiOutput("infodrugcountsallevents",style = "position:absolute;right:40px;z-index:10")),
                                             withSpinner(dataTableOutput( 'all' ))
                                    ),
                                    tabPanel(uiOutput("CountsForEventsInSelectedReports"),
                                             uiOutput("sourcePrrInDataframe", style = "display:inline-block; margin-left:20px;"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl5"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery", textOutput("downloadBtnLbl5"))))),
                                                       uiOutput("infoCountsForEventsInSelectedReports",style = "position:absolute;right:40px;z-index:10")),
                                             withSpinner(dataTableOutput( 'coquery' ))
                                    ),
                                    # tabPanel(uiOutput("DrugCountsforEvent"),
                                    #          uiOutput("sourceCoDataframe", style = "display:inline-block; margin-left:20px;"),
                                    #          wellPanel(style="background-color:white;height:30px;border:none",
                                    #                    column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl6"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE", textOutput("downloadBtnLbl6"))))),
                                    #                    uiOutput("infoRankedDrugCounts",style = "position:absolute;right:40px;z-index:10")),
                                    #          withSpinner(dataTableOutput( 'coqueryEex' ))
                                    # ),
                                    tabPanel(uiOutput("CountsForAllDrugs"),
                                             uiOutput("sourceAcDataframe", style = "display:inline-block; margin-left:20px;"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl7"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryA", textOutput("downloadBtnLbl7"))))),
                                                       uiOutput("infoCountsForAllDrugs",style = "position:absolute;right:40px;z-index:10")),
                                             withSpinner(dataTableOutput( 'coqueryA' ))
                                    ),
                                    tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                                             uiOutput("sourceInqDataframe", style = "display:inline-block; margin-left:20px;"),
                                             wellPanel(style="background-color:white;height:30px;border:none",
                                                       column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl8"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlindquery", textOutput("downloadBtnLbl8"))))),
                                                       uiOutput("infoindquery2",style = "position:absolute;right:40px;z-index:10")),
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

