library(shiny)
require(shinyBS)
library(shinycssloaders)
library(shinyjs)
library(plotly)
library(DT)

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
shinyUI(fluidPage( includeCSS("../sharedscripts/custom.css"),
                  fluidRow(useShinyjs(),column(width=12,
                    column(width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dl", textOutput("downloadBtnLbl")))))),
                  ),
                  fluidRow(useShinyjs(),column(width=12,bsAlert("nodata_dash"))),
                   fluidRow(useShinyjs(),
                     column(width=4,
                            # a(href='https://open.fda.gov/', 
                            #   img(src='l_openFDA.png', align='bottom')),
                            # renderDates()
                            # dateRangeInput(
                            #   'daterange','',
                            #   # uiOutput('UseReportsBetween'),
                            #   start = '1989-6-30',
                            #   end = Sys.Date()
                            # ),
                            # uiOutput("daterange"),
                     ),
                     column(width=8,
                            titlePanel("" ) )
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
    column(width=4,
           withSpinner(plotlyOutput("sourceplot"))
           
           ),
    column(width=4,
           withSpinner(plotlyOutput("seriousplot"))
            ),
    column(width=4,
           withSpinner(plotlyOutput("sexplot"))
           )
  ),
  fluidRow(
    column(width=12,style = "height:20px;")
    ),
  fluidRow(id="maintabs",
    column(width=9,
      tabsetPanel(

        tabPanel(uiOutput( "Events"), makeDataTableOutput('query')
                 # withSpinner(uiOutput("wordcloudtabset"))
                ),
        tabPanel(uiOutput("ConcomitantMedications"),
                 makeDataTableOutput('coquery')
                 
            ),
        tabPanel(uiOutput("Indications"),makeDataTableOutput('indquery')
                 
        )
        
        
      )
    ),
    column(width=3,
           "" )
  )
)
)
