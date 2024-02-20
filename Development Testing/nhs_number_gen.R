
  # libraries, clear console, clear global env
    library(dplyr)
    library(tidyr)
    library(stringr)
    library("getPass")
    rm(list = ls())
    cat("\014")
  

nhs_check <- function(NHSnumber)
{
  if(str_count(toString(NHSnumber)) != 10){
    return (1 == 0)}
  y <- 0
  for(i in 1:9){
    y <- y + as.numeric(substr(NHSnumber, i, i))*(11-i)
  }
  ifelse(y%%11 == 0,
         return ((as.numeric(substr(NHSnumber, 10, 10))) == 0),
         return ((11 - y%%11) == as.numeric(substr(NHSnumber, 10, 10))))
}


{
  required <- 48
  index <- 9000000016
  v <- c()
  
  for(index in 9512000000:9999999999) {
    if(length(v) >= required) break;
    if(nhs_check(index)) {
        v <- c(v, as.character(index))
    } else {
      print(sprintf('%s is not a valid nhs number', as.character(index)))
    }
    index <- index + 1
  }
  for(i in 1:length(v)) {
    print(as.numeric(v[i]))
  }
}

if (exists("Connection")) {
  dbDisconnect(Connection)
}

df <- as.data.frame(v)

write.csv(df, 'output.csv')
shell.exec(getwd())
