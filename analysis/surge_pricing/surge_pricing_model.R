# assumes estimate_historical_surge_pricing.R has been run in its entirety

trip_counts_padded = trip_counts_padded %>%
  arrange(region_type, pickup_region_id, trip_start) %>%
  group_by(region_type, pickup_region_id) %>%
  mutate(trips_trend = trips - lag(rollmeanr(trips, k = 8, fill = NA), 1)) %>%
  ungroup()

surge_model_data = tnp_trips %>%
  filter(
    trip_type == "tnp",
    shared_status == "solo",
    has_clean_fare_info,
    !is.na(fare_ratio),
    !is.na(pickup_community_area)
  ) %>%
  select(-trip_type, -shared_status, -share_requested, -has_clean_fare_info)

surge_model_data = surge_model_data %>%
  mutate(pickup_community_area = as.character(pickup_community_area)) %>%
  left_join(
    trip_counts_padded %>%
      filter(region_type == "census_tract") %>%
      select(pickup_region_id, trip_start, modified_z_score, trips_trend) %>%
      rename(
        census_tract_z_score = modified_z_score,
        census_tract_trips_trend = trips_trend
      ),
    by = c("pickup_census_tract" = "pickup_region_id", "trip_start")
  ) %>%
  mutate(
    census_tract_z_score = replace_na(census_tract_z_score, 0),
    census_tract_trips_trend = replace_na(census_tract_trips_trend, 0)
  ) %>%
  inner_join(
    trip_counts_padded %>%
      filter(region_type == "community_area") %>%
      select(pickup_region_id, trip_start, modified_z_score, trips_trend) %>%
      rename(
        community_area_z_score = modified_z_score,
        community_area_trips_trend = trips_trend
      ),
    by = c("pickup_community_area" = "pickup_region_id", "trip_start")
  ) %>%
  inner_join(
    trip_counts_padded %>%
      filter(region_type == "city", pickup_region_id == "chicago") %>%
      select(pickup_region_id, trip_start, modified_z_score, trips_trend) %>%
      rename(
        citywide_z_score = modified_z_score,
        citywide_trips_trend = trips_trend
      ),
    by = "trip_start"
  ) %>%
  mutate(weather_hour = floor_date(trip_start, unit = "hour")) %>%
  inner_join(
    select(weather_data, hour_for_trips, precip_inches),
    by = c("weather_hour" = "hour_for_trips")
  ) %>%
  select(-weather_hour) %>%
  filter(!is.na(citywide_trips_trend))

# calibrate a very naive curve-fitting model
surge_model = minpack.lm::nlsLM(
  fare_ratio ~ b_intercept +
               b_q2 * (pricing_regime == "q2_2019") +
               b_tract_z_scale * scurve(census_tract_z_score, 6, 2) +
               b_area_z_scale * scurve(community_area_z_score, 6, 2) +
               b_city_z_scale * scurve(citywide_z_score, 6, 2) +
               b_tract_trips_trend_scale * scurve(census_tract_trips_trend, 100, 30) +
               b_area_trips_trend_scale * scurve(community_area_trips_trend, 300, 100) +
               b_city_trips_trend_scale * scurve(citywide_trips_trend, 900, 300) +
               b_precip * (precip_inches > 0),
  data = surge_model_data,
  start = list(
    b_intercept = 1,
    b_q2 = 0.1,
    b_tract_z_scale = 0.1,
    b_area_z_scale = 0.1,
    b_city_z_scale = 0.1,
    b_tract_trips_trend_scale = 0.1,
    b_area_trips_trend_scale = 0.1,
    b_city_trips_trend_scale = 0.1,
    b_precip = 0.05
  )
)
