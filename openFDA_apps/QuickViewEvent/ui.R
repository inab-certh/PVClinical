library(rsconnect)
library(shinyjs)
library(shiny)
library(shinyWidgets)
library(DT)
library(shinycssloaders)


options(encoding = 'UTF-8')


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
countries <- c("en", "gr")

flags <- c(
  "https://cdn.rawgit.com/lipis/flag-icon-css/master/flags/4x3/gb.svg",
  "https://cdn.rawgit.com/lipis/flag-icon-css/master/flags/4x3/gr.svg"
)

shinyUI(fluidPage(includeCSS("../sharedscripts/custom.css"),
                  fluidRow(useShinyjs(),
                           column(id="xlsrow", width=8,div(div(style="display:inline-block",div(id="downloadExcelColumn",textOutput("downloadDataLbl"))),div(style="display:inline-block; margin-left:20px;",downloadButton("dl", textOutput("downloadBtnLbl")))))),
                  fluidRow(useShinyjs(),
                           column(width=12,bsAlert("nodata_qve"),uiOutput("info",style = "position:absolute;right:40px;z-index:10"))),
                                  # titlePanel("RR-Drug" ) ,
                                  fluidRow(useShinyjs(),
                                           column(width=12,style="margin-top:60px;",
                                                  # dateRangeInput(
                                                  #   'daterange',
                                                  #   uiOutput('UseReportsBetween'),
                                                  #   start = '1989-6-30',
                                                  #   end = Sys.Date()
                                                  # ),
                                                  dateRangeInput('daterange', '', start = '1989-6-30', end = Sys.Date(), language="en", separator="to" ),
                                                  uiOutput("dtlocator"),
                                                  uiOutput('prrtitleBlank'),
                                            withSpinner(makeDataTableOutput( 'prr2' )))),
                                  #htmlOutput( 'prrtitle' ),
                                  
                                  hidden(
                                    uiOutput('page_content'),
                                    
                                    textInput_p(
                                      "t1",
                                      "Adverse Reaction",
                                      '',
                                      HTML(tt('eventname1')),
                                      tt('eventname2'),
                                      placement = 'bottom'
                                    ),
                                    textInput_p("lang", "lang", '', 
                                                HTML( tt('en') ), tt('gr'),
                                                placement='bottom'),
                                    selectInput_p("v1", 'Drug Variable' , getdrugvarchoices(),
                                                  #                                               HTML( tt('drugvar1') ), tt('drugvar2'),
                                                  placement = 'top'),
                                    
                                    numericInput_p(
                                      'limit',
                                      'Maximum number of drugs',
                                      50,
                                      1,
                                      100,
                                      step = 1,
                                      HTML(tt('limit1')),
                                      tt('limit2'),
                                      placement = 'bottom'
                                    ),
                                    
                                    numericInput_p(
                                      'start',
                                      'Rank of first event',
                                      1,
                                      1,
                                      999,
                                      step = 1,
                                      HTML(tt('limit1')),
                                      tt('limit2'),
                                      placement = 'bottom'
                                    ),
                                    textInput_p(
                                      "drugname",
                                      "Adverse Reaction",
                                      '',
                                      HTML(tt('eventname1')),
                                      tt('eventname2'),
                                      placement = 'left'
                                    ),
                                    
                                    numericInput_p(
                                      'limit2',
                                      'Maximum number of drugs',
                                      50,
                                      1,
                                      100,
                                      step = 1,
                                      HTML(tt('limit1')),
                                      tt('limit2'),
                                      placement = 'left'
                                    ),
                                    
                                    numericInput_p(
                                      'start2',
                                      'Rank of first event',
                                      1,
                                      1,
                                      999,
                                      step = 1,
                                      HTML(tt('limit1')),
                                      tt('limit2'),
                                      placement = 'bottom'
                                    ),
                                    radioButtons(
                                      'useexact',
                                      'Match Event Term:',
                                      c('Exactly' = 'exact', 'Any Term' = 'any'),
                                      selected = 'any'
                                    )
                                    
                                  ),
                                  
                           )
                           
                  )

