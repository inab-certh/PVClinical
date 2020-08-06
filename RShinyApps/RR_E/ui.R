library(shiny)
library(shinyjs)
library(shinycssloaders)

source('sourcedir.R')

# getdrugvarchoices <- function(){
#   openfdavars <- c(
#     'generic_name',
#     'substance_name',
#     'brand_name')
#   openfdavars <-  paste0( 'patient.drug.openfda.', openfdavars )
#   s <- c( openfdavars, 'patient.drug.medicinalproduct')
#   return(s)
# }

renderEventName <- function() {
  (htmlOutput('eventname'))
  
}
renderLimit <- function() {
  (htmlOutput('limit'))
  
}
renderStart <- function() {
  (htmlOutput('start'))
  
}
shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),fluidRow(
  useShinyjs(),
  
  column(
    width = 12,bsAlert("nodata_rrd"),
    # titlePanel("RR-Event"),
    
    hidden(
      uiOutput('page_content'),
      
      textInput_p(
        "t1",
        "Adverse Reaction",
        '',
        HTML(tt('eventname1')),
        tt('eventname2'),
        placement = 'bottom'
      ),
      textInput_p("lang", "lang", '', 
                  HTML( tt('en') ), tt('gr'),
                  placement='bottom'),
      selectInput_p("v1", 'Drug Variable' , getdrugvarchoices(),
                    #                                               HTML( tt('drugvar1') ), tt('drugvar2'),
                    placement = 'top'),
      
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
      textInput_p(
        "drugname",
        "Adverse Reaction",
        '',
        HTML(tt('eventname1')),
        tt('eventname2'),
        placement = 'left'
      ),
      
      numericInput_p(
        'limit2',
        'Maximum number of drugs',
        50,
        1,
        100,
        step = 1,
        HTML(tt('limit1')),
        tt('limit2'),
        placement = 'left'
      ),
      
      numericInput_p(
        'start2',
        'Rank of first event',
        1,
        1,
        999,
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
      )
      
    ),
    
    dateRangeInput(
      'daterange','',
      # uiOutput('UseReportsBetween'),
      start = '1989-6-30',
      end = Sys.Date()
    ),
    tabsetPanel(
      tabPanel(
        uiOutput("PRRRORResults"),
        wellPanel(
          column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlprr2", "Download")))),
          style="background-color:white;height:60px;border:none",uiOutput( 'prrtitleBlank' ),uiOutput("infoprr2",style = "position:absolute;right:40px;z-index:10")
        ),
        dataTableOutput( 'prr2' )
      ),
      tabPanel(
        uiOutput("AnalyzedEventCountsforSpecifiedDrug")   ,
        wellPanel(
          column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlspecifieddrug2", "Download")))),
          style="background-color:white;height:60px;border:none",uiOutput("infospecifieddrug2",style = "position:absolute;right:40px;z-index:10")
        ),
        withSpinner(dataTableOutput( 'specifieddrug2' ))
        
      ),
      tabPanel(
        uiOutput("AnalyzedDrugCountsforAllEvents"),
        wellPanel(
          column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlall2", "Download")))),
          style="background-color:white;height:60px;border:none",uiOutput("infoall2",style = "position:absolute;right:40px;z-index:10")
        ),
        withSpinner(makeDataTableOutput( 'all2' ))
      ),
      tabPanel(
        uiOutput("RankedDrugCountsforEvent"),
        wellPanel(
          column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoqueryE2", "Download")))),
          style="background-color:white;height:60px;border:none",uiOutput("infocoqueryE2",style = "position:absolute;right:40px;z-index:10")
        ),  
        withSpinner(makeDataTableOutput( 'coqueryE2' ))
        ),
        
        tabPanel(
          uiOutput("CountsForEventsInSelectedReports"),
          wellPanel(
            column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlcoquery2", "Download")))),
            style="background-color:white;height:60px;border:none",uiOutput("infocoquery2",style = "position:absolute;right:40px;z-index:10")
          ),
          withSpinner(makeDataTableOutput( 'coquery2' )) 
        ),
        tabPanel(
          uiOutput("CountsForIndicationsInSelectedReports"),
          wellPanel(
            column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn","Download Data in Excel format")),div(style="display:inline-block; margin-left:20px;",downloadButton("dlindquery2", "Download")))),
            style="background-color:white;height:60px;border:none",uiOutput("infoindquery2",style = "position:absolute;right:40px;z-index:10")
          ),
          withSpinner(makeDataTableOutput( 'indquery2' )) 
        ),
        id = 'maintabs',
        selected = uiOutput("PRRRORResults")
      )
    )
  )
))
