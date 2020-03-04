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
shinyUI(fluidPage(fluidRow(
  useShinyjs(),
  
  column(
    width = 12,
    titlePanel("RR-Event"),
    
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
      'daterange',
      uiOutput('UseReportsBetween'),
      start = '1989-6-30',
      end = Sys.Date()
    ),
    tabsetPanel(
      tabPanel(
        uiOutput("PRRRORResults"),
        uiOutput('prrtitle'),
        withSpinner(makeDataTableOutput( 'prr2' ))
        # withSpinner(uiOutput("maketabsetPRRRORResults"))
      ),
      tabPanel(
        uiOutput("AnalyzedEventCountsforSpecifiedDrug")   ,
        # wellPanel(
        #   htmlOutput('alldrugtext'),
        #   htmlOutput_p('queryalldrugtext' ,
        #                tt('gquery1'), tt('gquery2'),
        #                placement = 'bottom')
        # ),
        # wellPanel(
        #   htmlOutput('querytitle'),
        #   htmlOutput_p('querytext' ,
        #                tt('gquery1'), tt('gquery2'),
        #                placement = 'bottom')
        # ),
        withSpinner(makeDataTableOutput( 'specifieddrug2' ))
        # wordcloudtabset(
        #   'cloudquery',
        #   'specifieddrug2',
        #   types = c('datatable', 'plot'),
        #   popheads = c(tt('drug1'), tt('word1')),
        #   poptext = c(tt('codrug1a'), tt('word2'))
        # )
      ),
      tabPanel(
        uiOutput("AnalyzedDrugCountsforAllEvents"),
        # wellPanel(
        #   htmlOutput('alltext'),
        #   htmlOutput_p('queryalltext' ,
        #                tt('gquery1'), tt('gquery2'),
        #                placement = 'bottom')
        # ),
        # wellPanel(htmlOutput('alltitle')),
        # htmlOutput_p('allquerytext' ,
        #              tt('gquery1'), tt('gquery2'),
        #              placement = 'bottom'),
        withSpinner(makeDataTableOutput( 'all2' ))
        # wordcloudtabset(
        #   'cloudall',
        #   'all2',
        #   types = c('datatable', 'plot'),
        #   popheads = c(tt('drug1'), tt('word1')),
        #   poptext = c(tt('codrug1a'), tt('word2'))
        # )
      ),
      tabPanel(
        uiOutput("RankedDrugCountsforEvent"),
          # wellPanel(
          #   htmlOutput('cotextE'),
          #   htmlOutput_p('querycotextE' ,
          #                tt('gquery1'), tt('gquery2'),
          #                placement = 'bottom')
          # ),
          # wellPanel(htmlOutput('cotitleD')),
          #                                  htmlOutput_p( 'coquerytextE' ,
          #                                                tt('gquery1'), tt('gquery2'),
          #                                                placement='bottom' ),
        withSpinner(makeDataTableOutput( 'coqueryE2' ))  
        # wordcloudtabset(
        #     'cloudcoqueryE',
        #     'coqueryE2',
        #     types = c('datatable', 'plot'),
        #     popheads = c(tt('codrug1'), tt('word1')),
        #     poptext = c(tt('codrug3'), tt('word2'))
        #   )
        ),
        tabPanel(
          uiOutput("CountsForEventsInSelectedReports"),
          # wellPanel(
          #   htmlOutput('cotext'),
          #   htmlOutput_p('querycotext' ,
          #                tt('gquery1'), tt('gquery2'),
          #                placement = 'bottom')
          # ),
          # wellPanel(
          #   htmlOutput('cotitle'),
          #   htmlOutput_p('coquerytext'  ,
          #                tt('gquery1'), tt('gquery2'),
          #                placement = 'bottom')
          # ) ,
          withSpinner(makeDataTableOutput( 'coquery2' )) 
          # wordcloudtabset(
          #   'cloudcoquery',
          #   'coquery2',
          #   types = c('datatable', 'plot'),
          #   popheads = c(tt('event1'), tt('word1')),
          #   poptext = c(tt('event2'), tt('word2'))
          # )
        ),
        tabPanel(
          uiOutput("CountsForIndicationsInSelectedReports"),
          # wellPanel(
          #   htmlOutput('indtext'),
          #   htmlOutput_p('queryindtext'  ,
          #                tt('gquery1'), tt('gquery2'),
          #                placement = 'bottom')
          # ),
          # wellPanel(htmlOutput('indtitle')),
          withSpinner(makeDataTableOutput( 'indquery2' )) 
          # wordcloudtabset(
          #   'cloudindquery',
          #   'indquery2',
          #   types = c('datatable', 'plot'),
          #   popheads = c(tt('indication1'), tt('word1')),
          #   poptext = c(tt('indication2'), tt('word2'))
          # )
        ),
        # tabPanel(uiOutput("OtherApps"),
        #          wellPanel(htmlOutput('applinks'))),
        # tabPanel(uiOutput("DataReference"), HTML(
        #   renderiframe("https://open.fda.gov/drug/event/")
        # )),
        # tabPanel(uiOutput("About"),
        #          img(src = 'l_openFDA.png'),
        #          HTML((loadhelp(
        #            'about'
        #          )))),
        id = 'maintabs',
        selected = uiOutput("PRRRORResults")
      )
    )
  )
))
