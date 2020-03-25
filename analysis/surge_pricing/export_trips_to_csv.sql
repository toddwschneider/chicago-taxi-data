CREATE TEMPORARY VIEW trips_for_csv_export AS
SELECT
  trip_type,
  CASE
    WHEN shared_trip_authorized = true AND trips_pooled > 1 THEN 'shared'
    WHEN shared_trip_authorized = true AND trips_pooled = 1 THEN 'unmatched_share'
    ELSE 'solo'
  END AS shared_status,
  trip_start,
  trip_seconds,
  trip_miles,
  pickup_community_area,
  pickup_census_tract,
  fare,
  tips,
  coalesce(tolls, 0) + coalesce(extras, 0) AS tolls_and_extras,
  dropoff_community_area,
  dropoff_census_tract
FROM trips
WHERE trip_start >= '2018-11-01'
  AND trip_start < '2020-01-01';

\copy (SELECT * FROM trips_for_csv_export) TO 'data/chicago_trips_20181101_20191231.csv' CSV HEADER;
