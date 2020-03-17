library(rsconnect)
library(shinyjs)
library(shinycssloaders)

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
                    
                    column(width=12,
                           # titlePanel("RR-Drug" ) 
                           ),
                    
                    bsAlert("alert2"),
                    
                    hidden(
                      uiOutput('page_content'),
                      
                      radioButtons('useexact', 'Match drug name:', c('Exactly'='exact', 'Any Term'='any'), selected='any'),
                      
                      renderDates(),
                      
                      selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top'), 
                      selectInput_p("v1", 'Drug Variable' ,getdrugvarchoices(), 
                                    HTML( tt('drugvar1') ), tt('drugvar2'),
                                    placement='top'), 
                      textInput_p("t1", "Drug Name", '', 
                                  HTML( tt('drugname1') ), tt('drugname2'),
                                  placement='bottom'), 
                      textInput_p("lang", "lang", '', 
                                  HTML( tt('en') ), tt('gr'),
                                  placement='bottom'),
                      
                      numericInput_p('limit', 'Maximum number of event terms', 50,
                                     1, 100, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom'), 
                      
                      numericInput_p('start', 'Rank of first event', 1,
                                     1, 999, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom')
                      
                    ),
                    tags$div(style='padding-left:40px',dateRangeInput('daterange', "", start = '1989-6-30', end = Sys.Date())),
                    tabsetPanel(
                      tabPanel(uiOutput("PRRRORResults"),
                               wellPanel(
                                 style="background-color:white;height:60px;border:none",uiOutput( 'prrtitleBlank' ),uiOutput("infoprr2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               dataTableOutput( 'prr2' )
                      ),
                      tabPanel(uiOutput("AnalyzedEventCountsforSpecifiedDrug")   ,
                               wellPanel(
                                 style="background-color:white;height:60px;border:none",uiOutput("infospecifieddrug2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               dataTableOutput( 'specifieddrug2' )
                      ),
                      tabPanel(uiOutput("AnalyzedEventCountsforAllDrugs"),
                               wellPanel(
                                 style="background-color:white;height:60px;border:none",uiOutput("infoall2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               dataTableOutput( 'all2' )
                      ),
                      tabPanel(uiOutput("RankedEventCountsforDrug"),
                               wellPanel(
                                 style="background-color:white;height:60px;border:none",uiOutput("infocoqueryE2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               dataTableOutput( 'coqueryE2' )
                      ),
                      tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
                               wellPanel(
                                 style="background-color:white;height:60px;border:none",uiOutput("infocoquery2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               dataTableOutput( 'coquery2' )
                      ),
                      tabPanel(uiOutput("CountsForIndicationsInSelectedReports"),
                               wellPanel(
                                 style="background-color:white;height:60px;border:none",uiOutput("infoindquery2",style = "position:absolute;right:40px;z-index:10")
                               ),
                               dataTableOutput( 'indquery2' )
                      ),
                      id='maintabs', selected=  uiOutput("PRRRORResults") 
                    ),
                      

        )
      )
    )
