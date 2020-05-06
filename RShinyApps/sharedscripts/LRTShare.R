popprr <- function()
{
  text <- "Likelihood ratio test results for most common terms."
  head <- paste("LRT Results")
  return( c(head=head, text=text) )
}
popcloudprr <- function()
{
  text <- "Size of words are proportional to the LRT value of the word."
  head <- "Wordcloud of LRT Results"
  return( c(head=head, text=text) )
}
poptextplot <- function()
{
  head <- "Text Plot"
  text <- "Plot of number of events and LRT value for terms.  Selecting a region of terms displays a table of the selected terms"
  return( c(head=head, text=text) )
}

popAnalyzedEventCountsforDrug <- function()
{
  text <- "Analyzed Event Counts for Drugs"
  head <- "Frequency Table"
  return( c(head=head, text=text) )
}

popcloudAnalyzedEventCountsforDrug <- function()
{
  text <- "Wordcloud of Analyzed Event Counts for Drugs"
  head <- "Word Cloud"
  return( c(head=head, text=text) )
}

popcloudall <- function()
{
  text <- "Wordcloud for All Event Counts for Drugs"
  head <- "Word Cloud"
  return( c(head=head, text=text) )
}

popall <- function()
{
  text <- "All Counts for Drugs"
  head <- "Frequency Table"
  return( c(head=head, text=text) )
}


popcloudcoquery <- function()
{
  text <- "Size of words are proportional to the frequency of the word."
  head <- 'Word Cloud' 
  return( c(head=head, text=text) )
}


popcoquery <- function()
{
  text <- 'Frequency table for drugs found in selected reports. Drug name is linked to LRT results for drug \"L\" is linked to SPL labels for drug in openFDA. \"D\" is linked to a dashboard display for the drug.'
  head <- 'Concomitant Medications'
  return( c(head=head, text=text) )
}

popquery <- function()
{
  text <- 'Frequency table of events found in selected reports.  Event term is linked to PRR results for the event. "M" is linked to medline dictionary definition for event term'
  head <- 'Reported Events'
  return( c(head=head, text=text) )
}

popcoqueryE <- function()
{
  text <- 'Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations. \"L\" is linked to SPL labels for Drug in openFDA. \"D\" is linked to a dashboard display for a drug.'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}

popcoqueryEex <- function()
{
  text <- 'Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations. \"L\" is linked to SPL labels for Drug in openFDA. \"D\" is linked to a dashboard display for a drug.'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}

popcoqueryA <- function()
{
  text <- 'Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations. \"L\" is linked to SPL labels for Drug in openFDA. \"D\" is linked to a dashboard display for a drug.'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}

popindquery <- function()
{
  text <- 'Frequency table of reported indication for which the drug was administered.  Indication is linked to medline dictionary definition for event term'
  head <- 'Reported Indication for Drug' 
  return( c(head=head, text=text) )
}

calcLRTstats2 <- function( nij, n.j , ni. , n.. )
  #Total number of reports
{
 
  
  #Total number of Events
  #Total events for drug j
#   n.j <- sum(combe$count.x)
#   #Total reports for DE combination
#   nij <-  combe$count.x
#   #Total reports for event i
#   ni. <- combe$count.y
#   #Total events
#   n.. <- sum(allevents)
  
  
  pi. <- ni./n..
  a <- nij
  b <- ni. - nij
  c <- n.j - nij
  d <- n.. - ni. - n.j + nij
  RR <- prrd( n.., ni., n.j, nij )
  LLRE <- LLR( n.., ni., n.j, nij )
  LLRE[is.nan(LLRE)] <- 0
  LLRE[RR < 1] <- 0
  return( list( RR=RR, LLRE=LLRE ) )
}


calcLRTstats <- function(totals, combe, combr=NULL, allevents)
  #Total number of reports
{
  #Total reports for drug j
  rn.j <- totals$totaldrug
  #Total reports for DE combination
  rnij <-  combe$count.x
  #Total report forevent i
  rni. <- combe$count.y
  rn.. <- totals$total
  #   print(combe)
  #   print(combr)
  #   print(totals)
  
  #Total number of Events
  #Total events for drug j
  n.j <- sum(combe$count.x)
  #Total reports for DE combination
  nij <-  combe$count.x
  #Total reports for event i
  ni. <- combe$count.y
  #Total events
  n.. <- sum(allevents)
  
  
  pi. <- ni./n..
  a <- nij
  b <- ni. - nij
  c <- n.j - nij
  d <- n.. - ni. - n.j + nij
  RR <- prrd( n.., ni., n.j, nij )
  PRRD <- prrd( rn.., rni., rn.j, rnij )
  LLRE <- LLR( n.., ni., n.j, nij )
  LLRE[is.nan(LLRE)] <- 0
  LLRE[RR < 1] <- 0
  LLRR <- LLR( rn.., rni., rn.j, rnij )
  LLRR[is.nan(LLRR)] <- 0
  return( list( RR=RR, PRRD=PRRD, LLRE=LLRE, LLRR=LLRR ) )
}

cloudplot <- function( mydf, session, scale1=6, name=1, freq=2, mymult=1,
                       stattext="Frequencies",termtype='Events', intype='Drug', scale=NULL  ){ 

  if ( is.data.frame(mydf) & getterm1(session)!="" )
  {    
    mydf <- data.frame(mydf[,name], mydf[, freq]*mymult)
    mytitle <- paste( stattext, 'for',  termtype , 'in Reports That Contain\n', getterm1(session) )
  } else  {
    mytitle <- paste('Please Enter', intype, 'Term' )
    mydf <- data.frame(term=c('No Drug Given'), LLR=1)
  }  
  return( getcloud(mydf, scale1=scale1, title=mytitle, scale=scale ) )  
}

checkdf <- function(mydf, myinput, names=NULL, changecell=NULL)
{
  if ( is.data.frame(mydf) & length(mydf) > 0 )
  {
    if( !is.null(names))
    {
      names(mydf) <- names
    }
    if( !is.null(changecell))
    {
      mydf[changecell['row'], changecell['column']] <- changecell['val']
    }
    return(mydf) 
  } else  {return(data.frame(Error=paste( 'No results for', myinput ), Count=0))}
}


popindquery2 <- function()
{
  text <- 'Frequency table of reported indication for which the drug was administered.  Indication is linked to medline dictionary definition for event term'
  head <- 'Reported Indication for Drug' 
  return( c(head=head, text=text) )
}
popcoqueryE2 <- function()
{
  text <- 'Frequency table for drugs found in selected reports. Drug name is linked to PRR results for drug-event combinations. \"L\" is linked to SPL labels for Drug in openFDA. \"D\" is linked to a dashboard display for a drug.'
  head <- 'Concomitant Medications' 
  return( c(head=head, text=text) )
}
popall2 <- function()
{
  text <- "All Counts for Drugs"
  head <- "Frequency Table"
  return( c(head=head, text=text) )
}
popspecifieddrug2 <- function()
{
  text <- "All Counts for Drugs"
  head <- "Frequency Table"
  return( c(head=head, text=text) )
}
popprr2 <- function()
{
  text <- "The proportional reporting ratio (PRR) is a simple way to get a measure of how common an adverse event for a particular drug is compared to how common the event is in the overall database.  <br>"
  head <- "Proportional Reporting Ratio"
  return( c(head=head, text=text) )
}
popcpmeanplot <- function()
{
  text <- 'Changepoint type      : Change in mean'
  head <- "Change in mean analysis"
  return( c(head=head, text=text) )
}
popquery_counts2 <- function()
{
  text <- 'Changepoint type      : Change in mean'
  head <- "Monthly and cumulative counts for drug-event combination"
  return( c(head=head, text=text) )
}



