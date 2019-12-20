library(rsconnect)
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

shinyUI(fluidPage(
                  fluidRow(useShinyjs(),
                           column(width=6,
                                  titlePanel("RR-Drug" ),
                                  
                                  plotOutput_p("seriousplot",
                                               HTML( tt('dot1') ), tt('dot2'),
                                               height = "250px"),

                                 wellPanel(
                                   plotOutput_p( 'cpmeanplot' ),
                                   htmlOutput_p( 'cpmeantext' )
                                 )
                           ),
                                  
                    column(width=6,
                           titlePanel("RR-Drug" ) ,
                    
                    bsAlert("alert2"),
                    
                    hidden(
                      radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected='any'),
                      radioButtons('useexactD', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any'),
                      radioButtons('useexactE', 'Match event name:', c('Exactly'='exact', 'Any Term'='any'), selected = 'any' ),
                      
                      renderDates(),
                      
                      textInput_p("t2", "Adverse Events", '', 
                                  HTML( tt('eventname1') ), tt('eventname2'),
                                  placement='bottom'),
                      selectInput_p("v2", 'Time Variable' , c('receivedate', 'receiptdate'), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top', selected='receiptdate'), 
                      selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top'), 
                      textInput_p("t1", "Drug Name", '', 
                                  HTML( tt('drugname1') ), tt('drugname2'),
                                  placement='bottom'),
                      numericInput_p('maxcp', "Maximum Number of Change Points", 3, 1, step=1,
                                     HTML( tt('cplimit1') ), tt('cplimit2'),
                                     placement='bottom'),
                      
                      numericInput_p('limit', 'Maximum number of event terms', 50,
                                     1, 100, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom'), 
                      
                      numericInput_p('start', 'Rank of first event', 1,
                                     1, 999, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom'),
                      textInput_p("drugname", "Name of Drug", '', HTML( tt('drugname1') ), tt('drugname2'), placement='left'), textInput_p("eventname", "Adverse Events", '', 
                                                                                                                                           HTML( tt('eventname1') ), tt('eventname2'),
                                                                                                                                           placement='left'),              
                      numericInput_p('maxcp2', "Maximum Number of Change Points", 3, 1, , step=1,
                                     HTML( tt('cplimit1') ), tt('cplimit2'),
                                     placement='left'),
                      dateRangeInput('daterange', 'Use Reports Between: ', start = '1989-6-30', end = Sys.Date())
                    ),
                    
                    htmlOutput( 'prrtitle' ),
                    makeDataTableOutput( 'prr2' )
                    # tabPanel("PRR and ROR Results",
                    #          wellPanel(
                    #            htmlOutput( 'prrtitle' )
                    #          ),
                    #          #                          wordcloudtabset('cloudprr', 'prr', 
                    #          #                                          popheads=c( tt('prr1'), tt('word1') ), 
                    #          #                                          poptext=c( tt('prr5'), tt('word2') ) )
                    #          maketabset( c('prr2', 'cloudprr', 'textplot'), 
                    #                      types=c('datatable', "plot", 'plot'),
                    #                      names=c("Table","Word Cloud", "text Plot"), 
                    #                      popheads = c(tt('prr1'), tt('word1'), tt('textplot1') ), 
                    #                      poptext = c( tt('prr5'), tt('wordPRR'), tt('textplot2') ) )
                    # ),
                      
                      
                      
                    )
                  
                  
                  
        )
      )
    )
