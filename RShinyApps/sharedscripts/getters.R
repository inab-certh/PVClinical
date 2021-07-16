

getterm1 <- function( session, quote=FALSE, upper=TRUE){
  s <- session$input$t1
  if( upper )
    {
    s <- toupper( s )
    }
  if (s == '')
  {
    return( '' )
  }
  if (quote){
    s <-  gsub('"', '', s , fixed=TRUE)
    return(paste0('"', s, '"'))
    return(paste0('%22', s, '%22'))
  } else {
    return( s )
  }
  names <- s
  names <- paste0( names, collapse=' ')
  return( names )
}

getterm2 <- function( session, quote=FALSE){
  s <- toupper( session$input$t2 )
  if (s == '')
  {
    return( '' )
  }
  if (quote){
    s <-  gsub('"', '', s , fixed=TRUE)
    return(paste0('%22', s, '%22'))
  } else {
    return( s )
  }
  names <- s
  names <- paste0( names, collapse=' ')
  return( names )
}

getlimit <- function( session ){ 
  return(session$input$limit)
}

getnumsims <- function( session ){ 
  return(session$input$numsims)
}

getstart <- function( session ){
  return(session$input$start)
}

tableout <- function( mydf, mynames=NULL, error)
  { 
  if ( length(mydf) > 0 )
  {
    if (!is.null(mynames))
    {
      names(mydf) <- mynames
    }
    return(mydf) 
  } else  {return(data.frame(Term=error, Count=0))}
}

cloudout <- function(mydf, title)
  {
  if ( is.data.frame(mydf) )
  {
    mydf <- mydf[ 1:min( 100, nrow(mydf) ), ]
    return( getcloud(mydf,  title = title ) )  
  } else  {
    return( data.frame( error) )
  }
  
  
}
getcounts999fda <- function( session, v, t, count, limit=1000,
                         exactrad='exact', counter=1, db= '/drug/',eventName=NULL )
  {
  if ( is.null( t ) ){
    return(data.frame( c( paste('Please enter a', getsearchtype(), 'name') , '') ) )
  }
  # browser()
  #Can we find exact name?
  if ( exactrad=='exact' )
  {
    exact <- TRUE
#    t <- paste0('%22', t, '%22')
    myurl <- buildURL(v = v, t= t,
                      count = count, limit=limit, db= db, addplus = FALSE  )
    mylist <- fda_fetch_p( session, myurl,  message = counter, flag=paste( 'No Reports for', t, '<br>' ) )

  } else {
    #No, can we find close name?
    exact <- FALSE
    v <- sub('.exact', '', v, fixed=TRUE)
    myurl <- buildURL(v= v, t=t,
                      count=count,limit=limit, db= db)
    mylist <- fda_fetch_p( session, myurl,  message = counter, flag=paste( 'No Reports for', t, '<br>' ) )
  }
  mydf <- mylist$result
  # browser()

  excludeddf <- data.frame()
  if( length(mydf)>0 )
    {
    mydfsource <- mylist$result
#    browser()
    caretrow <- which(grepl('^', mydfsource[,'term'], fixed=TRUE) )
    if (length(caretrow) > 0)
    {
      excludeddf <- mydfsource[ caretrow, ]
      mydf <- mydfsource[-caretrow, ]
    }
    aposrow <- which(grepl("'", mydf[,'term'], fixed=TRUE) )
    if (length(aposrow) > 0)
    {
      excludeddf <- rbind( excludeddf, mydf[ aposrow, ] )
      mydf <- mydf[ -aposrow, ]
    }
    slashrow <- which(grepl("/", mydf[,'term'], fixed=TRUE) )
    if (length(slashrow) > 0)
    {
      excludeddf <- rbind( excludeddf, mydf[ slashrow, ] )
      mydf <- mydf[ -slashrow, ]
    }
    commarow <- which(grepl(",", mydf[,'term'], fixed=TRUE) )
    if (length(commarow) > 0)
    {
      excludeddf <- rbind( excludeddf, mydf[ commarow, ] )
      mydf <- mydf[ -commarow, ]
    }
    if (length(excludeddf) > 0 )
      {
      names(excludeddf) <- c( "Terms that contain '^',  '/',  ','  or ' ' ' can't be analyzed and are excluded", 'count' )
      }
  } else {
    excludeddf <- mydf
  }
  # max <- min(100, nrow(mydf) )
  max <- nrow(mydf)
  # max <- min(900, nrow(mydf) )
  
  if (!is.null(eventName)){
    mydf<-mydf[which(mydf$term==eventName),]
  }
  else {
    mydf<-mydf[1:max,]
  }

  return( list(mydf=mydf, myurl=myurl, exact = exact, excludeddf = excludeddf   ) )
}

# Refactor
getcounts999 <- function( session, v, t, count, limit=1000, 
                          exactrad='exact', counter=1, db= '/drug/',eventName=NULL  )
{
  if ( is.null( t ) ){
    return(data.frame( c( paste('Please enter a', getsearchtype(), 'name') , '') ) )
  }
  # browser()
  #Can we find exact name?
  #   if ( exactrad=='exact' )
  #   {
  #     exact <- TRUE
  # #    t <- paste0('%22', t, '%22')
  #     myurl <- buildURL(v = v, t= t, 
  #                       count = count, limit=limit, db= db, addplus = FALSE  )
  #     mylist <- fda_fetch_p( session, myurl,  message = counter, flag=paste( 'No Reports for', t, '<br>' ) )
  #     browser()
  #   } else {
  #     #No, can we find close name?
  #     exact <- FALSE
  #     v <- sub('.exact', '', v, fixed=TRUE)
  #     myurl <- buildURL(v= v, t=t, 
  #                       count=count,limit=limit, db= db)
  #     mylist <- fda_fetch_p( session, myurl,  message = counter, flag=paste( 'No Reports for', t, '<br>' ) )
  #     browser()
  #   }
  #   mydf <- mylist$result
  # browser()
  # Refactor
  if ( v[2] == "patient.reaction.reactionmeddrapt.exact"){
    # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    eventName<-unlist(strsplit(t[2], '\\"'))[2]
    if (is.na(eventName) ){
      eventName <-unlist(strsplit(t[2], '\\"'))[1]
    }
    drugName<-NULL
    eventQuery<-totalDrugsInEventReports(eventName=eventName, input$date1, input$date2)
    eventResult <- con$aggregate(eventQuery)
    colnames(eventResult)[1]<-"term"
    
    mydf<-eventResult
    
    
  } else {
    # con <- mongo("fda", url = "mongodb://127.0.0.1:27017/medical_db")
    con <- mongo("dict_fda", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    drugName<-unlist(strsplit(t[2], '\\"'))[2]
    
    drugQuery<-totalEventsInReports(drugName=drugName, input$date1, input$date2)
    drugResult <- con$aggregate(drugQuery)
    colnames(drugResult)[1]<-"term"
    
    mydf<-drugResult
  }
  con$disconnect()
  # browser()
  
  
  # mydf <- data.frame(mydf, cumsum= cumsum(mydf[,2]))
  # Redone
  
  
  #   excludeddf <- data.frame()
  #   if( length(mydf)>0 )
  #     {
  #     mydfsource <- mylist$result
  # #    browser()
  #     caretrow <- which(grepl('^', mydfsource[,'term'], fixed=TRUE) )
  #     if (length(caretrow) > 0)
  #     {
  #       excludeddf <- mydfsource[ caretrow, ] 
  #       mydf <- mydfsource[-caretrow, ]
  #     }
  #     aposrow <- which(grepl("'", mydf[,'term'], fixed=TRUE) )
  #     if (length(aposrow) > 0)
  #     {
  #       excludeddf <- rbind( excludeddf, mydf[ aposrow, ] )
  #       mydf <- mydf[ -aposrow, ]
  #     }
  #     slashrow <- which(grepl("/", mydf[,'term'], fixed=TRUE) )
  #     if (length(slashrow) > 0)
  #     {
  #       excludeddf <- rbind( excludeddf, mydf[ slashrow, ] )
  #       mydf <- mydf[ -slashrow, ]
  #     }
  #     commarow <- which(grepl(",", mydf[,'term'], fixed=TRUE) )
  #     if (length(commarow) > 0)
  #     {
  #       excludeddf <- rbind( excludeddf, mydf[ commarow, ] )
  #       mydf <- mydf[ -commarow, ]
  #     }
  #     if (length(excludeddf) > 0 )
  #       {
  #       names(excludeddf) <- c( "Terms that contain '^',  '/',  ','  or ' ' ' can't be analyzed and are excluded", 'count' )
  #       }
  #   } else {
  #     excludeddf <- mydf
  #   }
  # max <- min(100, nrow(mydf) )
  max <- nrow(mydf)
  # max <- min(900, nrow(mydf) )
  if (!is.null(eventName) && !is.null(drugName)){
    con_med <- mongo("medra", url = "mongodb://sdimitsaki:hXN8ERdZE6yt@83.212.101.89:37777/FDAforPVClinical?authSource=admin")
    event <- con_med$find(paste0('{"code" : "',eventName,'"}'))
    con_med$disconnect()
    eventName = toupper(event$names[[1]][1])
    mydf<-mydf[which(mydf$term==eventName),]
  }
  else {
    mydf<-mydf[1:max,]
  }
  
  return( list(mydf=mydf) )
}
# Redone
