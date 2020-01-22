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
renderDrugName <- function() { 
  
  ( htmlOutput('drugname') )
  
} 
renderEventName <- function() { 
  
  ( htmlOutput('eventname') )
  
} 
# renderDrugText <- function() { 
#   
#   return('')
#   
# }   
renderEventText <- function() { 
  
  return( verbatimTextOutput('geteventtext') )
  
}    
shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
  fluidRow(useShinyjs(),
           column(width=12, titlePanel("Dynamic PRR" ),
                  
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
                 renderEventText(),
                 
                   renderDrugName(),
                   radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                   renderEventName(),
                   radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                 
                 
                 
                          textInput_p("drugname", "Name of Drug", '', 
                                      HTML( tt('drugname1') ), tt('drugname2'),
                                      placement='left'), 
                          textInput_p("eventname", "Adverse Events", '', 
                                      HTML( tt('eventname1') ), tt('eventname2'),
                                      placement='left')
                 ),
                 dateRangeInput('daterange', uiOutput('PlotPRRbetween'), start = '1989-6-30', end = Sys.Date()),
                          
      tabsetPanel(
        tabPanel(uiOutput('PRROverTime'),  
                 wellPanel( 
                   withSpinner(plotOutput_p( 'prrplot',
                                 tt('prr1'), tt('prr5'),
                                 placement='left', height='600px' ))
                 )
        ),
      tabPanel(uiOutput('ReportCountsandPRR'), 
               wellPanel( 
                 htmlOutput_p( 'querytitle' ), 
                 dataTableOutput_p("query_counts2",
                              tt('ts1'), tt('ts2'),
                              placement='top' )
               )
              ),
      tabPanel(uiOutput('CountsForDrugsInSelectedReports'),
               wellPanel( 
                 htmlOutput( 'cotext' ),
                 htmlOutput_p( 'querycotext' ,
                               tt('gquery1'), tt('gquery2'),
                               placement='bottom' )
               ),
               wellPanel(
                 htmlOutput( 'cotitle' )
               ),
               htmlOutput_p( 'coquerytext' ,
                             tt('gquery1'), tt('gquery2'),
                             placement='bottom' ),
               wordcloudtabset('cloudcoquery', 'coquery2', 
                               types=c('datatable', 'plot'),
                               popheads=c( tt('codrug1'), tt('word1') ), 
                               poptext=c( tt('codrug3'), tt('word2') ))
      ),
      tabPanel(uiOutput('CountsForEventsInSelectedReports'),
               wellPanel( 
                 htmlOutput( 'cotextE' ),
                 htmlOutput_p( 'querycotextE' ,
                               tt('gquery1'), tt('gquery2'),
                               placement='bottom' )
               ),
               wellPanel(
                 htmlOutput( 'cotitleE' )
               ),
               htmlOutput_p( 'coquerytextE' ,
                             tt('gquery1'), tt('gquery2'),
                             placement='bottom' ),
               wordcloudtabset('cloudcoqueryE', 'coqueryE2',
                               types=c('datatable', 'plot'),
                               popheads=c( tt('codrug1'), tt('word1') ), 
                               poptext=c( tt('codrug3'), tt('word2') ))
      ),
        # tabPanel(uiOutput('MetaDataandQueries'),  
        #          wellPanel( 
        #            htmlOutput_p( 'allquerytext' ,
        #                          tt('gquery1'), tt('gquery2'),
        #                          placement='bottom'),
        #            htmlOutput_p( 'drugquerytext',
        #                          tt('gquery1'), tt('gquery2'),
        #                          placement='bottom' ),
        #            htmlOutput_p( 'eventquerytext',
        #                          tt('gquery1'), tt('gquery2'),
        #                          placement='bottom' ),
        #            htmlOutput_p( 'drugeventquerytext' ,
        #                          tt('gquery1'), tt('gquery2'),
        #                          placement='bottom')
        #          )
        # ),
      # tabPanel(uiOutput('OtherApps'),  
      #          wellPanel( 
      #            htmlOutput( 'applinks' )
      #          )
      # ),
      # tabPanel(uiOutput('DataReference'), HTML( renderiframe( "https://open.fda.gov/drug/event/") ) 
      # ),
      # tabPanel(uiOutput('About'), 
      #          img(src='l_openFDA.png'),
      #          HTML( (loadhelp('about') ) )  ),
#                 tabPanel("session",  
#                          wellPanel( 
#                            verbatimTextOutput( 'urlquery' )
#                          )
#                 ),
              id='maintabs'
            )
          )
        )
      )
    )
