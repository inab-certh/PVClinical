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
  fluidRow(useShinyjs(),
           column(width=12, titlePanel("LRT Signal Analysis for a Drug" ),                           
                  
                  hidden(
                 selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                               HTML( tt('drugvar1') ), tt('drugvar2'),
                               placement='top'), 
                 textInput_p("t1", "Drug Name", 'Gadobenate', 
                               HTML( tt('drugname1') ), tt('drugname2'),
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
                 dateRangeInput('daterange', 'Use Reports Between: ', start = '1989-6-30', end = Sys.Date()),
                 
        
      tabsetPanel(
                tabPanel("LRT Results based on Total Events",
                         wellPanel(
                         htmlOutput( 'prrtitle' ), 
                         helpText('Results sorted by LRR')
                         ),

                         maketabset( c('prr', 'cloudprr', 'textplot'), 
                                     types=c('html', "plot", 'plot'),
                                     names=c("Table","Word Cloud", "Text Plot") )
                ),
              tabPanel("Simulation Results for Event Based LRT",
                       wellPanel( 
                         plotOutput( 'simplot')
                        )
              ),
                tabPanel("Analyzed Event Counts for Drug"   ,
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
                tabPanel("Analyzed Event Counts for All Drugs",
                         wellPanel( 
                           htmlOutput( 'alltext' ),
                           htmlOutput_p( 'queryalltext' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                         ),
                        htmlOutput( 'alltitle' ), 
                        wordcloudtabset('cloudall', 'all')
                ),
                tabPanel("Counts For Drugs In Selected Reports",
                         wellPanel( 
                           htmlOutput( 'cotext' ),
                           htmlOutput_p( 'querycotext' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' )
                         ),
                           htmlOutput( 'cotitle' ),
                         wordcloudtabset('cloudcoquery', 'coquery')
                 ),
                tabPanel("Event Counts for Drug",
                         wellPanel( 
                           htmlOutput( 'cotextE' ),
                           htmlOutput_p( 'querycotextE' ,
                                         tt('gquery1'), tt('gquery2'),
                                         placement='bottom' )
                         ),
                         wellPanel(
                           htmlOutput( 'cotitleE' )
                         ),
                         wellPanel(
                           htmlOutput( 'cotitleEex' ),
                           htmlOutput( 'coqueryEex' )
                         ),
                         htmlOutput_p( 'coquerytextE' ,
                                       tt('gquery1'), tt('gquery2'),
                                       placement='bottom' ),
                         wordcloudtabset('cloudcoqueryE', 'coqueryE',
                                         popheads=c( tt('codrug1'), tt('word1') ), 
                                         poptext=c( tt('codrug3'), tt('word2') ))
                ),
                tabPanel("Counts For All Events",
                         wellPanel( 
                           htmlOutput( 'cotextA' ),
                           htmlOutput_p( 'querycotextA' ,
                                         tt('gquery1'), tt('gquery2'),
                                         placement='bottom' )
                         ),
                         wellPanel(
                           htmlOutput( 'cotitleA' )
                         ),

                         wordcloudtabset('cloudcoqueryA', 'coqueryA',
                                         popheads=c( tt('codrug1'), tt('word1') ), 
                                         poptext=c( tt('codrug3'), tt('word2') ))
                ),
                tabPanel("Counts For Indications In Selected Reports",
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
                tabPanel("Other Apps",  
                         wellPanel( 
                           htmlOutput( 'applinks' )
                         )
                ),
                tabPanel('Data Reference', HTML( renderiframe('https://open.fda.gov/drug/event/') ) ),
                tabPanel('About', 
                         img(src='l_openFDA.png'),
                         HTML( (loadhelp('about') ) )  )

            )
          )
        )
      )
    )
