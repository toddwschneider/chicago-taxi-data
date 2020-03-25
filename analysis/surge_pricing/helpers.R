required_packages = c(
  "data.table",
  "fasttime",
  "glue",
  "lubridate",
  "MASS",
  "minpack.lm",
  "patchwork",
  "tidyverse",
  "zoo"
)

installed_packages = rownames(installed.packages())
packages_to_install = required_packages[!(required_packages %in% installed_packages)]

if (length(packages_to_install) > 0) {
  install.packages(
    packages_to_install,
    dependencies = TRUE,
    repos = "https://cloud.r-project.org",
  )
}

rm(required_packages, installed_packages, packages_to_install)

library(tidyverse)
library(lubridate)
library(patchwork)
library(zoo)
library(fasttime)

font_family = "Open Sans"
title_font_family = "Fjalla One"
red = "#cc0000"
black = "#000000"

theme_tws = function(base_size = 12) {
  bg_color = "#f4f4f4"
  bg_rect = element_rect(fill = bg_color, color = bg_color)

  theme_bw(base_size) +
    theme(
      text = element_text(family = font_family),
      plot.title = element_text(family = title_font_family),
      plot.subtitle = element_text(size = rel(1)),
      plot.caption = element_text(size = rel(0.5), margin = unit(c(1, 0, 0, 0), "lines"), lineheight = 1.1, color = "#555555"),
      plot.background = bg_rect,
      axis.ticks = element_blank(),
      axis.text.x = element_text(size = rel(1)),
      axis.title.x = element_text(size = rel(1), margin = margin(1, 0, 0, 0, unit = "lines")),
      axis.text.y = element_text(size = rel(1)),
      axis.title.y = element_text(size = rel(1)),
      panel.background = bg_rect,
      panel.border = element_blank(),
      panel.grid.major = element_line(color = "grey80", size = 0.25),
      panel.grid.minor = element_blank(),
      panel.spacing = unit(1.5, "lines"),
      legend.background = bg_rect,
      legend.key.width = unit(1.5, "line"),
      legend.key = element_blank(),
      strip.background = element_blank()
    )
}

no_axis_titles = function() {
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )
}

scurve = function(x, center, width) {
  1 / (1 + exp(-(x - center) / width))
}

area_sides = tibble(
  community_area = 1:77,
  side = case_when(
    community_area %in% c(8, 32, 33) ~ "central",
    community_area %in% c(5:7, 21:22) ~ "north",
    community_area %in% c(1:4, 9:14, 77) ~ "far_north",
    community_area %in% 15:20 ~ "northwest",
    community_area %in% 23:31 ~ "west",
    community_area %in% c(34:43, 60, 69) ~ "south",
    community_area %in% c(57:59, 61:68) ~ "southwest",
    community_area %in% 44:55 ~ "far_southeast",
    community_area %in% 70:75 ~ "far_southwest",
    community_area %in% c(56, 76) ~ "airports",
  )
)

major_venues = list(
  soldier_field = "17031330100",
  united_center = "17031838100"
)

# additional info about weather data:
# https://mesonet.agron.iastate.edu/ASOS/
# https://en.wikipedia.org/wiki/METAR#METAR_WX_codes
get_weather_data = function() {
  asos = read_csv("https://mesonet.agron.iastate.edu/cgi-bin/request/asos.py?station=ORD&data=tmpf&data=wxcodes&year1=2018&month1=10&day1=31&year2=2020&month2=1&day2=2&tz=Etc%2FUTC&format=onlycomma&latlon=no&missing=empty&trace=0.0001&direct=no&report_type=1&report_type=2")

  precip = read_csv("https://mesonet.agron.iastate.edu/cgi-bin/request/hourlyprecip.py?network=IL_ASOS&station=ORD&year1=2018&month1=10&day1=31&year2=2020&month2=1&day2=1&tz=Etc%2FUTC")

  asos %>%
    arrange(valid) %>%
    mutate(
      tmpf = na.locf(tmpf, na.rm = FALSE),
      hour = floor_date(valid, unit = "hour")
    ) %>%
    group_by(hour) %>%
    mutate(
      row_num = row_number(),
      snowing = sum(grepl("SN", wxcodes)) > 0
    ) %>%
    ungroup() %>%
    filter(row_num == 1) %>%
    select(hour, tmpf, snowing) %>%
    rename(hour_utc = hour, degrees_f = tmpf) %>%
    left_join(precip, by = c("hour_utc" = "valid")) %>%
    select(hour_utc, degrees_f, precip_inches = precip_in, snowing) %>%
    mutate(
      precip_inches = replace_na(precip_inches, 0),
      hour_for_trips = force_tz(with_tz(hour_utc, "America/Chicago"), "UTC"),
      timestamp = as.integer(hour_for_trips),
      date = as.Date(hour_for_trips)
    ) %>%
    group_by(hour_for_trips) %>%
    filter(row_number() == 1) %>%
    ungroup() %>%
    filter(date >= as.Date("2018-11-01")) %>%
    select(hour_for_trips, degrees_f, precip_inches, snowing, timestamp, date)
}
