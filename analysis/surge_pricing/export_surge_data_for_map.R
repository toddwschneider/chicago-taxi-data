# assumes estimate_historical_surge_pricing.R has been run in its entirety

export_data = trip_counts_padded %>%
  filter(
    trips > 0,
    region_type %in% c("census_tract", "community_area")
  ) %>%
  left_join(
    all_surge_mults,
    by = c("pickup_region_id", "region_type", "trip_start")
  ) %>%
  select(pickup_region_id, region_type, trip_start, estimated_surge_ratio, trips, modified_z_score) %>%
  mutate(
    date = as.Date(trip_start),
    trip_start = as.integer(trip_start),
    estimated_surge_ratio = round(estimated_surge_ratio, 2),
    modified_z_score = round(modified_z_score, 1)
  ) %>%
  rowwise() %>%
  mutate(values = list(c(estimated_surge_ratio, trips, modified_z_score))) %>%
  ungroup()

# write json to files by date
base_path = "export_data"
dir.create(base_path)

export_data %>%
  group_by(date) %>%
  group_walk(~ {
    filename = glue::glue("{base_path}/{.y$date}.json")

    trips_json = .x %>%
      select(trip_start, pickup_region_id, values) %>%
      nest(data = c(pickup_region_id, values)) %>%
      rowwise() %>%
      mutate(data = list(as.list(deframe(data)))) %>%
      ungroup() %>%
      select(trip_start, data) %>%
      deframe() %>%
      as.list()

    weather_stats = filter(weather_data, date == .y$date)

    weather_json = purrr::map(1:nrow(weather_stats), function(i) {
      c(weather_stats$degrees_f[i], weather_stats$precip_inches[i], weather_stats$snowing[i])
    }) %>% setNames(as.character(weather_stats$timestamp))

    output_json = list(trips = trips_json, weather = weather_json)

    cat(
      jsonlite::toJSON(output_json, auto_unbox = TRUE, na = "null"),
      file = filename
    )
  })
