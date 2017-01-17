library(dplyr)
library(ggplot2)
library(scales)
library(RPostgreSQL)
library(zoo)
library(stringr)
library(lubridate)
library(readr)
library(extrafont)
source("helpers.R")

trips = query("SELECT * FROM daily_trips ORDER BY date") %>%
  mutate(
    monthly = rollsum(trips, k = 28, na.pad = TRUE, align = "right"),
    taxis_average = rollmean(unique_taxis, k = 28, na.pad = TRUE, align = "right")
  )

monthly_total_trips = ggplot(data = trips, aes(x = date, y = monthly)) +
  geom_line(size = 1.25, color = chi_hex) +
  scale_y_continuous(labels = unit_format("m", scale = 1e-6, sep = "")) +
  expand_limits(y = 0) +
  ggtitle(
    "Chicago monthly taxi pickups",
    subtitle = "Trailing 28 days"
  ) +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

daily_total_trips = ggplot(data = filter(trips, date <= "2016-11-30"), aes(x = date, y = trips)) +
  geom_line(size = 0.5, color = chi_hex) +
  scale_y_continuous(labels = unit_format("k", scale = 1e-3, sep = ""), limits = c(0, 175000)) +
  expand_limits(y = 0) +
  ggtitle("Chicago daily taxi pickups") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

daily_taxis_in_use = ggplot(data = trips, aes(x = date, y = taxis_average)) +
  geom_line(size = 1.25, color = chi_hex) +
  scale_y_continuous(labels = comma) +
  expand_limits(y = 0) +
  ggtitle(
    "Chicago daily taxis in service",
    subtitle = "Taxis that made at least 1 daily pickup"
  ) +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

areas = query("
  WITH areas AS (
    SELECT DISTINCT pickup_community_area AS id FROM daily_trips_by_pickup_community_area
  ),

  dates AS (
    SELECT date(d) AS date
    FROM generate_series(
      (SELECT MIN(date) FROM daily_trips_by_pickup_community_area),
      (SELECT MAX(date) FROM daily_trips_by_pickup_community_area),
      '1 day'
    ) d
  )

  SELECT
    areas.id AS pickup_community_area,
    c.community AS name,
    dates.date,
    COALESCE(t.count, 0) AS trips
  FROM areas
    CROSS JOIN dates
    LEFT JOIN daily_trips_by_pickup_community_area t
      ON dates.date = t.date
      AND areas.id = t.pickup_community_area
    LEFT JOIN community_areas c
      ON areas.id = c.area_numbe::int
  ORDER BY areas.id, dates.date
") %>%
  group_by(pickup_community_area) %>%
  mutate(
    monthly = rollsum(trips, k = 28, na.pad = TRUE, align = "right"),
    name = str_to_title(name)
  ) %>%
  ungroup()

areas$name[areas$pickup_community_area == 76] = "O'Hare Airport"

area_totals = areas %>%
  group_by(pickup_community_area, name) %>%
  summarize(total = sum(trips)) %>%
  arrange(desc(total)) %>%
  ungroup()

areas = areas %>%
  mutate(name = factor(name, levels = area_totals$name))

for (i in filter(area_totals, total > 10000)$pickup_community_area) {
  area_data = filter(areas, pickup_community_area == i, !is.na(monthly))

  if (max(area_data$monthly) > 10000) {
    y_labels = unit_format("k", scale = 1e-3, sep = "")
  } else {
    y_labels = comma
  }

  p = ggplot(data = area_data, aes(x = date, y = monthly)) +
    geom_line(size = 1.25, color = chi_hex) +
    scale_y_continuous(labels = y_labels) +
    expand_limits(y = 0) +
    ggtitle(
      area_data$name[1],
      subtitle = "Taxi pickups, trailing 28 days"
    ) +
    labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
    theme_tws(base_size = 32) +
    no_axis_titles()

  png(filename = paste0("graphs/area", i, ".png"), width = 640, height = 640)
  print(p)
  dev.off()
}

annual = query("
  WITH sep_nov_2016 AS (
    SELECT
      pickup_community_area,
      SUM(count) AS trips
    FROM daily_trips_by_pickup_community_area
    WHERE date >= '2016-09-01'
      AND date <= '2016-11-30'
    GROUP BY pickup_community_area
  ),

  sep_nov_2015 AS (
    SELECT
      pickup_community_area,
      SUM(count) AS trips
    FROM daily_trips_by_pickup_community_area
    WHERE date >= '2015-09-01'
      AND date <= '2015-11-30'
    GROUP BY pickup_community_area
  ),

  may_jul_2014 AS (
    SELECT
      pickup_community_area,
      SUM(count) AS trips
    FROM daily_trips_by_pickup_community_area
    WHERE date >= '2014-05-01'
      AND date <= '2014-07-30'
    GROUP BY pickup_community_area
  )

  SELECT
    t1.pickup_community_area,
    c.community AS name,
    t1.trips AS may_jul_2014,
    t2.trips AS sep_nov_2015,
    t3.trips AS sep_nov_2016
  FROM
    may_jul_2014 t1,
    sep_nov_2015 t2,
    sep_nov_2016 t3,
    community_areas c
  WHERE
    t1.pickup_community_area = t2.pickup_community_area
    AND t2.pickup_community_area = t3.pickup_community_area
    AND t1.pickup_community_area = c.area_numbe::int
  ORDER BY c.community
") %>%
  mutate(
    name = str_to_title(name),
    annual_growth = sep_nov_2016 / sep_nov_2015 - 1,
    q2_2014_to_current = sep_nov_2016 / may_jul_2014 - 1
  )

write_csv(annual, "data/community_areas_annual_growth.csv")
write_csv(area_totals, "data/community_area_totals.csv")

taxis = query("
  SELECT
    month,
    COUNT(DISTINCT taxi_id) AS active_taxis,
    SUM(trips) AS total_trips,
    AVG(days_worked) AS mean_days_worked,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY days_worked) AS median_days_worked,
    SUM(trip_seconds) / 3600 / SUM(days_worked) AS mean_hours_per_day_worked,
    AVG(trips) AS mean_trips,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY trips) AS median_trips,
    SUM(trips) / SUM(days_worked) AS mean_trips_per_day_worked,
    AVG(fare) mean_fare_collected,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY fare) AS median_fare_collected,
    SUM(fare) / SUM(days_worked) AS mean_fare_collected_per_day_worked,
    AVG(trip_total) mean_total_collected,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY trip_total) AS median_total_collected,
    SUM(fare) as fare,
    SUM(tolls) as tolls,
    SUM(extras) as extras,
    SUM(trip_total) AS trip_total
  FROM taxi_monthly_activity
  WHERE month >= '2013-02-02'
    AND month < '2016-12-01'
  GROUP BY month
  ORDER BY month
")

monthly_taxis_in_use = ggplot(data = taxis, aes(x = month, y = active_taxis)) +
  geom_line(size = 1.25, color = chi_hex) +
  scale_y_continuous(labels = comma) +
  expand_limits(y = 0) +
  ggtitle(
    "Chicago monthly taxis in service",
    subtitle = "Taxis that made at least 1 pickup per month"
  ) +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

trips_per_taxi_per_day = ggplot(data = taxis, aes(x = month, y = mean_trips_per_day_worked)) +
  geom_line(size = 1.25, color = chi_hex) +
  scale_y_continuous(labels = comma) +
  expand_limits(y = 0) +
  ggtitle("Trips per day per active taxi") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

fares_per_taxi_per_day = ggplot(data = taxis, aes(x = month, y = mean_fare_collected_per_day_worked)) +
  geom_line(size = 1.25, color = chi_hex) +
  scale_y_continuous(labels = dollar) +
  expand_limits(y = 0) +
  ggtitle(
    "Daily fares collected per active taxi",
    subtitle = "Excludes tips, tolls, and extras"
  ) +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

avg_days_worked = ggplot(data = taxis, aes(x = month, y = mean_days_worked)) +
  geom_line(size = 1.25, color = chi_hex) +
  scale_y_continuous(labels = comma) +
  expand_limits(y = 0) +
  ggtitle("Average days worked per medallion per month") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

daily_taxi_activity = query("
  SELECT taxi_id, date, trips
  FROM taxi_daily_activity
  ORDER BY taxi_id, date
")

daily_trips_histogram = ggplot(data = daily_taxi_activity, aes(x = pmin(trips, 50), y = ..density..)) +
  geom_histogram(binwidth = 1) +
  scale_y_continuous(labels = percent) +
  scale_x_continuous("Number of trips in 24 hr period", breaks = 10 * (0:5), labels = c(10 * (0:4), "≥50")) +
  ggtitle(
    "Histogram of daily trips per taxi",
    subtitle = paste(format(range(daily_taxi_activity$date), "%b %Y"), collapse = "–")
  ) +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  theme(axis.title.y = element_blank())

payment_types = query("
  WITH totals AS (
    SELECT month, SUM(count) AS total
    FROM payment_types
    GROUP BY month
  )
  SELECT
    p.month,
    p.payment_type,
    p.count / t.total AS frac
  FROM payment_types p, totals t
  WHERE p.month = t.month
    AND payment_type IN ('Cash', 'Credit Card')
  ORDER BY p.payment_type, p.month;
")

payment_types_graph = ggplot(data = payment_types, aes(x = month, y = frac, color = payment_type)) +
  geom_line(size = 1.25) +
  scale_color_discrete("") +
  scale_y_continuous(labels = percent) +
  expand_limits(y = 0) +
  ggtitle(
    "Chicago taxi payment methods",
    subtitle = "% of trips"
  ) +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  theme(legend.position = "bottom") +
  no_axis_titles()

reference_month = "2014-06-30"

nyc_monthly = read_csv("data/nyc_monthly_taxi_trips.csv")
nyc_monthly = nyc_monthly %>%
  arrange(month) %>%
  mutate(
    geo = "NYC",
    index = 100 * trips_per_day / nyc_monthly$trips_per_day[nyc_monthly$month == reference_month]
  )

chicago_monthly = query("SELECT month, trips_per_day FROM monthly_trips WHERE days >= 28 ORDER BY month")
chicago_monthly = chicago_monthly %>%
  mutate(
    geo = "CHI",
    index = 100 * trips_per_day / chicago_monthly$trips_per_day[chicago_monthly$month == reference_month]
  )

chi_nyc = bind_rows(nyc_monthly, chicago_monthly) %>%
  group_by(geo) %>%
  mutate(annual_growth = trips_per_day / lag(trips_per_day, 12) - 1) %>%
  ungroup() %>%
  filter(month >= "2013-02-02")

chi_nyc_comparison = ggplot(data = chi_nyc, aes(x = month, y = index, color = geo)) +
  geom_line(size = 1.25) +
  geom_text(
    data = filter(chi_nyc, month == max(chi_nyc$month)),
    aes(x = month + 120, label = geo),
    size = 9, family = font_family
  ) +
  scale_y_continuous(breaks = seq(0, 100, by = 25)) +
  scale_color_manual(values = c(chi_hex, nyc_hex), guide = FALSE) +
  expand_limits(y = 0) +
  coord_cartesian(xlim = as.Date(c("2013-01-01", "2017-06-01"))) +
  ggtitle(
    "Chicago and NYC monthly taxi pickups index",
    subtitle = "Indexed to June 2014 = 100"
  ) +
  labs(caption = "Data via City of Chicago and NYC TLC\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  theme(plot.title = element_text(size = rel(1))) +
  no_axis_titles()

chi_nyc_growth = ggplot(data = filter(chi_nyc, month >= "2014-02-01"), aes(x = month, y = annual_growth, color = geo)) +
  geom_line(size = 1.25) +
  geom_text(
    data = filter(chi_nyc, month == max(chi_nyc$month)),
    aes(x = month + 90, label = geo),
    size = 9, family = font_family
  ) +
  geom_hline(yintercept = 0, color = "#888888") +
  scale_y_continuous(labels = percent) +
  scale_color_manual(values = c(chi_hex, nyc_hex), guide = FALSE) +
  expand_limits(y = 0) +
  coord_cartesian(xlim = as.Date(c("2014-01-01", "2017-04-01"))) +
  ggtitle(
    "Chicago and NYC taxi pickups",
    subtitle = "Annual growth rate"
  ) +
  labs(caption = "Data via City of Chicago and NYC TLC\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  theme(plot.title = element_text(size = rel(1))) +
  no_axis_titles()

cubs = query("
  WITH daily AS (
    SELECT
      date(dropoff_hour) AS date,
      (date(dropoff_hour) IN (SELECT DISTINCT date FROM cubs_home_games)) AS cubs_home_game,
      SUM(count) AS trips
    FROM hourly_trips_by_dropoff_census_tract
    WHERE dropoff_census_tract IN ('17031061100', '17031061000', '17031832000', '17031061200', '17031832100', '17031060500', '17031061500', '17031062200', '17031062100', '17031062300')
    GROUP BY date
    ORDER BY date
  )
  SELECT
    date(date_trunc('month', date) + '1 month - 1 day'::interval) AS month,
    cubs_home_game,
    COUNT(*),
    AVG(trips) AS avg
  FROM daily
  GROUP BY month, cubs_home_game
  ORDER BY cubs_home_game, month
") %>%
  mutate(
    season = year(month),
    grp = ifelse(cubs_home_game, season, 0),
    cubs_home_game = factor(cubs_home_game, levels = c(FALSE, TRUE), labels = c("No home game", "Home game"))
  )

text_labels = group_by(cubs, cubs_home_game) %>% top_n(1, month)
text_labels$avg[1] = text_labels$avg[1] - 125
text_labels$avg[2] = text_labels$avg[2] + 100

wrigley = ggplot(data = cubs, aes(x = month, y = avg, color = cubs_home_game, group = grp)) +
  geom_line(size = 1.25) +
  geom_text(
    data = text_labels,
    aes(x = month, label = cubs_home_game),
    size = 7.5, family = font_family
  ) +
  scale_y_continuous(labels = comma) +
  scale_color_manual(values = c(chi_hex, cubs_hex), guide = FALSE) +
  expand_limits(y = 0) +
  coord_cartesian(xlim = as.Date(c("2013-01-01", "2017-06-01"))) +
  ggtitle(
    "Wrigley Field taxi activity",
    subtitle = "Daily drop offs, days with vs. without home games"
  ) +
  labs(caption = "Data via City of Chicago and Baseball Reference\ntoddwschneider.com") +
  theme_tws(base_size = 32) +
  no_axis_titles()

setwd("graphs/")
w = 640
h = 640

png("monthly_taxi_trips.png", width=w, height=h)
print(monthly_total_trips)
dev.off()

png("daily_total_trips.png", width=w, height=h)
print(daily_total_trips)
dev.off()

png("chi_nyc_index.png", width=w, height=h)
print(chi_nyc_comparison)
dev.off()

png("chi_nyc_growth.png", width=w, height=h)
print(chi_nyc_growth)
dev.off()

png("monthly_taxis_in_use.png", width=w, height=h)
print(monthly_taxis_in_use)
dev.off()

png("trips_per_taxi_per_day.png", width=w, height=h)
print(trips_per_taxi_per_day)
dev.off()

png("fares_per_taxi_per_day.png", width=w, height=h)
print(fares_per_taxi_per_day)
dev.off()

png("daily_trips_histogram.png", width=w, height=h)
print(daily_trips_histogram)
dev.off()

png("payment_types.png", width=w, height=h)
print(payment_types_graph)
dev.off()

png("wrigley_dropoffs.png", width=w, height=h)
print(wrigley)
dev.off()
