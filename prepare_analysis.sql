-- Queries to create some intermediate tables that are used in analysis.R

-- Optional: create some indexes for faster query performance
/*
CREATE INDEX idx_trips_on_taxi_id ON trips (taxi_id);
CREATE INDEX idx_trips_on_pickup_community_area ON trips (pickup_community_area);
CREATE INDEX idx_trips_on_pickup_census_tract ON trips (pickup_census_tract);
CREATE INDEX idx_trips_on_dropoff_community_area ON trips (dropoff_community_area);
CREATE INDEX idx_trips_on_dropoff_census_tract ON trips (dropoff_census_tract);
*/

CREATE TABLE daily_trips AS
SELECT
  date(trip_start) date,
  COUNT(*) AS trips,
  COUNT(DISTINCT taxi_id) AS unique_taxis,
  COUNT(DISTINCT company) AS unique_companies
FROM trips
GROUP BY date;

CREATE TABLE monthly_trips AS
SELECT
  date(date_trunc('month', date) + '1 month - 1 day'::interval) AS month,
  SUM(trips) AS trips,
  COUNT(*) AS days,
  SUM(trips)::numeric / COUNT(*) AS trips_per_day
FROM daily_trips
GROUP BY month
ORDER BY month;

CREATE TABLE hourly_trips_by_pickup_census_tract AS
SELECT
  pickup_census_tract,
  date_trunc('hour', trip_start) AS pickup_hour,
  EXTRACT(hour FROM trip_start) AS hour_of_day,
  EXTRACT(dow FROM trip_start) AS day_of_week,
  COUNT(*) count
FROM trips
GROUP BY pickup_census_tract, pickup_hour, hour_of_day, day_of_week
ORDER BY pickup_census_tract, pickup_hour;

CREATE TABLE hourly_trips_by_dropoff_census_tract AS
SELECT
  dropoff_census_tract,
  date_trunc('hour', trip_end) AS dropoff_hour,
  EXTRACT(hour FROM trip_end) AS hour_of_day,
  EXTRACT(dow FROM trip_end) AS day_of_week,
  COUNT(*) count
FROM trips
GROUP BY dropoff_census_tract, dropoff_hour, hour_of_day, day_of_week
ORDER BY dropoff_census_tract, dropoff_hour;

CREATE TABLE daily_trips_by_pickup_community_area AS
SELECT pickup_community_area, date(trip_start) date, COUNT(*) count
FROM trips
GROUP BY pickup_community_area, date
ORDER BY pickup_community_area, date;

CREATE TABLE payment_types AS
SELECT
  date(date_trunc('month', trip_start) + '1 month - 1 day'::interval) AS month,
  payment_type,
  COUNT(*),
  SUM(fare) AS fare,
  SUM(tips) AS tips,
  SUM(tolls) AS tolls,
  SUM(extras) AS extras,
  SUM(trip_total) AS trip_total
FROM trips
WHERE fare BETWEEN 1 AND 1000
  AND trip_total BETWEEN 1 AND 1000
GROUP BY month, payment_type
ORDER BY month, payment_type;

/*
N.B. this is not exact because of timestamp rounding. E.g. if trips A and B
both start and end within the same 15-minute interval, we don't know which one
was first. With additional work could make some improvement based on pickup and
drop off locations, but even then we still wouldn't know for sure
*/
CREATE TABLE next_trips AS
SELECT
  trip_id,
  taxi_id,
  dropoff_community_area,
  trip_end,
  LEAD(trip_start, 1) OVER (PARTITION BY taxi_id ORDER BY trip_start, trip_end, trip_id) AS next_trip_start,
  LEAD(pickup_community_area, 1) OVER (PARTITION BY taxi_id ORDER BY trip_start, trip_end, trip_id) AS next_pickup_community_area
FROM trips
ORDER BY taxi_id, trip_start, trip_end, trip_id;

CREATE TABLE next_trips_by_dropoff_area AS
SELECT
  dropoff_community_area,
  COUNT(*) AS dropoffs,
  SUM(CASE WHEN EXTRACT(EPOCH FROM next_trip_start - trip_end) <= 60 * 15 THEN 1 ELSE 0 END) AS next_trip_within_30_minutes
FROM next_trips
WHERE next_trip_start >= trip_end
GROUP BY dropoff_community_area
ORDER BY dropoffs DESC;

COPY (
  SELECT
    community,
    dropoff_community_area AS id,
    dropoffs,
    next_trip_within_30_minutes / dropoffs::numeric AS next_trip_within_30_minutes
  FROM
    next_trips_by_dropoff_area t, community_areas a
  WHERE t.dropoff_community_area = a.area_numbe::int
  ORDER BY next_trip_within_30_minutes DESC
) TO stdout WITH CSV HEADER;

CREATE TABLE taxi_daily_activity AS
SELECT
  taxi_id,
  date(trip_start) AS date,
  COUNT(DISTINCT date(trip_start)) AS days_worked,
  COUNT(*) AS trips,
  SUM(trip_seconds) AS trip_seconds,
  SUM(trip_miles) AS trip_miles,
  SUM(fare) AS fare,
  SUM(tolls) AS tolls,
  SUM(extras) AS extras,
  SUM(trip_total) AS trip_total
FROM trips
WHERE fare IS NOT NULL
  AND trip_miles IS NOT NULL
  AND trip_seconds IS NOT NULL
  AND fare BETWEEN 1 AND 1000
  AND trip_total BETWEEN 1 AND 1000
  AND trip_miles BETWEEN 0 AND 250
  AND trip_seconds BETWEEN 30 AND 21600
GROUP BY taxi_id, date
ORDER BY taxi_id, date;

CREATE TABLE taxi_monthly_activity AS
SELECT
  taxi_id,
  date(date_trunc('month', trip_start) + '1 month - 1 day'::interval) AS month,
  COUNT(DISTINCT date(trip_start)) AS days_worked,
  COUNT(*) AS trips,
  SUM(trip_seconds) AS trip_seconds,
  SUM(trip_miles) AS trip_miles,
  SUM(fare) AS fare,
  SUM(tolls) AS tolls,
  SUM(extras) AS extras,
  SUM(trip_total) AS trip_total,
  SUM(CASE WHEN payment_type = 'Credit Card' THEN 1 ELSE 0 END) / COUNT(*)::numeric AS frac_credit_card,
  SUM(CASE WHEN payment_type = 'Cash' THEN 1 ELSE 0 END) / COUNT(*)::numeric AS frac_cash
FROM trips
WHERE fare IS NOT NULL
  AND trip_total IS NOT NULL
  AND trip_miles IS NOT NULL
  AND trip_seconds IS NOT NULL
  AND fare BETWEEN 1 AND 1000
  AND trip_total BETWEEN 1 AND 1000
  AND trip_miles BETWEEN 0 AND 250
  AND trip_seconds BETWEEN 30 AND 21600
GROUP BY taxi_id, month
ORDER BY taxi_id, month;

-- uniquely identifiable taxis analysis
CREATE TABLE hourly_trips_by_pickup_community_area AS
SELECT
  pickup_community_area,
  date_trunc('hour', trip_start) AS pickup_hour,
  EXTRACT(hour FROM trip_start) AS hour_of_day,
  EXTRACT(dow FROM trip_start) AS day_of_week,
  COUNT(*) count
FROM trips
GROUP BY pickup_community_area, pickup_hour, hour_of_day, day_of_week
ORDER BY pickup_community_area, pickup_hour;

CREATE TABLE hourly_trips_by_dropoff_community_area AS
SELECT
  dropoff_community_area,
  date_trunc('hour', trip_end) AS dropoff_hour,
  EXTRACT(hour FROM trip_end) AS hour_of_day,
  EXTRACT(dow FROM trip_end) AS day_of_week,
  COUNT(*) count
FROM trips
GROUP BY dropoff_community_area, dropoff_hour, hour_of_day, day_of_week
ORDER BY dropoff_community_area, dropoff_hour;

CREATE TABLE unique_taxis_by_community_area_hourly_pickups AS
SELECT
  t.taxi_id,
  h.*
FROM
  hourly_trips_by_pickup_community_area h,
  trips t
WHERE
  h.count = 1
  AND h.pickup_community_area = t.pickup_community_area
  AND h.pickup_hour = date_trunc('hour', t.trip_start);

CREATE TABLE unique_taxis_by_community_area_hourly_dropoffs AS
SELECT
  t.taxi_id,
  h.*
FROM
  hourly_trips_by_dropoff_community_area h,
  trips t
WHERE
  h.count = 1
  AND h.dropoff_community_area = t.dropoff_community_area
  AND h.dropoff_hour = date_trunc('hour', t.trip_end);

CREATE TABLE identifiable_taxi_ids AS
SELECT DISTINCT taxi_id
FROM unique_taxis_by_community_area_hourly_pickups
UNION
SELECT DISTINCT taxi_id
FROM unique_taxis_by_community_area_hourly_dropoffs;

SELECT COUNT(*) FROM identifiable_taxi_ids;
-- 5,704 taxis (66% of 8,641 total) have a pickup or drop off defined uniquely by community area and date/time rounded to the nearest hour

SELECT COUNT(*) FROM trips WHERE taxi_id IN (SELECT taxi_id FROM identifiable_taxi_ids);
-- 101,728,172 trips made by those 5,704 taxis, 98% of 103,924,630 total trips
