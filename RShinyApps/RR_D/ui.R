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
                  fluidRow(useShinyjs(), uiOutput('page_content'),
                    
                    column(width=12,
                           titlePanel("RR-Drug" ) ),
                    
                    bsAlert("alert2"),
                    
                    hidden(
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
                      
                      numericInput_p('limit', 'Maximum number of event terms', 50,
                                     1, 100, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom'), 
                      
                      numericInput_p('start', 'Rank of first event', 1,
                                     1, 999, step=1, 
                                     HTML( tt('limit1') ), tt('limit2'),
                                     placement='bottom')
                      
                    ),
                    tags$div(style='padding-left:40px',dateRangeInput('daterange', uiOutput('UseReportsBetween'), start = '1989-6-30', end = Sys.Date())),
                    tabsetPanel(
                      tabPanel(uiOutput("PRRRORResults"),
                               wellPanel(
                                 htmlOutput( 'prrtitle' )
                               ),
                               #                          wordcloudtabset('cloudprr', 'prr', 
                               #                                          popheads=c( tt('prr1'), tt('word1') ), 
                               #                                          poptext=c( tt('prr5'), tt('word2') ) )
                               maketabset( c('prr2', 'cloudprr', 'textplot'), 
                                           types=c('datatable', "plot", 'plot'),
                                           names=c("Table","Word Cloud", "text Plot"), 
                                           popheads = c(tt('prr1'), tt('word1'), tt('textplot1') ), 
                                           poptext = c( tt('prr5'), tt('wordPRR'), tt('textplot2') ) )
                      ),
                      tabPanel(uiOutput("AnalyzedEventCountsforSpecifiedDrug")   ,
                               wellPanel( 
                                 htmlOutput( 'alldrugtext' ),
                                 htmlOutput_p( 'queryalldrugtext' ,
                                               tt('gquery1'), tt('gquery2'),
                                               placement='bottom' )
                               ), 
                               wellPanel( 
                                 htmlOutput( 'querytitle' ), 
                                 #                          tableOutput("query"),
                                 htmlOutput_p( 'querytext' ,
                                               tt('gquery1'), tt('gquery2'),
                                               placement='bottom' )
                               ),
                               wordcloudtabset('cloudquery', 'specifieddrug2', 
                                               types= c('datatable', 'plot'), 
                                               popheads=c( tt('event1'), tt('word1') ), 
                                               poptext=c( tt('event2'), tt('word2') )
                               )
                      ),
                      tabPanel(uiOutput("AnalyzedEventCountsforAllDrugs"),
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
                               wordcloudtabset('cloudall', 'all2',  
                                               types= c('datatable', 'plot'),
                                               popheads=c( tt('event1'), tt('word1') ), 
                                               poptext=c( tt('event2'), tt('word2') ))
                      ),
                      tabPanel(uiOutput("RankedEventCountsforDrug"),
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
                               wordcloudtabset('cloudcoqueryE', 'coqueryE2',
                                               types= c('datatable', 'plot'), 
                                               popheads=c( tt('codrug1'), tt('word1') ), 
                                               poptext=c( tt('codrug3'), tt('word2') ))
                      ),
                      tabPanel(uiOutput("CountsForDrugsInSelectedReports"),
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
                                               types= c('datatable', 'plot'), 
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
                               wordcloudtabset('cloudindquery', 'indquery2',
                                               types= c('datatable', 'plot'), 
                                               popheads=c( tt('indication1'), tt('word1') ),
                                               poptext=c( tt('indication2'), tt('word2') ) )
                      ),
                      tabPanel(uiOutput("OtherApps"),  
                               wellPanel( 
                                 htmlOutput( 'applinks' )
                               )
                      ),
                      tabPanel(uiOutput("DataReference"), HTML( renderiframe('https://open.fda.gov/drug/event/') )  ),
                      tabPanel(uiOutput("About"), 
                               # img(src='l_openFDA.png'),
                               HTML( (loadhelp('about') ) )  ),
                      #                 tabPanel("session",  
                      #                          wellPanel( 
                      #                            verbatimTextOutput( 'urlquery' )
                      #                          )
                      #                 ),
                      id='maintabs', selected=  uiOutput("PRRRORResults") 
                  ),
#   img(src='l_openFDA.png'),
#   titlePanel("RR-Drug"),
#   sidebarLayout(
#     sidebarPanel(
# #       tabsetPanel(
# #         tabPanel('Select Drug',
#                    )
#         ,
# #     id='sidetabs', selected='Select Drug')
# #     ),
#     mainPanel(
#       
#             )
#           )
        )
      )
    )
