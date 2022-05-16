parseQueryFunction<- function(queryString){
 
  testString <- twitterQuery %>% URLdecode()

  #split each combination
  possible_combinations <- stri_split(testString, regex = "OR")
  
  query <- data.frame()
  query[1,1] <- possible_combinations[[1]][1]
  j <- 1
  k <- 1
  
  for(i in 2:lengths(possible_combinations)){
    temp_query <- possible_combinations[[1]][k]
    query[j,1] <- paste0(query[j,1], "OR", possible_combinations[[1]][k])
    if (str_length( query[j,1]) < 900){
      k <- k+1
      i <- k
    }else{ 
      j <- j+1
    }
    
    # }
    
  }
  query_clean <- data.frame(lapply(query, function(x){
    gsub("NAOR", "", x)
  }))
  return(query_clean)
  
  
}
