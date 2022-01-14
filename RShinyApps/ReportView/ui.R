library(shiny)
library(shinyjs)

library(shiny.i18n)
library(shinyalert)

source('sourcedir.R')


getchoices <- function(){
  othervars <- c( 'Any Variable',  '_exists_')
  
  openfdavars <-  getallvars( allvars(), mytype = 'text', section= c('of', 'o2'))
  openfdavars <-  paste0( 'patient.drug.openfda.', openfdavars )
  
  headervars <- getallvars( allvars(), mytype = 'text', section= c('rh', 'se' ))
  
  patientvars <- getallvars( allvars(), mytype = 'text', section= c('pt', 'na'))
  patientvars <-  paste0( 'patient.', patientvars )
  
  drugvars <- getallvars( allvars(), mytype = 'text', section= c('dr', 'as'))
  drugvars <-  paste0( 'patient.drug.', drugvars )
  
  reactionvars <- getallvars( allvars(), mytype = 'text', section= c('re'))
  reactionvars <-  paste0( 'patient.reaction.', reactionvars )

  exactvars <- paste0( c( getdrugvarchoices(), 'patient.reaction.reactionmeddrapt' ), '.exact')
  
  s <- c(othervars, openfdavars, headervars,  patientvars, drugvars, reactionvars, exactvars)
  return(s)
}

getdatechoices <- function(){
  s <- c( 'receiptdate','receivedate' )
  return(s)
}

rendercurrec <- function() { 
  
  uiOutput('currec') 
  
} 
renderrepportid <- function() { 
  
  uiOutput('reportid') 
  
} 

renderv1 <- function() { 
  
  ( htmlOutput('v1') )
  
} 
renderv2 <- function() { 
  
  ( htmlOutput('v2') )
  
}  
renderv3 <- function() { 
  
  ( htmlOutput( 'v3' ) )
  
} 
rendert1 <- function() { 
  
  ( htmlOutput('t1') )
  
} 
rendert2 <- function() { 
  
  ( htmlOutput('t2') )
  
}  
rendert3 <- function() { 
  
  ( htmlOutput( 't3' ) )
  
} 


shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
                  fluidRow(useShinyjs(),useShinyalert(),
                           column(width=12, bsAlert("nodata_report")), id='alertrow'),
                  fluidRow(useShinyjs(),
                    column(width=3,
                           # a(href='https://open.fda.gov/', 
                           #   img(src='l_openFDA.png', align='bottom')),
                           #renderDates()
                    ),
                    column(width=8,
                           titlePanel(
                             textOutput("paneltitle"),
                             "")) 
                    , id='titlerow'),
#                   img(src='l_openFDA.png'),
#   titlePanel("Report Browser"),
#   fluidRow(
#     column(width=4,
#            wellPanel( 
#              selectizeInput('v1', 'Variable 1', getchoices() , width='100%', 
#                             selected=getchoices()[2], options=list(create=TRUE, maxOptions=1000) ),
#              textInput("t1", "Terms", '')
#            )
#     ),
#     
#     column(width=4,
#            wellPanel( 
#              selectizeInput('v2', 'Variable 2', getchoices() , width='100%', 
#                             selected=getchoices()[1], options=list(create=TRUE, maxOptions=1000) ),
#              textInput("t2", "Terms", '')
#              #Haemoglobinuria
#            )
#     ),
#     column(width=4,
#            wellPanel( 
#              selectizeInput("v3", "Variable 3", c( getdatechoices(), getchoices() ) , width='100%', 
#                             selected=getdatechoices()[1] , options=list(create=TRUE, maxOptions=1000) ), 
#              textInput("t3", "Terms", paste0('[19060630+TO+', format(Sys.Date(), '%Y%m%d'), ']') )
#            )
#     )
#   ),
  fluidRow(useShinyjs(), style="margin-bottom: 0.3rem",
    column(width=2, bsButton( 'prevrow', '< Previous', block=TRUE, style = 'primary') ),
    column(width=2, htmlOutput("ptext") ),
    column(width=4, 
           strong( rendercurrec() ) ),
    column(width=2, htmlOutput("ntext") ),
    column(width=2, bsButton( 'nextrow', 'Next >', block=TRUE, style = 'primary') )
    , id='navrow'),
  fluidRow(useShinyjs(),
    column(width=12, 
           wellPanel( 
             fluidRow(column(width=8, tableOutput( 'patienttable' ),),
             # htmlOutput( 'overviewtitle' ), 
             column(width=4, 
                    fluidRow(column(width=6,textInput("safetyreportid", "Safety Report Id", "")),
                             column(width=5,bsButton( 'searchID', 'Search ID', block=TRUE, style = 'primary'),
                                    style="margin-top: 2.45rem;"),),
                    tableOutput('reporttable'),),
             style = "max-height: 600px;",
             
             # style="float: right;"
             hidden(sliderInput('skip', 'Report #', value=1, min=1, step= 1, max=100, width='100%'))
           )
           )
    )
    , id='sliderrow'),
fluidRow(column(width=2, downloadButton( 'downloadData', 'Download report', 
                                         block=TRUE) ),
         style= " margin-bottom: 0.3rem; float:right;",
         ),
fluidRow(column(width=2, downloadButton( 'downloadAllData', 'Download all reports', 
                                         block=TRUE) ),
         style= " margin-bottom: 0.3rem; float:right;",
),
fluidRow(useShinyjs(),
         hidden(column(width=3,
         wellPanel(
           
           style = "max-height: 600px",
           bsButton("tabBut", "Filter by...", style='primary'),
           br(),
           renderv1(),
           rendert1(),
           conditionalPanel(
             condition = "1 == 2",
             selectizeInput('v1', 'Variable 1', getchoices() , width='100%', 
                            selected=getchoices()[1], options=list(create=TRUE, maxOptions=1000) ),
             textInput("t1", "Terms", '')
           )
           ,
           # uiOutput("variablesModal")
           bsModal( 'modalUpdateVars', textOutput("variablesmodal"), "tabBut", size = "large",
                    htmlOutput('mymodal'), 
                    selectizeInput('v1_2', tags$div(HTML(paste(textOutput("variablelbl1", inline=TRUE), tags$span('1'))), style = "display: inline;"), getchoices() , width='100%', 
                                   selected=getchoices()[1], options=list(create=TRUE, maxOptions=1000) ),
                    textInput("t1_2", textOutput("termslbl1"), ''),
                    selectizeInput('v2_2', tags$div(HTML(paste(textOutput("variablelbl2", inline=TRUE), tags$span('2'))), style = "display: inline;"), getchoices() , width='100%',
                                   selected=getchoices()[1], options=list(create=TRUE, maxOptions=1000) ),
                    textInput("t2_2", textOutput("termslbl2"), ''),
                    selectizeInput("v3_2", tags$div(HTML(paste(textOutput("variablelbl3", inline=TRUE), tags$span('3'))), style = "display: inline;"), c( getdatechoices(), getchoices() ) , width='100%',
                                   selected='effective_time' , options=list(create=TRUE, maxOptions=1000) ),
                    textInput("t3_2", textOutput("termslbl3"), '[20000101+TO+20170101]'),
                    bsButton("update", "Update Variables", style='primary') )
         ,
         # tableOutput( 'patienttable' ),
         tags$script(
           "$( document ).ready(function() {
              $('#modalUpdateVars .modal-footer .btn-default').attr('id', 
              'modalCloseBtn');
           })")
          
         
         ),
         
         
         wellPanel( 
           style = "overflow-y:scroll; max-height: 600px",
           renderv2(),
           rendert2(),
           conditionalPanel(
             condition = "1 == 2",
             selectizeInput('v2', 'Variable 2', getchoices() , width='100%', 
                            selected=getchoices()[1], options=list(create=TRUE, maxOptions=1000) ),
             textInput("t2", "Terms", '')
           )
         ),
         wellPanel( 
           style = "overflow-y:scroll; max-height: 600px",
           renderv3(),
           rendert3(),
           conditionalPanel(
             condition = "1 == 2",
             selectizeInput("v3", "Variable 3", c( getdatechoices(), getchoices() ) , width='100%', 
                            selected='effective_time' , options=list(create=TRUE, maxOptions=1000) ), 
             textInput("t3", "Terms", paste0('[19060630+TO+', format(Sys.Date(), '%Y%m%d'), ']') )
           )
         ),
         # bsAlert("alert")
  )),
  column(width=12, 
         bsAlert("alert2"),  
      tabsetPanel(
                # tabPanel(textOutput("overviewtxt"),  
                #          uiOutput("sourceReportframe", style = "display:inline-block; margin-left:20px;"),
                #          wellPanel( 
                #            htmlOutput( 'overviewtitle' ), 
                #            tableOutput( 'overviewtable' ),
                #            style = "overflow-y:scroll; max-height: 600px",
                #          )
                # ),
                # tabPanel(textOutput("metadatatxt"),
                #         
                #          wellPanel( 
                #            htmlOutput( 'querytitle' ), 
                #            htmlOutput( 'metatext' ), 
                #            htmlOutput( 'json' ),
                #            style = "overflow-y:scroll; max-height: 600px",
                #          )
                # ),
                # tabPanel(textOutput("reportheadertxt"), 
                #          
                #          wellPanel(  
                #            htmlOutput( 'headertabletitle' ), 
                #            tableOutput("headertable"),
                #            hr(),
                #            htmlOutput('receivertabletitle'),
                #            tableOutput("receiver"),
                #            hr(),
                #            
                #            htmlOutput('reportduplicatetabletitle'),
                #            tableOutput("reportduplicate"),
                #            hr(),
                #            
                #            htmlOutput('sendertabletitle'),
                #            tableOutput("sender"),
                #            hr(),
                #            
                #            htmlOutput('primarysourcetabletitle'),
                #            tableOutput("primarysource"),
                #            style = "overflow-y:scroll; max-height: 600px"
                #          )
                # ),
                # tabPanel(textOutput("patienttxt"),  
                #          
                #          wellPanel( 
                #            htmlOutput('patienttabletitle'),
                #            htmlOutput( 'patient' ),
                #            style = "overflow-y:scroll; max-height: 600px",
                #          )
                # ),
                tabPanel(textOutput("patreactiontxt"),  
                         uiOutput("sourcePatientDataframe", style = "display:inline-block; margin-left:20px;"),
                         wellPanel( 
                           htmlOutput('patientreactiontabletitle'),
                           htmlOutput( 'patientreaction'),
                           style = "overflow-y:scroll; max-height: 600px"
                         )
                ),
                tabPanel(textOutput("patdrugtxt"),
                         uiOutput("sourceDrugDataframe", style = "display:inline-block; margin-left:20px;"),
                         wellPanel(  
                           # htmlOutput('patientdrugtabletitle'),
                           htmlOutput( 'drug' ),
                           style = "overflow-y:scroll; max-height: 600px"
                         )
                ),
                tabPanel(textOutput("patdrugopenfdatxt"),
                         fluidRow(
                           column(width=4,
                                  uiOutput("sourceFdaDataframe", style = "display:inline-block; margin-left:20px;"),
                                  
                           ),
                           column(width=4,
                                  uiOutput("sourceFdaSDataframe", style = "display:inline-block; margin-left:20px;"),
                           ),
                         ),
                        
                         wellPanel(  
                                     tableOutput('medication'),
                                     # htmlOutput('patientdrugopenfdatabletitle'),
                                     # tableOutput( 'openfda' ),
                                     # htmlOutput('patientdrugopenfda2tabletitle'),
                                     # tableOutput( 'openfda2' ),
                                     style = "overflow-y:scroll; max-height: 600px"
                         )
                ),
                # tabPanel("Other Apps",  
                #          wellPanel( 
                #            htmlOutput( 'applinks' )
                #          )
                # ),
                # tabPanel('Data Reference', HTML( renderiframe( "https://open.fda.gov/drug/event/") ) 
                # ),
                # tabPanel('About',
                #          img(src='l_openFDA.png'),
                #          HTML( (loadhelp('about') ) )  ),
              id='maintabs'
            )
        )
  , id='mainrow'),
  id='mainpage'
  )
)