library(shiny)
require(shinyBS)
library(shinycssloaders)

source('sourcedir.R')

# SOURCEDIR <- 'sharedscripts/'
# tipify(
#   selectInput("drugvar", 'Drug Variable' ,getdrugvarchoices()),
#   'openFDA Content'
# )



# getdrugvarchoices <- function(){
#   openfdavars <- c( 
#     'generic_name',
#     'substance_name',
#     'brand_name')
#   openfdavars <-  paste0( 'patient.drug.openfda.', openfdavars )
#   s <- c( openfdavars, 'patient.drug.medicinalproduct')
#   return(s)
# }



openfdavars <- getdrugvarchoices()

renderDrugName <- function() { 
  
  ( htmlOutput('drugname') )
  
} 
renderv1 <- function() { 
  
  ( uiOutput('v1_in') )
  
}  
renderdrugname <- function() { 
  s <- ( ('drugname_in') )
  s <- strsplit(s, '<', fixed=TRUE)
  s <- strsplit(s[1], '>', fixed=TRUE)
  return( s[2] )
} 
rendert1 <- function() { 
  
  ( uiOutput('t1_in') )
  
} 
renderuseexact <- function() { 
  
  ( uiOutput('useexact_in') )
  
} 
shinyUI(fluidPage(useShinyjs(), includeCSS("../sharedscripts/custom.css"),
                   fluidRow(
                     column(width=4,
                            # a(href='https://open.fda.gov/', 
                            #   img(src='l_openFDA.png', align='bottom')),
                            renderDates()
                     ),
                     column(width=8,
                            titlePanel(uiOutput( "dashboard" ) ) )
                   ),
#                    img(src='l_openFDA.png'),
#                    titlePanel( 'Dashboard' ),

                    hr(),
hidden(
  uiOutput('page_content'),
  
           selectInput_p("v1", 'Drug Variable' , openfdavars, 
                   HTML( tt('drugvar1') ), tt('drugvar2'),
                   placement='top'),
    
              textInput_p("t1", "Name of Drug", '', 
                   HTML( tt('drugname1') ), tt('drugname2'),
                    placement='bottom'),
                  # ),

           textInput_p("lang", "lang", '', 
                       HTML( tt('en') ), tt('gr'),
                       placement='bottom'),
              renderDrugName(),
             radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'),
                          selected='any', inline=TRUE),

           
                              textInput_p("drugname", "Name of Drug", '', 
                                          HTML( tt('drugname1') ), tt('drugname2'),
                                          placement='left'),
                              
    
          htmlOutput_p( 'alldrugtext' ,
          HTML( tt('gcount1') ), tt('gcount2'),
          placement='bottom'),
          htmlOutput_p( 'queryalldrugtext' ,
          HTML( tt('gquery1') ), tt('gquery2'),
          placement='bottom')
      ),
    

fluidRow(
    column(width=12,
           HTML(paste('<h4>',uiOutput( "productsummary" ),'</h4>', sep="")))),
  fluidRow(
    column(width=4,
           tabsetPanel(
             tabPanel(uiOutput( "table" ),
                        htmlOutput_p("source", 
                                      tt( 'freqtab1'), 
                                      tt( 'freqtab2') )
             ),
             tabPanel(uiOutput( "dotchart" ),
                      withSpinner(plotOutput_p("sourceplot", 
                                     HTML( tt('dot1') ), tt('dot2'), 
                                     height = "250px"))
             ),
             tabPanel(uiOutput( "piechart" ),
                        plotOutput_p("sourcepie", 
                                     HTML( tt('pie1') ), tt('pie2'), height = "250px")
             ),
             id='maintabs', selected=uiOutput( "dotchart" )
           )),
    column(width=4,
      tabsetPanel(
                tabPanel(uiOutput( "table2" ),
                           htmlOutput_p("serious", 
                                        tt( 'freqtab1'), 
                                        tt( 'freqtab2'))
                  ),
                tabPanel(uiOutput( "dotchart2" ),
                         withSpinner(plotOutput_p("seriousplot", 
                                        HTML( tt('dot1') ), tt('dot2'), 
                                        height = "250px"))
                ),
                tabPanel(uiOutput( "piechart2" ),
                           plotOutput_p("seriouspie", 
                                        HTML( tt('pie1') ), tt('pie2'), height = "250px")
                ),
                id='maintabs', selected=uiOutput( "dotchart2" )
                )
            ),
    column(width=4,
           tabsetPanel(
             tabPanel(uiOutput( "table3" ),
                        htmlOutput_p("sex", 
                                     tt( 'freqtab1'), 
                                     tt( 'freqtab2'))
             ),
             tabPanel(uiOutput( "dotchart3" ),
                        (withSpinner(plotOutput_p("sexplot", 
                                   HTML( tt('dot1') ), tt('dot2'),
                                   height = "250px")))
             ),
             tabPanel(uiOutput( "piechart3" ),
                        plotOutput_p("sexpie", 
                                     HTML( tt('pie1') ), tt('pie2'), height = "250px")
             ),
             id='maintabs', selected=uiOutput( "dotchart3" )
           )
           )
  ),
  fluidRow(
    column(width=12,
           HTML(paste('<h4>',uiOutput( "AdverseEventsConcomitantMedications" ),'</h4>', sep="")))
    ),
  fluidRow(
    column(width=9,
      tabsetPanel(


        tabPanel(uiOutput( "Events"), withSpinner(uiOutput("wordcloudtabset"))
                ),
        tabPanel(uiOutput("ConcomitantMedications"),
                 wordcloudtabset('cocloud', 'coquery', 
                 popheads=c( tt('codrug1'), tt('word1') ), poptext=c( tt('codrug2'), tt('word2') )
                 )
            ),
        tabPanel(uiOutput("Indications"),
                 wordcloudtabset('indcloud', 'indquery', 
                                 popheads=c( tt('indication1'), tt('word1') ), poptext=c( tt('indication2'), tt('word2') )
                 )
        )
        # tabPanel(uiOutput("Other Apps"),  
        #          wellPanel( 
        #            htmlOutput_p( 'applinks' )
        #          )
        # ),
        # tabPanel(uiOutput("DataReference"), HTML( renderiframe( "https://open.fda.gov/drug/event/") ) 
        # ),
        # tabPanel(uiOutput("About"), 
        #          # img(src='l_openFDA.png'),
        #          HTML( (loadhelp('about') ) )  )
        
      )
    ),
    column(width=3,
           bsAlert("alert") )
  )
)
)
