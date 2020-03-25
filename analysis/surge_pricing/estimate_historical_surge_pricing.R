source("helpers.R")
weather_data = get_weather_data()

# import data and add some variables
tnp_trips = data.table::fread("data/chicago_trips_20181101_20191231.csv") %>%
  as_tibble() %>%
  filter(
    trip_type == "tnp",
    !is.na(pickup_community_area) # remove trips that don't start within city limits
  )

tnp_trips = tnp_trips %>%
  mutate(
    trip_minutes = trip_seconds / 60,
    trip_start = fastPOSIXct(trip_start, tz = "UTC"),
    pickup_census_tract = as.character(pickup_census_tract),
    dropoff_census_tract = as.character(dropoff_census_tract),
    trip_id = row_number(),
    share_requested = shared_status %in% c("shared", "unmatched_share"),
    calendar_month = as.Date(floor_date(trip_start, unit = "month")),
    mph = 60 * trip_miles / trip_minutes,
    pricing_regime = case_when(
      as.Date(trip_start) < as.Date("2019-03-29") ~ "pre_q2_2019",
      as.Date(trip_start) < as.Date("2019-07-01") ~ "q2_2019",
      trip_start >= as.POSIXct("2019-10-31 23:45:00", "UTC") & trip_start < as.POSIXct("2019-11-08 00:00:00", "UTC") ~ "nov_1_7_2019",
      TRUE ~ "post_q2_2019"
    ),
    has_clean_fare_info = (
      !is.na(fare) & !is.na(trip_miles) & !is.na(trip_minutes) &
      (trip_miles >= 1.5 | trip_minutes >= 8) &
      trip_miles >= 0.5 & trip_miles < 100 &
      trip_minutes >= 2 & trip_minutes < 180 &
      mph >= 0.5 & mph < 80 &
      fare > 2 & fare < 1000 &
      fare / trip_miles < 25 &
      pricing_regime != "nov_1_7_2019"
    )
  ) %>%
  select(-trip_seconds) %>%
  left_join(area_sides, by = c("pickup_community_area" = "community_area")) %>%
  rename(pickup_side = side)




# run robust regresion models and add baseline fare predictions to trips data
set.seed(1738)

model_coefs = tnp_trips %>%
  distinct(pricing_regime, share_requested) %>%
  arrange(pricing_regime, share_requested) %>%
  mutate(coefs = list(NA))

fitted_values = tnp_trips %>%
  filter(has_clean_fare_info) %>%
  group_by(pricing_regime, share_requested) %>%
  group_modify(~ {
    formula = if (.y$share_requested) {
      fare ~ (trip_miles + trip_minutes) * shared_status
    } else {
      fare ~ trip_miles + trip_minutes
    }

    model = MASS::rlm(formula, data = .x, method = "MM", init = "lts")

    fitted_values = modelr::add_predictions(.x, model, var = "predicted_fare") %>%
      select(trip_id, predicted_fare)

    model_coefs <<- model_coefs %>%
      mutate(coefs = case_when(
        (pricing_regime == .y$pricing_regime & share_requested == .y$share_requested) ~ list(broom::tidy(model)),
        TRUE ~ coefs
      ))

    fitted_values
  }) %>%
  ungroup() %>%
  select(trip_id, predicted_fare)

tnp_trips = tnp_trips %>%
  left_join(fitted_values, by = "trip_id") %>%
  mutate(fare_ratio = fare / predicted_fare)

rm(fitted_values)

# compare robust model to ols model
coef(lm(fare ~ trip_miles + trip_minutes, data = filter(tnp_trips, has_clean_fare_info, !share_requested, pricing_regime == "post_q2_2019")))




# calculate pickups benchmarks and modified z-scores

trip_counts = bind_rows(
  tnp_trips %>%
    count(pickup_census_tract, trip_start, name = "trips") %>%
    rename(pickup_region_id = pickup_census_tract) %>%
    mutate(region_type = "census_tract"),
  tnp_trips %>%
    count(pickup_community_area, trip_start, name = "trips") %>%
    rename(pickup_region_id = pickup_community_area) %>%
    mutate(
      pickup_region_id = as.character(pickup_region_id),
      region_type = "community_area"
    ),
  tnp_trips %>%
    count(trip_start, name = "trips") %>%
    transmute(
      pickup_region_id = "chicago",
      trip_start,
      trips,
      region_type = "city"
    )
) %>%
  filter(!is.na(pickup_region_id))

all_timestamps = trip_counts %>%
  distinct(trip_start) %>%
  pull(trip_start) %>%
  sort()

trip_counts_padded = trip_counts %>%
  group_by(pickup_region_id) %>%
  complete(trip_start = all_timestamps, fill = list(trips = 0)) %>%
  ungroup() %>%
  mutate(region_type = case_when(
    pickup_region_id == "chicago" ~ "city",
    nchar(pickup_region_id) <= 2 ~ "community_area",
    TRUE ~ "census_tract"
  ))

rm(trip_counts, all_timestamps)

pickups_benchmarks = trip_counts_padded %>%
  group_by(
    pickup_region_id,
    wday = wday(trip_start),
    hour = hour(trip_start),
    minute = minute(trip_start)
  ) %>%
  summarize(
    perc50 = median(trips),
    median_abs_dev = median(abs(trips - perc50)),
    mean_abs_dev = mean(abs(trips - perc50))
  ) %>%
  ungroup()

trip_counts_padded = trip_counts_padded %>%
  mutate(
    wday = wday(trip_start),
    hour = hour(trip_start),
    minute = minute(trip_start)
  ) %>%
  inner_join(pickups_benchmarks, by = c("pickup_region_id", "wday", "hour", "minute")) %>%
  select(-wday, -hour, -minute) %>%
  mutate(
    modified_z_score = case_when(
      mean_abs_dev == 0 ~ 0,
      median_abs_dev == 0 ~ 0.7979 * (trips - perc50) / mean_abs_dev,
      TRUE ~ 0.6745 * (trips - perc50) / median_abs_dev
    )
  )

tract_surge_mults = tnp_trips %>%
  filter(
    has_clean_fare_info,
    shared_status == "solo",
    !is.na(pickup_community_area),
    !is.na(pickup_census_tract)
  ) %>%
  group_by(pickup_census_tract, trip_start) %>%
  summarize(
    estimated_surge_ratio = mean(fare_ratio),
    based_on_n = n()
  ) %>%
  ungroup() %>%
  mutate(region_type = "census_tract")

area_surge_mults = tnp_trips %>%
  filter(
    has_clean_fare_info,
    shared_status == "solo",
    !is.na(pickup_community_area)
  ) %>%
  group_by(pickup_community_area, trip_start) %>%
  summarize(
    estimated_surge_ratio = mean(fare_ratio),
    based_on_n = n()
  ) %>%
  ungroup() %>%
  mutate(
    pickup_community_area = as.character(pickup_community_area),
    region_type = "community_area"
  )

all_surge_mults = bind_rows(
  rename(tract_surge_mults, pickup_region_id = pickup_census_tract),
  rename(area_surge_mults, pickup_region_id = pickup_community_area)
)
