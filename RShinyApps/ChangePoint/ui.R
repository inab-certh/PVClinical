library(shiny)
require(shinyBS)
library(shinyjs)

source( 'sourcedir.R')

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
rendermaxcp <- function() { 
  
  ( htmlOutput('maxcp') )
  
} 
shinyUI(fluidPage(
  fluidRow(useShinyjs(),
           column(width=12, titlePanel("Change Point Analysis" ),
                  
                  hidden(
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
                 numericInput_p('maxcp', "Maximum Number of Change Points", 3, 1, step=1,
                                HTML( tt('cplimit1') ), tt('cplimit2'),
                                placement='bottom'),
                  
                 
                 radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                 radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any' ),
                 
                 
                 textInput_p("drugname", "Name of Drug", '', HTML( tt('drugname1') ), tt('drugname2'), placement='left'), textInput_p("eventname", "Adverse Events", '', 
                                      HTML( tt('eventname1') ), tt('eventname2'),
                                      placement='left'),              
                 numericInput_p('maxcp2', "Maximum Number of Change Points", 3, 1, , step=1,
                               HTML( tt('cplimit1') ), tt('cplimit2'),
                               placement='left')
                
                  ),
        
    dateRangeInput('daterange', 'Date Report Was First Received by FDA.', start = '1989-6-30', end = Sys.Date() ),

      tabsetPanel(
                 tabPanel("Change in Mean Analysis",  
                          wellPanel( 
                            plotOutput_p( 'cpmeanplot' ), 
                            htmlOutput_p( 'cpmeantext' )
                            )
                          ),
                tabPanel("Change in Variance Analysis",  
                         wellPanel( 
                           plotOutput_p( 'cpvarplot' ), 
                           htmlOutput_p( 'cpvartext' )
                          )
                         ),
                 tabPanel("Bayesian Changepoint Analysis",  
                          wellPanel( 
                            plotOutput_p( 'cpbayesplot' ), 
                            verbatimTextOutput( 'cpbayestext' )
                            )
                          ),
                tabPanel("Report Counts by Date",  
                         wellPanel( 
                           htmlOutput_p( 'allquerytext',
                                         tt('gquery1'), tt('gquery2'),
                                         placement='bottom'  ),
                           htmlOutput_p( 'metatext' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                         ),
                         wellPanel( 
                           htmlOutput( 'querytitle' ),
                           htmlOutput_p( 'querytext',
                                       HTML( tt('gquery1') ), tt('gquery2'),
                                       placement='bottom' ),
                           htmlOutput_p("query",
                                        HTML( tt('ts1') ), tt('ts2'),
                                        placement='top'  )
                         )
                ),
                tabPanel("Counts For Drugs In Selected Reports",
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
                         wordcloudtabset('cloudcoquery', 'coquery',
                                         popheads=c( tt('codrug1'), tt('word1') ), 
                                         poptext=c( tt('codrug3'), tt('word2') ))
                ),
                tabPanel("Counts For Events In Selected Reports",
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
                         wordcloudtabset('cloudcoqueryE', 'coqueryE',
                                         popheads=c( tt('codrug1'), tt('word1') ), 
                                         poptext=c( tt('codrug3'), tt('word2') ))
                ),
                tabPanel("Other Apps",  
                         wellPanel( 
                           htmlOutput( 'applinks' )
                         )
                ),
                tabPanel('Data Reference', HTML( renderiframe( "https://open.fda.gov/drug/event/") ) 
                ),
                tabPanel('About', 
                         img(src='l_openFDA.png'),
                         HTML( (loadhelp('about') ) )  ),
#                 tabPanel("session",  
#                          wellPanel( 
#                            verbatimTextOutput( 'urlquery' )
#                          )
#                 ),
              id='maintabs', selected = 'Change in Mean Analysis'
            )
          )
        )
      )
    )

