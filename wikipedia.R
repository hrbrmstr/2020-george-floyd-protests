# Turns Wikipedia entry on George Floyd protests (https://en.wikipedia.org/wiki/List_of_George_Floyd_protests)
# into data
#
# NOTE: the entry page is a live event page and the HTML structure changes
#       often. This script will be updated as it breaks.

library(sf)
library(V8)
library(rvest)
library(stringi)
library(hrbrthemes)
library(tidyverse)

ctx <- v8()

pg <- read_html("https://en.wikipedia.org/wiki/List_of_George_Floyd_protests")

# geolocated >= 100 -------------------------------------------------------

# in-page JS code has some parsed topojson of U.S. locales where
# 100+ protesters have gathered to-date. this extracts them.

html_nodes(pg, "script")[1] %>%
  html_text() %>%
  stri_replace_first_fixed(
    'document.documentElement.className="client-js";',
    'var '
  ) %>%
  ctx$eval()

ctx$get("RLCONF")[["wgKartographerLiveData"]] %>%
  .[[1]] %>%
  as_tibble() -> xdf

map(xdf$geometry$coordinates, set_names, c("lng", "lat")) %>%
  map(as.list) %>%
  bind_rows() %>%
  mutate(
    locale = xdf$properties$title
  ) %>%
  st_as_sf(
    coords = c("lng", "lat"),
    crs = 4326
  ) -> protests_100

st_write(protests_100, here::here("data/2020-06-02-wikipedia-protests-100.geojson"))

# map them to check
library(rnaturalearth)

ne110 <- filter(ne_countries(returnclass="sf"), region_un != "Antarctica")

ggplot() +
  geom_sf(data = ne110, size = 0.125, color = "#2b2b2b88", fill = NA) +
  geom_sf(data = protests_100, shape = 15, size = 0.5, color = "#7f0000") +
  coord_sf(crs = 54019, datum = NA) +
  labs(
    title = sprintf("%s Protests", Sys.Date()-1),
    subtitle = "Locations where 100+ came together",
    caption = "Source: <https://en.wikipedia.org/wiki/List_of_George_Floyd_protests>\nCode: <https://github.com/hrbrmstr/2020-george-floyd-protests>"
  ) +
  theme_ipsum_es(grid="") -> gg

ggsave(
  filename = "protests-map.png",
  plot = gg,
  width = 900/96,
  height = 600/96,
  dpi = "retina"
)

# day/locale/counts (>=100) table -----------------------------------------

html_node(pg, xpath=".//table[caption]") %>%
  html_table() %>%
  as_tibble() %>%
  gather(day, count, -Location) %>%
  mutate(
    day = as.Date(sprintf("%s 2020", day), format="%b %d %Y"),
    count = stri_replace_last_regex(count, "\\[.*", "") %>%
      ifelse(. == "", 0, .) %>%
      parse_number()
  ) %>%
  mutate(
    Location = case_when(
      Location == "Honolulu" ~ "Honolulu, Hawaii",
      Location == "Miami" ~ "Miami, Florida",
      TRUE ~ Location
    )
  ) %>%
  separate(Location, c("locale", "state"), sep=", ") -> locale_ts_gt_100

write_csv(locale_ts_gt_100, here::here("data/2020-06-02-wikipedia-locale-ts-100.csv"))

# locale details ----------------------------------------------------------

# this gets a listing of U.S. state and locale (city/town) documented
# entries

html_nodes(pg, xpath=".//h2[contains(., 'International')]/preceding-sibling::h3") %>%
  map_df(~{
    tibble(
      state = html_text(.x, trim=TRUE) %>% stri_replace_all_regex("\\[.*$", ""),
      entry = html_nodes(.x, xpath = ".//following-sibling::ul[1]/li") %>%
        html_text(trim=TRUE)
    )
  }) %>%
  mutate(
    locale = stri_match_first_regex(entry, "^([^\\:]+):+")[,2],
    entry = stri_replace_first_regex(entry, "^([^\\:]+):+", "") %>%
      stri_replace_all_regex("\\[[[:digit:]]+\\]", "") %>%
      stri_trim_both()
  ) %>%
  group_by(state, locale) %>%
  summarise(
    entry = paste0(entry, collapse = " ")
  ) -> protest_entries

write_csv(protest_entries, here::here("data/2020-06-02-wikipedia-locale-entries.csv"))

# NOTE: as of 2020-06-01 0635 ET many entries noting either the presence of
#       the national guard or the calling for the presence of the national
#       guard are missing.

filter(protest_entries, grepl("national guard", entry, ignore.case = TRUE))

