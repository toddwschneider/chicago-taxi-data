# assumes estimate_historical_surge_pricing.R has been run in its entirety

# calculate some aggregate stats
tnp_trips %>%
  filter(
    has_clean_fare_info,
    !is.na(fare_ratio),
    shared_status == "solo"
  ) %>%
  summarize(
    avg_fare_ratio = mean(fare_ratio),
    frac12 = mean(fare_ratio >= 1.2),
    frac15 = mean(fare_ratio >= 1.5)
  )

tnp_trips %>%
  filter(
    has_clean_fare_info,
    !is.na(fare_ratio),
    shared_status == "solo"
  ) %>%
  group_by(pricing_regime) %>%
  summarize(
    avg_fare_ratio = mean(fare_ratio),
    frac12 = mean(fare_ratio >= 1.2),
    frac15 = mean(fare_ratio >= 1.5)
  ) %>%
  ungroup()

avg_surge_by_time_of_week = tnp_trips %>%
  filter(
    has_clean_fare_info,
    !is.na(fare_ratio),
    shared_status == "solo"
  ) %>%
  mutate(wday = wday(trip_start), hour = hour(trip_start)) %>%
  group_by(
    is_q2_2019 = (pricing_regime == "q2_2019"),
    pickup_side,
    hour,
    weekday_type = case_when(
      wday == 6 & hour >= 20 ~ "weekend",
      wday == 7 ~ "weekend",
      wday == 1 & hour < 20 ~ "weekend",
      TRUE ~ "weekday"
    )
  ) %>%
  summarize(
    avg_fare_ratio = mean(fare_ratio),
    frac12 = mean(fare_ratio >= 1.2),
    frac15 = mean(fare_ratio >= 1.5),
    n = n()
  ) %>%
  ungroup() %>%
  mutate(q2_2019_factor = factor(is_q2_2019, levels = c(TRUE, FALSE), labels = c("Q2 2019", "Excl. Q2 2019")))

avg_surge_by_date = tnp_trips %>%
  filter(
    has_clean_fare_info,
    !is.na(fare_ratio),
    shared_status == "solo"
  ) %>%
  group_by(date = as.Date(trip_start)) %>%
  summarize(
    avg_fare_ratio = mean(fare_ratio),
    frac12 = mean(fare_ratio >= 1.2),
    frac15 = mean(fare_ratio >= 1.5),
    n = n()
  ) %>%
  ungroup()

# surge prices in q2 2019
png("graphs/average_surge_by_date.png", width = 800, height = 800)
avg_surge_by_date %>%
  ggplot(aes(x = date, y = avg_fare_ratio)) +
  annotate(
    "rect",
    xmin = as.Date("2019-03-29"), xmax = as.Date("2019-06-30"),
    ymin = 0.98, ymax = 1.32,
    fill = "#ff0000",
    alpha = 0.15
  ) +
  geom_line(size = 0.75) +
  scale_y_continuous(labels = function(value) paste0(format(value, nsmall = 2), "x")) +
  ggtitle("Surge Prices Were Highest in Q2 2019", "Average estimated surge multiplier") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 24) +
  no_axis_titles()
dev.off()

avg_fare_for_typical_trip = tnp_trips %>%
  filter(
    has_clean_fare_info,
    !is.na(fare_ratio),
    shared_status == "solo",
    trip_miles >= 4 & trip_miles <= 4.2,
    trip_minutes >= 15 & trip_minutes <= 17
  ) %>%
  group_by(date = as.Date(trip_start)) %>%
  summarize(avg_fare = mean(fare), n = n()) %>%
  ungroup()

png("graphs/average_typical_fare_by_date.png", width = 800, height = 800)
avg_fare_for_typical_trip %>%
  ggplot(aes(x = date, y = avg_fare)) +
  annotate(
    "rect",
    xmin = as.Date("2019-03-29"), xmax = as.Date("2019-06-30"),
    ymin = 9, ymax = 13,
    fill = "#ff0000",
    alpha = 0.15
  ) +
  geom_line(size = 0.75) +
  scale_y_continuous(labels = scales::dollar) +
  ggtitle("Ride-Hail Fares Were Highest in Q2 2019", "Average fare for a typical 4-mile, 15-minute trip") +
  labs(caption = "Includes private (not shared) trips 4–4.2 miles, 15–17 minutes. Excludes tips and additional charges\nData via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 24) +
  no_axis_titles()
dev.off()

daily_trip_counts = tnp_trips %>%
  group_by(date = as.Date(trip_start)) %>%
  count(date)

# no obvious change in total demand during q2
png("graphs/total_trips_by_date.png", width = 800, height = 800)
daily_trip_counts %>%
  ggplot(aes(x = date, y = n)) +
  geom_line(size = 0.75) +
  scale_y_continuous(labels = scales::comma) +
  expand_limits(y = 0) +
  ggtitle("Chicago Ride-Hail Activity", "Daily pickups") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 24) +
  no_axis_titles()
dev.off()




# trends by geography
png("graphs/chicago_weekday_average_surge_by_side_ex_q2_2019.png", width = 1200, height = 1200)
avg_surge_by_time_of_week %>%
  filter(weekday_type == "weekday", !is_q2_2019) %>%
  ggplot(aes(x = hour, y = avg_fare_ratio)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "")) +
  scale_y_continuous(breaks = c(1, 1.05, 1.1), labels = function(value) paste0(format(value, nsmall = 2), "x")) +
  expand_limits(y = 1, x = c(0, 25)) +
  facet_wrap(~pickup_side, ncol = 3) +
  ggtitle("Chicago Weekday Ride-Hail Surge Pricing by Pickup Side", "Average estimated surge pricing multiplier, 11/1/18–3/28/19 + 7/1/19–12/31/19") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 20) +
  no_axis_titles()
dev.off()

png("graphs/chicago_weekday_average_surge_by_side_q2_2019.png", width = 1200, height = 1200)
avg_surge_by_time_of_week %>%
  filter(weekday_type == "weekday", is_q2_2019) %>%
  ggplot(aes(x = hour, y = avg_fare_ratio)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "")) +
  scale_y_continuous(labels = function(value) paste0(format(value, nsmall = 1), "x")) +
  expand_limits(y = c(1, 1.4), x = c(0, 25)) +
  facet_wrap(~pickup_side, ncol = 3) +
  ggtitle("Chicago Weekday Ride-Hail Surge Pricing by Pickup Side", "Average estimated surge pricing multiplier, 3/29/19–6/30/19") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 20) +
  no_axis_titles()
dev.off()

png("graphs/chicago_weekend_average_surge_by_side_ex_q2_2019.png", width = 1200, height = 1200)
avg_surge_by_time_of_week %>%
  filter(weekday_type == "weekend", !is_q2_2019) %>%
  ggplot(aes(x = hour, y = avg_fare_ratio)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "")) +
  scale_y_continuous(breaks = c(1, 1.05, 1.1), labels = function(value) paste0(format(value, nsmall = 2), "x")) +
  expand_limits(y = 1, x = c(0, 25)) +
  facet_wrap(~pickup_side, ncol = 3) +
  ggtitle("Chicago Weekend Ride-Hail Surge Pricing by Pickup Side", "Average estimated surge pricing multiplier, 11/1/18–3/28/19 + 7/1/19–12/31/19") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 20) +
  no_axis_titles()
dev.off()

png("graphs/chicago_weekend_average_surge_by_side_q2_2019.png", width = 1200, height = 1200)
avg_surge_by_time_of_week %>%
  filter(weekday_type == "weekend", is_q2_2019) %>%
  ggplot(aes(x = hour, y = avg_fare_ratio)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "")) +
  scale_y_continuous(labels = function(value) paste0(format(value, nsmall = 1), "x")) +
  expand_limits(y = 1, x = c(0, 25)) +
  facet_wrap(~pickup_side, ncol = 3) +
  ggtitle("Chicago Weekend Ride-Hail Surge Pricing by Pickup Side", "Average estimated surge pricing multiplier, 3/29/19–6/30/19") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 20) +
  no_axis_titles()
dev.off()

pickup_distrbutions = avg_surge_by_time_of_week %>%
  group_by(weekday_type, pickup_side, hour) %>%
  summarize(pickups = sum(n)) %>%
  ungroup() %>%
  group_by(weekday_type, pickup_side) %>%
  mutate(frac = pickups / sum(pickups)) %>%
  ungroup()

png("graphs/chicago_weekday_average_pickups_by_side.png", width = 1200, height = 1200)
pickup_distrbutions %>%
  filter(weekday_type == "weekday") %>%
  ggplot(aes(x = hour, y = frac)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "")) +
  scale_y_continuous(labels = scales::percent) +
  expand_limits(y = c(0, 0.1), x = c(0, 25)) +
  facet_wrap(~pickup_side, ncol = 3) +
  ggtitle("Chicago Weekday Ride-Hail Pickups Distribution by Side", "% of weekday pickups, 11/1/18–12/31/19") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 20) +
  no_axis_titles()
dev.off()

png("graphs/chicago_weekend_average_pickups_by_side.png", width = 1200, height = 1200)
pickup_distrbutions %>%
  filter(weekday_type == "weekend") %>%
  ggplot(aes(x = hour, y = frac)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "")) +
  scale_y_continuous(labels = scales::percent) +
  expand_limits(y = c(0, 0.1), x = c(0, 25)) +
  facet_wrap(~pickup_side, ncol = 3) +
  ggtitle("Chicago Weekend Ride-Hail Pickups Distribution by Side", "% of weekend pickups, 11/1/18–12/31/19") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 20) +
  no_axis_titles()
dev.off()

png("graphs/central_chicago_avg_weekday_surge.png", width = 800, height = 800)
avg_surge_by_time_of_week %>%
  filter(pickup_side == "central", weekday_type == "weekday") %>%
  bind_rows(mutate(top_n(., 2, -hour), hour = 24)) %>% {
    ggplot(., aes(x = hour, y = avg_fare_ratio, color = q2_2019_factor)) +
    geom_line(size = 0.75) +
    geom_point(size = 3) +
    scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "12:00 AM")) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = 3), labels = function(value) paste0(format(value, nsmall = 1), "x")) +
    scale_color_manual(values = c(red, black), guide = FALSE) +
    expand_limits(y = c(1, 1.1)) +
    facet_wrap(~q2_2019_factor, ncol = 1, scales = "free_y") +
    ggtitle("Weekday Ride-Hail Surge Pricing in Central Chicago", "Average estimated surge pricing multiplier, weekdays") +
      labs(caption = "“Central Chicago” includes the Loop, Near North Side, and Near South Side community areas\nBased on ride-hail trips 11/1/18–12/31/19, “Q2 2019” defined as 3/29/19–6/30/19\nData via City of Chicago\ntoddwschneider.com") +
    theme_tws(base_size = 24) +
    no_axis_titles()
  }
dev.off()

png("graphs/north_side_chicago_avg_weekday_surge.png", width = 800, height = 800)
avg_surge_by_time_of_week %>%
  filter(pickup_side == "north", weekday_type == "weekday") %>%
  bind_rows(mutate(top_n(., 2, -hour), hour = 24)) %>% {
    ggplot(., aes(x = hour, y = avg_fare_ratio, color = q2_2019_factor)) +
    geom_line(size = 0.75) +
    geom_point(size = 3) +
    scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "12:00 AM")) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = 3), labels = function(value) paste0(format(value, nsmall = 1), "x")) +
    scale_color_manual(values = c(red, black), guide = FALSE) +
    expand_limits(y = c(1, 1.1)) +
    facet_wrap(~q2_2019_factor, ncol = 1, scales = "free_y") +
    ggtitle("Weekday Ride-Hail Surge Pricing on Chicago’s North Side", "Average estimated surge pricing multiplier, weekdays") +
    labs(caption = "“North Side” includes Avondale, North Center, Lake View, Lincoln Park, and Logan Square community areas\nBased on ride-hail trips 11/1/18–12/31/19, “Q2 2019” defined as 3/29/19–6/30/19\nData via City of Chicago\ntoddwschneider.com") +
    theme_tws(base_size = 24) +
    no_axis_titles()
  }
dev.off()

png("graphs/west_side_chicago_avg_weekend_surge.png", width = 800, height = 800)
avg_surge_by_time_of_week %>%
  filter(pickup_side == "west", weekday_type == "weekend") %>%
  bind_rows(mutate(top_n(., 2, -hour), hour = 24)) %>% {
    ggplot(., aes(x = hour, y = avg_fare_ratio, color = q2_2019_factor)) +
    geom_line(size = 0.75) +
    geom_point(size = 3) +
    scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12:00 AM", " 6:00 AM", "12:00 PM", " 6:00 PM", "12:00 AM")) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = 3), labels = function(value) paste0(format(value, nsmall = 1), "x")) +
    scale_color_manual(values = c(red, black), guide = FALSE) +
    expand_limits(y = c(1, 1.1)) +
    facet_wrap(~q2_2019_factor, ncol = 1, scales = "free_y") +
    ggtitle("Weekend Ride-Hail Surge Pricing on Chicago’s West Side", "Average estimated surge pricing multiplier, weekends") +
    labs(caption = "“West Side” includes Austin, East Garfield Park, Humboldt Park, Lower West Side, Near West Side,\nNorth Lawndale, South Lawndale, West Garfield Park, and West Town community areas\nBased on ride-hail trips 11/1/18–12/31/19, “Q2 2019” defined as 3/29/19–6/30/19\nData via City of Chicago\ntoddwschneider.com") +
    theme_tws(base_size = 24) +
    no_axis_titles()
  }
dev.off()




# notable events at Soldier Field
soldier_field_trip_counts = trip_counts_padded %>%
  filter(
    pickup_region_id == major_venues$soldier_field,
    region_type == "census_tract"
  ) %>%
  mutate(
    date_for_event = case_when(
      hour(trip_start) <= 3 ~ as.Date(trip_start) - 1,
      TRUE ~ as.Date(trip_start)
    )
  ) %>%
  left_join(all_surge_mults, by = c("pickup_region_id", "trip_start", "region_type"))

# biggest surge multipliers at Soldier Field
soldier_field_trip_counts %>%
  filter(trips >= 100) %>%
  group_by(date_for_event) %>%
  top_n(1, estimated_surge_ratio) %>%
  ungroup() %>%
  arrange(desc(estimated_surge_ratio)) %>%
  select(trip_start, trips, modified_z_score, estimated_surge_ratio) %>%
  print(n = 25)

# biggest pickup spikes at Soldier Field
soldier_field_trip_counts %>%
  filter(trips >= 100) %>%
  group_by(date_for_event) %>%
  top_n(1, trips) %>%
  ungroup() %>%
  arrange(desc(trips)) %>%
  select(trip_start, trips, modified_z_score, estimated_surge_ratio) %>%
  print(n = 25)

plot_surge_chart = function(trip_counts, t1, t2, surge_lim = c(0, 3.5), trips_lim = c(0, 350), title = NULL, subtitle = NULL) {
  t1 = as.POSIXct(t1, tz = "UTC")
  t2 = as.POSIXct(t2, tz = "UTC")

  t_data = trip_counts %>%
   filter(trip_start >= t1, trip_start <= t2)

 p1 = ggplot(t_data, aes(x = trip_start, y = estimated_surge_ratio)) +
   geom_line(size = 1) +
   scale_x_datetime(labels = scales::date_format("%l:%M %p")) +
   scale_y_continuous(labels = function(num) format(num, nsmall = 1)) +
   expand_limits(y = surge_lim) +
   ggtitle("Estimated surge pricing multiplier") +
   theme_tws(base_size = 24) +
   no_axis_titles() +
   theme(
     panel.grid.minor = element_blank(),
     plot.margin = margin(24, 12, 24, 12, "pt"),
     plot.title = element_text(size = rel(0.7), family = font_family)
   )

 p2 = ggplot(t_data, aes(x = trip_start, y = trips)) +
   geom_line(size = 1) +
   scale_x_datetime(labels = scales::date_format("%l:%M %p")) +
   scale_y_continuous(labels = scales::comma) +
   expand_limits(y = trips_lim) +
   ggtitle("Number of pickups") +
   theme_tws(base_size = 24) +
   no_axis_titles() +
   theme(
     panel.grid.minor = element_blank(),
     plot.margin = margin(24, 12, 12, 12, "pt"),
     plot.title = element_text(size = rel(0.7), family = font_family)
   )

 p1 / p2 +
   plot_annotation(
     title = title,
     subtitle = subtitle,
     caption = "Data via City of Chicago\ntoddwschneider.com",
     theme = theme_tws(base_size = 24)
   )
}

png("graphs/rolling_stones_soldier_field_20190625.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-06-25 21:00:00",
  t2 = "2019-06-26 02:00:00",
  title = "Ride-Hailing at Soldier Field: The Rolling Stones No Filter Tour",
  subtitle = "Tue Jun 25, 2019"
)
dev.off()

png("graphs/rolling_stones_soldier_field_20190621.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-06-21 21:00:00",
  t2 = "2019-06-22 02:00:00",
  title = "Ride-Hailing at Soldier Field: The Rolling Stones No Filter Tour",
  subtitle = "Fri Jun 21, 2019"
)
dev.off()

png("graphs/bts_soldier_field_20190511.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-05-11 21:00:00",
  t2 = "2019-05-12 02:00:00",
  title = "Ride-Hailing at Soldier Field: BTS World Tour",
  subtitle = "Sat May 11, 2019"
)
dev.off()

png("graphs/bts_soldier_field_20190512.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-05-12 21:00:00",
  t2 = "2019-05-13 02:00:00",
  title = "Ride-Hailing at Soldier Field: BTS World Tour",
  subtitle = "Sun May 12, 2019"
)
dev.off()

png("graphs/bears_packers_soldier_field_20190905.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-09-05 18:00:00",
  t2 = "2019-09-06 02:00:00",
  title = "Ride-Hailing at Soldier Field: Bears vs. Packers",
  subtitle = "Thu Sep 5, 2019. 7:20 PM kickoff"
)
dev.off()

png("graphs/bears_cowboys_soldier_field_20191205.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-12-05 18:00:00",
  t2 = "2019-12-06 02:00:00",
  title = "Ride-Hailing at Soldier Field: Bears vs. Cowboys",
  subtitle = "Thu Dec 5, 2019. 7:20 PM kickoff"
)
dev.off()

png("graphs/bears_eagles_double_doink_soldier_field_20190106.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-01-06 12:00:00",
  t2 = "2019-01-07 00:00:00",
  title = "Ride-Hailing at Soldier Field: Bears vs. Eagles “Double Doink”",
  subtitle = "Sat Jan 6, 2019. 3:40 PM kickoff"
)
dev.off()

png("graphs/bears_chiefs_soldier_field_20191222.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = soldier_field_trip_counts,
  t1 = "2019-12-22 18:00:00",
  t2 = "2019-12-23 02:00:00",
  title = "Ride-Hailing at Soldier Field: Bears vs. Chiefs",
  subtitle = "Sun Dec 22, 2019. 7:20 PM kickoff"
)
dev.off()




# notable events at the United Center
united_center_events = read_csv("data/united_center_events_calendar.csv") %>%
  mutate(timestamp = fastPOSIXct(timestamp, "UTC"))

united_center_events_daily = united_center_events %>%
  group_by(date) %>%
  summarize(
    num_events = n(),
    events = paste(
      paste(time, title),
      collapse = ", "
    )
  ) %>%
  ungroup() %>%
  arrange(date)

united_center_trip_counts = trip_counts_padded %>%
  filter(
    pickup_region_id == major_venues$united_center,
    region_type == "census_tract"
  ) %>%
  mutate(
    date_for_event = case_when(
      hour(trip_start) <= 3 ~ as.Date(trip_start) - 1,
      TRUE ~ as.Date(trip_start)
    )
  ) %>%
  left_join(united_center_events_daily, by = c("date_for_event" = "date")) %>%
  left_join(all_surge_mults, by = c("pickup_region_id", "trip_start", "region_type"))

# biggest surge multipliers
united_center_trip_counts %>%
  filter(trips >= 100) %>%
  group_by(date_for_event) %>%
  top_n(1, estimated_surge_ratio) %>%
  ungroup() %>%
  arrange(desc(estimated_surge_ratio)) %>%
  select(trip_start, trips, modified_z_score, estimated_surge_ratio, events) %>%
  print(n = 25)

# biggest pickup spikes
united_center_trip_counts %>%
  filter(trips >= 50) %>%
  group_by(date_for_event) %>%
  top_n(1, trips) %>%
  ungroup() %>%
  arrange(desc(trips)) %>%
  select(trip_start, trips, modified_z_score, estimated_surge_ratio, events) %>%
  print(n = 25)

png("graphs/bulls_knicks_united_center_20190409.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = united_center_trip_counts,
  t1 = "2019-04-09 18:00:00",
  t2 = "2019-04-10 00:00:00",
  title = "Ride-Hailing at the United Center: Bulls vs. Knicks",
  subtitle = "Tue Apr 9, 2019. 7:00 PM tipoff",
  trips_lim = c(0, 200)
)
dev.off()

png("graphs/bulls_knicks_united_center_20191112.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = united_center_trip_counts,
  t1 = "2019-11-12 18:00:00",
  t2 = "2019-11-13 00:00:00",
  title = "Ride-Hailing at the United Center: Bulls vs. Knicks",
  subtitle = "Tue Nov 12, 2019. 7:00 PM tipoff",
  trips_lim = c(0, 200)
)
dev.off()

png("graphs/mumford_and_sons_united_center_20190329.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = united_center_trip_counts,
  t1 = "2019-03-29 18:00:00",
  t2 = "2019-03-30 02:00:00",
  title = "Ride-Hailing at the United Center: Mumford & Sons Delta Tour",
  subtitle = "Fri Mar 29, 2019",
  trips_lim = c(0, 300)
)
dev.off()

png("graphs/travis_scott_united_center_20190329.png", width = 800, height = 1000)
plot_surge_chart(
  trip_counts = united_center_trip_counts,
  t1 = "2018-12-06 18:00:00",
  t2 = "2018-12-07 02:00:00",
  title = "Ride-Hailing at the United Center: Travis Scott Astroworld Tour",
  subtitle = "Thu Dec 6, 2018",
  trips_lim = c(0, 300)
)
dev.off()

united_center_evening_pickups_by_date = trip_counts_padded %>%
  filter(
    pickup_region_id == major_venues$united_center,
    region_type == "census_tract",
    hour(trip_start) %in% 21:23
  ) %>%
  group_by(date = as.Date(trip_start)) %>%
  summarize(evening_trips = sum(trips)) %>%
  ungroup()

png("graphs/united_center_evening_pickups_by_date.png", width = 800, height = 800)
united_center_evening_pickups_by_date %>%
  ggplot(aes(x = date, y = evening_trips)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::comma) +
  ggtitle("Evening Ride-Hail Pickups Near United Center", "Daily pickups 9:00 PM–12:00 AM") +
  labs(caption = "Data via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 24) +
  no_axis_titles()
dev.off()

all_event_dates = united_center_events %>%
  filter(date >= "2018-11-01", date <= "2019-12-31") %>%
  filter(!grepl("cancel", tolower(title))) %>%
  pull(date) %>%
  unique() %>%
  sort()

for (i in 1:length(all_event_dates)) {
  d = all_event_dates[i]
  t1 = paste(d, "12:00:00")
  t2 = paste(d + 1, "01:00:00")

  title = glue::glue("{strftime(d, '%a %b')} {day(d)}, {year(d)} Ride-Hailing at the United Center")

  subtitle = united_center_events %>%
    filter(date == d) %>%
    pull(title) %>%
    paste(collapse = ", ")

  gg_obj = plot_surge_chart(united_center_trip_counts, t1, t2, title = title, subtitle = subtitle)

  filename = paste(d, subtitle) %>%
    tolower() %>%
    str_replace_all("[^a-z0-9 ]", "") %>%
    str_trim() %>%
    str_replace_all(" ", "_")

  png(glue::glue("graphs/united_center_events/{filename}.png"), width = 800, height = 800)
  print(gg_obj)
  dev.off()
}




surge_mults_and_z_scores = all_surge_mults %>%
  filter(region_type == "census_tract") %>%
  inner_join(
    filter(trip_counts_padded, region_type == "census_tract"),
    by = c("pickup_region_id", "trip_start")
  )

aggregate_surge_by_z = surge_mults_and_z_scores %>%
  group_by(
    q2 = as.Date(trip_start) >= "2019-03-29" & as.Date(trip_start) <= "2019-06-30",
    z_bucket = pmax(pmin(floor(modified_z_score), 8), -2)
  ) %>%
  summarize(
    n = sum(based_on_n),
    avg_ratio = sum(based_on_n * estimated_surge_ratio) / sum(based_on_n)
  ) %>%
  ungroup()

png("graphs/average_surge_vs_modified_z_score.png", width = 800, height = 800)
aggregate_surge_by_z %>%
  mutate(label = case_when(q2 ~ "3/29/19–6/30/19", TRUE ~ "11/1/18–3/28/19 + 7/1/19–12/31/19")) %>%
  ggplot(aes(x = z_bucket, y = avg_ratio)) +
  geom_line(size = 1) +
  scale_x_continuous("Modified z-score", breaks = c(-2, 0, 2, 4, 6, 8), labels = c("< -2", 0, 2, 4, 6, "8+")) +
  expand_limits(y = 1) +
  facet_wrap(~label, ncol = 1, scales = "free_y") +
  geom_blank(data = tibble(label = "3/29/19–6/30/19", z_bucket = 0, avg_ratio = 1.3)) +
  ggtitle(
    "Ride-Hail Surge Pricing vs. Demand",
    "Average estimated surge pricing multiplier"
  ) +
  labs(caption = "Modified z-score represents tract-level demand compared to “average” for time of day based on median and median absolute deviation\nData via City of Chicago\ntoddwschneider.com") +
  theme_tws(base_size = 24) +
  theme(axis.title.y = element_blank())
dev.off()
