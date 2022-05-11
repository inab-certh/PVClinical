library(rsconnect)
library(shinyjs)
library(shinycssloaders)
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

shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
                  fluidRow(useShinyjs(), 
                    
                    column(width=12,bsAlert("nodata_rrd"),
                           # titlePanel("RR-Drug" ) 
                           ),
                    
                    hidden(
                      uiOutput('page_content'),
                      
                      radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected='any'),
                      
                      renderDates(),
                      
                      selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top'), 
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
                                     placement='bottom')
                      
                    ),
                    tags$div(style='padding-left:40px',
                             fluidRow( useShinyjs(),
                                       style="margin-bottom: 0.3rem",
                                       column(width=2, dateInput("date1", "", value = (Sys.Date()-365)) ),
                                       column(width=1, p("to"),
                                              style="margin-top: 2.45rem; text-align: center;"),
                                       column(width=2, dateInput("date2", "", value = Sys.Date()) ),
                                       column(id="xlsrow", width=2, style="float:right; margin-top: 1rem;",
                                              #                           # style="display:inline-block",
                                              #                           #     div(id="downloadExcelColumn",
                                              #                           #         textOutput("downloadDataLbl"))),
                                              #                           # div(style="display:inline-block; margin-left:20px;",
                                              downloadButton("dlprr2", textOutput("downloadBtnLbl"))),
                                       )
                             # dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                             # uiOutput("dtlocator"),
                             # uiOutput("daterange"),
                             ),
                    tabsetPanel(
                      tabPanel(uiOutput("PRRRORResults"),
                               uiOutput("sourcePRRDataframe", style = "display:inline-block; margin-left:20px;"),
                               wellPanel(
                                 # column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl1"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr2", textOutput("downloadBtnLbl1"))))),
                                 style="background-color:white;height:60px;border:none",uiOutput( 'prrtitleBlank' ),uiOutput("infoprr2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               withSpinner(dataTableOutput( 'prr2' ))
                      ),
                      tabPanel(uiOutput("AnalyzedEventCountsforSpecifiedDrug")   ,
                               uiOutput("sourceDrugDataframe", style = "display:inline-block; margin-left:20px;"),
                               wellPanel(
                                 column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl2"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlspecifieddrug2", textOutput("downloadBtnLbl2"))))),
                                 style="background-color:white;height:60px;border:none",uiOutput("infospecdrug",style = "position:absolute;right:40px;z-index:10")
                               ),
                               withSpinner(dataTableOutput( 'specifieddrug2' ))
                      ),
                      tabPanel(uiOutput("AnalyzedEventCountsforAllDrugs"),
                               uiOutput("sourceEventDataframe", style = "display:inline-block; margin-left:20px;"),
                               wellPanel(
                                 column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl3"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlall2", textOutput("downloadBtnLbl3"))))),
                                 style="background-color:white;height:60px;border:none",uiOutput("infoeventcountsalldrugs",style = "position:absolute;right:40px;z-index:10")
                               ),
                               withSpinner(dataTableOutput( 'all2' ))
                      ),
                      tabPanel(uiOutput("RankedEventCountsforDrug"),
                               uiOutput("sourceCoeventsDataframe", style = "display:inline-block; margin-left:20px;"),
                               wellPanel(
                                 column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl4"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE2", textOutput("downloadBtnLbl4"))))),
                                 style="background-color:white;height:60px;border:none",uiOutput("infoRankedEventCounts",style = "position:absolute;right:40px;z-index:10")
                               ),
                               withSpinner(dataTableOutput( 'coqueryE2' ))
                      ),
                      tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                               uiOutput("sourceCodrugDataframe", style = "display:inline-block; margin-left:20px;"),
                               wellPanel(
                                 column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl5"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery2", textOutput("downloadBtnLbl5"))))),
                                 style="background-color:white;height:60px;border:none",uiOutput("infoCountsForDrugsInSelectedReports",style = "position:absolute;right:40px;z-index:10")
                               ),
                               withSpinner(dataTableOutput( 'coquery2' ))
                      ),
                      tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                               uiOutput("sourceIndrugDataframe", style = "display:inline-block; margin-left:20px;"),
                               wellPanel(
                                 column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl6"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dlindquery2", textOutput("downloadBtnLbl6"))))),
                                 style="background-color:white;height:60px;border:none",uiOutput("infoindquery2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               withSpinner(dataTableOutput( 'indquery2' ))
                      ),
                      id='maintabs', selected=  uiOutput("PRRRORResults") 
                    ),
                      

        )
      )
    )
