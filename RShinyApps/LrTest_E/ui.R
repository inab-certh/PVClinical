library(shiny)
library(shinyjs)

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

shinyUI(fluidPage(
  fluidRow(useShinyjs(),uiOutput('page_content'),
           column(width=12, titlePanel(uiOutput("LRTSignalAnalysisforanEvent") ),                           
                  
                  hidden(
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
                tabPanel(uiOutput("LRTResultsbasedonTotalDrugs"),
                         wellPanel(
                         htmlOutput( 'prrtitle' ), 
                         helpText('Results sorted by LRR')
                         ),
#                          wordcloudtabset('cloudprr', 'prr', 
#                                          popheads=c( tt('prr1'), tt('word1') ), 
#                                          poptext=c( tt('prr5'), tt('word2') ) )
                        
uiOutput("makeTabsetLRTResultsbasedonTotalDrugs")
                         
                ),
              tabPanel(uiOutput("SimulationResultsforDrugBasedLRT"),
                       wellPanel( 
                         plotOutput( 'simplot')
                        )
              ),
              tabPanel(uiOutput("AnalyzedDrugCountsforEventText")   ,
                       wellPanel( 
                         htmlOutput( 'alldrugtextAnalyzedEventCountsforDrug' ),
                         htmlOutput_p( 'alldrugqueryAnalyzedEventCountsforDrug' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                       ), 
                       wellPanel( 
                         htmlOutput( 'titleAnalyzedEventCountsforDrug' ), 
                         #                          tableOutput("query"),
                         htmlOutput_p( 'queryAnalyzedEventCountsforDrug' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                       ),
                       wordcloudtabset('cloudAnalyzedEventCountsforDrug', 'AnalyzedEventCountsforDrug'
                       )
              ),
                tabPanel(uiOutput("AnalyzedDrugCountsforAllEvents"),
                         wellPanel( 
                           htmlOutput( 'alltext' ),
                           htmlOutput_p( 'queryalltext' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                         ),
                         wellPanel(
                           htmlOutput( 'alltitle' ), 
                         htmlOutput_p( 'allquerytext' ,
                                     tt('gquery1'), tt('gquery2'),
                                     placement='bottom' ) ),
                         wordcloudtabset('cloudall', 'all')
                ),
                tabPanel(uiOutput("CountsForEventsInSelectedReports"),
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
                         wordcloudtabset('cloudcoquery', 'coquery')
                 ),
                tabPanel(uiOutput("DrugCountsforEvent"),
                         wellPanel( 
                           htmlOutput( 'cotextE' ),
                           htmlOutput_p( 'querycotextE' ,
                                         tt('gquery1'), tt('gquery2'),
                                         placement='bottom' )
                         ),
                         wellPanel(
                           htmlOutput( 'cotitleD' )
                         ),
                         wellPanel(
                           htmlOutput( 'cotitleEex' )
 #                          htmlOutput( 'coqueryEex' )
                         ),
#                          htmlOutput_p( 'coquerytextE' ,
#                                        tt('gquery1'), tt('gquery2'),
#                                        placement='bottom' ),
                         wordcloudtabset('coqueryEex', 'coqueryE', names=c('Tables', 'Tables'),
                                         popheads=c( tt('codrug1'), tt('word1') ), 
                                         poptext=c( tt('codrug3'), tt('word2') ))
                ),
                tabPanel(uiOutput("CountsForAllDrugs"),
                         wellPanel( 
                           htmlOutput( 'cotextA' ),
                           htmlOutput_p( 'querycotextA' ,
                                         tt('gquery1'), tt('gquery2'),
                                         placement='bottom' )
                         ),
                         wellPanel(
                           htmlOutput( 'cotitleA' )
                         ),
                         htmlOutput_p( 'coquerytextA' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' ),
                         wordcloudtabset('cloudcoqueryA', 'coqueryA',
                                         popheads=c( tt('codrug1'), tt('word1') ), 
                                         poptext=c( tt('codrug3'), tt('word2') ))
                ),
                tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                         wellPanel( 
                           htmlOutput( 'indtext' ),
                           htmlOutput_p( 'queryindtext' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                         ),
                         wellPanel(
                           htmlOutput( 'indtitle' )
                         ),
                         wordcloudtabset('cloudindquery', 'indquery',
                                         popheads=c( tt('indication1'), tt('word1') ),
                                         poptext=c( tt('indication2'), tt('word2') ) )
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
    )
