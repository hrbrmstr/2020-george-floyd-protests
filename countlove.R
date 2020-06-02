# Count Love — https://countlove.org — captures protest information
# and provides a search interface. The data is in JSON format in an XHR
# request so let's grab that daily.

httr::GET(
  url = "https://countlove.org/data/events.json",
  httr::write_disk(
    here::here(
      sprintf("data/%s-count-love-events.json", Sys.Date())
    )
  )
)

