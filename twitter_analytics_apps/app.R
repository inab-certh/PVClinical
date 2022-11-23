library(shiny)
library(shinyjs)
library(shinydashboard)
library(mongolite)
library(highcharter)
library(magrittr)
library(xts)
library(DT)
library(shinyBS)
library(shinyalert)
library(shinyWidgets)
library(shinycssloaders)
library(dplyr)
library(regexSelect)
library(digest)
library(viridis)
library("streamgraph")
library(stringr)
library(treemap)
library(tidyverse)
library(tidytext)
library(academictwitteR)
library(lubridate)
library(shinycustomloader)
library(stringi)
library(stringr)
library(yaml)
library(webshot2)

source("parseQueryFunction.R")



##################################################
## Project: Twitter data collection, analysis & visualisation
## Script purpose: Shiny app analytics for Twitter discourse using the Twitter V2 API
## Date: 12/7/2021
## Author: Christine Kakalou || ckakalou@certh.gr
##################################################



ui <- shinyUI(dashboardPage(
  skin = "black",
  dashboardHeader(disable = TRUE),
  dashboardSidebar(  disable = TRUE,
                     # Remove the sidebar toggle element
                     tags$script(JS("document.getElementsByClassName('sidebar-toggle')[0].style.visibility = 'hidden';"))),
  dashboardBody(
    fluidRow(
      tags$style(".small-box.bg-blue { background-color: #2b5763 !important; font-family: 'Helvetica Neue', Roboto, Arial, 'Droid Sans', sans-serif !important; color: #ffffff !important; }", HTML("
      @import url('https://fonts.googleapis.com/css2?family=Helvetica+Neue&display=swap');
      body {
        background-color: black;
        color: white;
      }
      h3 {
        font-family: 'Helvetica Neue', Roboto, Arial, 'Droid Sans', sans-serif;
      }
         p {
        font-family: 'Helvetica Neue', Roboto, Arial, 'Droid Sans', sans-serif;
         }
         h4 {
        font-family: 'Helvetica Neue', Roboto, Arial, 'Droid Sans', sans-serif;
      }
      .shiny-input-container {
        color: #474747;
      }")), tags$h1(), valueBoxOutput("tweetsNumber", width = 3 )
      , valueBoxOutput("RTNumber", width = 3 )
      , valueBoxOutput("duration", width = 3 )
      , valueBoxOutput("tweetsPerDay", width = 3 )
      ,  tags$br(),
      fluidRow(
        tabBox(
          title = tagList(shiny::icon("twitter")),
          id = "tabset1",
          height = "500px",
          width = 12
          ,
          tabPanel(
            "Timeline", 
            # textOutput(twitterQueryText),
            highchartOutput("timeline",height = "600px") %>% withLoader(loader = "loader6", proxy.height = "100px") %>% withSpinner(color="#2B5763", type = "7") 
            %>% withSpinner(color="#2B5763", type = "7")
            #   ,htmlwidgets::saveWidget(widget = timeline, file = "timeline.html"),
            #   webshot(url = "timeline.html",
            #           file = "timeline.png",
            #           delay=30)
          )
          ,
          tabPanel(style = "font-family: Helvetica Neue", "Raw Data", tags$h4(icon("binoculars"), "Explore the raw data"), tags$h2(),
                   dateRangeInput("dateRangeRaw", "Select date range:",
                                  start = "2006-03-26",
                                  end   = NULL),
                   # checkboxInput(inputId = "retweetFilter", label = "Remove retweets", value = FALSE),
                   DT::dataTableOutput("rawData") %>% withSpinner(color="#2B5763", type = "7"))
          
          ,
          # tabPanel("Hashtags", tags$h1(icon("hashtag"), "Track popular hashtags"), tags$h2(), streamgraphOutput("hashtagsStream"))
          # ,
          tabPanel("Authors", tags$h4(icon("pen-nib"), "Identify top 25 tweet authors"), tags$h2(), plotOutput("authorTreemap", width = "1000px", height = "900px")
          )
        )
      )
      
    ),
    
    # Add CSS files
    includeCSS(path = "www/AdminLTE.css"),
    includeCSS(path = "www/shinydashboard.css"),
  )
  
)
)


server <- function(input, output, session){
  config = read_yaml("config.yml")
  twitterBearer = config$TWITTER_BEARER
  cacheFolder = config$cacheFolder
  
  
  addClass(selector = "body", class = "sidebar-collapse")
  # twitterQuery <- "epoetin alfa end stage renal disease"
  hash = ""
  
  end_date = today() %>% toString() %>% paste0("T00:00:00Z")
  
  mainDataDirectory <- "data"
  
  if(file.exists(mainDataDirectory)){
    print("main data folder already exists")
  } else {
    dir.create(file.path(mainDataDirectory))
    print("created new directory")
  }
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    # browser()
    if (!is.null(query[['twitterQuery']])) {
      updateTextInput(session, "twitterQuery", query[['twitterQuery']])
      twitterQuery <<- query[['twitterQuery']]
    }
    
    if (!is.null(query[['hash']])) {
      updateTextInput(session, "hash", query[['hash']])
      hash <<- query[['hash']]
    }
    
  })
  twitterQueryREACTIVE <- reactive(twitterQuery)
  
  observe({
    print(twitterQueryREACTIVE())
    
  })
  
  hashREACTIVE <- reactive(hash)
  
  
  
  
  
  # Breakup query into 1020 char chunks
  
  query_clean.df <- reactive({parseQueryFunction(twitterQueryREACTIVE())})
  
  
  
  
  observe({
    if(file.exists( paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512")))){
      print("Query data folder already exists - Will empty now")
      unlink(paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512"),"/*"))
      
    } else {
      print("Will create new query data directory")
    }
    
    #
    # Collect tweets via the Full Archive Search using Twitter V2 API
    #
    
    for (row in 1:nrow(query_clean.df())){
      apiQuery <- query_clean.df()[row,1]
      
      tweets <- get_all_tweets(
        query = apiQuery,
        bearer_token = twitterBearer,
        start_tweets = "2006-03-27T00:00:00Z",
        end_tweets = end_date,
        file = digest(apiQuery, algo = "sha512"),
        data_path = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512")),
        n = 1000000
      )
    }
    
    
    
    queryPath = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512"))
    dataJSONPath = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512"), "/data_.json")
    usersJSONPath = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512"), "/users_.json")
    
    tweets_all <- bind_tweets(data_path = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512")))
    
    if(file.exists(paste0(queryPath,"/data_.json"))){
      print("empty data_.json file exists")
      file.remove(dataJSONPath)
      print("empty data_.json removed")
      file.remove(usersJSONPath)
      print("empty users_.json removed")
    } else {
    }
    
    
    if ((nrow(tweets_all)) > 0){
      
      tweets_all_tidy <- bind_tweets(data_path = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512")), output_format = "tidy")
      
      dataCollectionDuration <- as.data.frame(date(tweets_all_tidy$created_at[1])-date(tweets_all_tidy$created_at[nrow(tweets_all_tidy)]))
      
      ### -- Calculate Timeseries - ###
      
      tweets_all_tidy$created_at <- as.Date(tweets_all_tidy$created_at)
      tweets_original_tidy <- tweets_all_tidy %>% filter(is.na(tweets_all_tidy$'sourcetweet_type'))
      tweets_rts_tidy <- tweets_all_tidy %>% filter(!is.na(tweets_all_tidy$'sourcetweet_type'))
      
      xts_all <-  xts(rep(1, times = nrow(tweets_all_tidy)), tweets_all_tidy$created_at)
      xts_original <- xts(rep(1, times = nrow(tweets_original_tidy)), tweets_original_tidy$created_at)
      xts_rts <- xts(rep(1, times = nrow(tweets_rts_tidy)), tweets_rts_tidy$created_at)
      
      ts.sum.daily = apply.daily(xts_all, sum)
      ts.sum.daily_original=apply.daily(xts_original,sum)
      
      if (nrow(xts_rts)>0){
        ts.sum.daily_rts=apply.daily(xts_rts,sum)
      } else {
        # ts.sum.daily_rts <- ts.sum.daily_original %>% replace(ts.sum.daily_original$V1, 0)
      }
      
      
      
      streampal <- viridis_pal(option = "cividis")(15)
      
      ## Extract raw data  ##
      if (nrow(xts_rts)>0){
        raw_data.df <- tweets_all_tidy %>% select(text, created_at, sourcetweet_type, sourcetweet_text, user_name, user_username, tweet_id)
        raw_data.df <- raw_data.df %>% mutate(full_text = if_else(
          is.na(sourcetweet_type), text, sourcetweet_text
        ))
        raw_data.df$Date <- as.Date(raw_data.df$created_at)
        raw_data.df <- raw_data.df %>% mutate(tweet_url = paste0("https://twitter.com/", user_username, "/status/", tweet_id ))
        raw_data.df <- raw_data.df %>% select(full_text, created_at, sourcetweet_type, user_name, tweet_url)
        raw_data.df$tweet_url <- paste0("<a href=\"",raw_data.df$tweet_url, "\" target=\"_blank>\">", raw_data.df$tweet_url, "</a") 
        
        colnames(raw_data.df) <- c("Tweet Content", "Date", "is Retweet", "Tweet Author", "Link to tweet")
        raw_data.df$Date <- as.Date(raw_data.df$Date)
      } else{
        raw_data.df <- tweets_all_tidy %>% select(text, created_at, text, user_name, user_username, tweet_id)
        raw_data.df <- raw_data.df %>% mutate(full_text = text)
        raw_data.df$Date <- as.Date(raw_data.df$created_at)
        raw_data.df <- raw_data.df %>% mutate(tweet_url = paste0("https://twitter.com/", user_username, "/status/", tweet_id ))
        raw_data.df <- raw_data.df %>% select(full_text, created_at, user_name, tweet_url)
        raw_data.df$tweet_url <- paste0("<a href=\"",raw_data.df$tweet_url, "\" target=\"_blank>\">", raw_data.df$tweet_url, "</a") 
        
        colnames(raw_data.df) <- c("Tweet Content", "Date", "Tweet Author", "Link to tweet")
        raw_data.df$Date <- as.Date(raw_data.df$Date)
      }
      
      
      
      # ------ Enable regex search in datables -------
      options(DT.options = list(search = list(regex = TRUE, caseInsensitive = FALSE, search = ''),pageLength = 10))
      
      output$tweetsNumber <- renderValueBox({
        shinydashboard::valueBox(
          value = nrow(tweets_all_tidy),
          subtitle = "Tweets collected",
          icon = icon("twitter"),  color = 'blue'
        )
      })
      output$RTNumber <- renderValueBox({
        shinydashboard::valueBox(
          value = nrow(tweets_rts_tidy),
          subtitle = "Retweets",
          icon = icon("retweet"),  color = 'red'
        )
      })
      output$duration <- renderValueBox({
        shinydashboard::valueBox(
          value = dataCollectionDuration,
          subtitle = "Days collecting data",
          icon = icon("calendar-check"),  color = 'green'
        )
      })
      output$tweetsPerDay <- renderValueBox({
        shinydashboard::valueBox(
          value = round(nrow(tweets_all)/as.integer(dataCollectionDuration), digits = 3 ),
          subtitle = "Tweets/Day",
          icon = icon("calendar-check"),  color = 'teal'
        )
      })
      my_theme <- hc_theme(
        chart = list(
          style = list(
            fontFamily = '"Helvetica Neue", Roboto, Arial, "Droid Sans", sans-serif'
          )
        )
      )
      
      
      timelineHighChart <- reactive({
        if (nrow(xts_rts)>0){
          hchart(ts.sum.daily,type = "line", name = "All Tweets" , color = "#2b5763") %>% hc_add_series(ts.sum.daily_rts, name = "Retweets", type = "area", color = "#a2b1b6") %>% hc_add_series(ts.sum.daily_original, type = "area", name = "Original tweets", color = "#8ad1d7")  %>%   hc_title(text = "Timeline of Twitter activity") %>% hc_subtitle(text = "Original vs Retweets") %>% hc_yAxis(text="Number of Tweets") %>% hc_legend(enabled = TRUE) %>% hc_add_theme(my_theme) %>%   hc_exporting(
            enabled = TRUE, # always enabled
            filename = "custom-file-name"
          )
        } else{
          hchart(ts.sum.daily, type = "line", name = "All Tweets" , color = "#2b5763") %>% hc_add_series(ts.sum.daily_original, type = "area", name = "Original tweets", color = "#8ad1d7")  %>%  hc_title(text = "Timeline of Twitter activity") %>% hc_subtitle(text = "Original vs Retweets") %>% hc_yAxis(text="Number of Tweets") %>% hc_legend(enabled = TRUE) %>% hc_add_theme(my_theme) %>%   hc_exporting(
            enabled = TRUE, # always enabled
            filename = "custom-file-name"
          )
        }
      })
      
      
      
      output$timeline <- renderHighchart({
        #Plot Chart
        timelineHighChart()
      })
      
      
      
      
      raw_data_final.df <- reactive ({raw_data.df[which(raw_data.df$Date >= input$dateRangeRaw[1] & raw_data.df$Date <= input$dateRangeRaw[2]),] })
      
      output$rawData <- renderDataTable(raw_data_final.df() , escape = FALSE, options = list(search = list(regex = TRUE)))
      
      
      users_all <- bind_tweets(data_path = paste0("data/", digest(twitterQueryREACTIVE(), algo = "sha512")), user = TRUE)
      
      authorsDF_all <- users_all %>% select(username) %>% group_by(username) %>% summarise(count = n()) %>% arrange(desc(count))
      if (nrow(authorsDF_all) > 25){
        authorsDF <- authorsDF_all[1:25,]
      }else{
        authorsDF <- authorsDF_all
      }
      
      
      
      treemapToSave <- reactive ({ treemap(authorsDF, index="username", vSize="count", type="index", fontface.labels=c(1,1),  fontfamily.title = c('Helvetica Neue', 'Roboto', 'Arial', 'Droid Sans', 'sans-serif'),
                                           fontfamily.labels = c('Helvetica Neue', 'Roboto', 'Arial', 'Droid Sans', 'sans-serif'),
                                           fontfamily.legend = c('Helvetica Neue', 'Roboto', 'Arial', 'Droid Sans', 'sans-serif'), bg.labels=c("transparent"), fontsize.labels=c(14,12), fontcolor.labels = "#383838",inflate.labels=F, border.col=c("white","white"), border.lwds=c(4,2),
                                           palette = c("#bcd1d8","#73a8ae","#85f5ff","#eefdff","#858585"),
                                           title="Top authors in this discussion",                      # Customize your title
                                           fontsize.title=14) })
      
      output$authorTreemap <- renderPlot({ treemapToSave()
      })
  
      observe({
        if(hash!=""){
          
          fileNameTimeline <- file.path(cacheFolder,paste0(hashREACTIVE(),"_twitter_timeline"))
          print("filenameTimeline is: ")
          print(fileNameTimeline)
          if (file.exists(paste0(fileNameTimeline,".png"))) {
            #Delete file if it exists
            file.remove(paste0(fileNameTimeline,".png"))
          }
          
          htmlwidgets::saveWidget(widget =  timelineHighChart(), file = "timelineHighChart.html")
          webshot2::webshot(url = "timelineHighChart.html", file = paste0(fileNameTimeline, ".png"), zoom = 4, vheight = 500)
        }
        
      })
      
    }else
    {
      showModal(modalDialog(
        title = tags$h1(icon("twitter"), "No data to show", style = "color: #337AB8; font-size: 28px; font-family: 'Helvetica Neue', Roboto, Arial, 'Droid Sans', sans-serif;"),
        easyClose = FALSE,
        size = "m",
        tags$div("No tweets were found for this scenario.",
                 style = "color: #7387RC; font-size: 20px; font-family: 'Helvetica Neue', Roboto, Arial, 'Droid Sans', sans-serif;"),
        footer = NULL
      )
      )
      
    }
    
  })
}
shinyApp(ui, server)
