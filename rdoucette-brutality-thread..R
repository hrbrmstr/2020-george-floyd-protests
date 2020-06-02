# Police protest brutality thread by T. Greg Doucette
# https://twitter.com/greg_doucette/status/1267297607782731777

library(tweetview) # hrbrmstr/tweetview

thread <- tweetview::get_thread("1267297607782731777")

jsonlite::toJSON(thread, force = TRUE, pretty = TRUE) %>%
  writeLines(here::here("data/2020-06-02-doucette-extract.json"))
