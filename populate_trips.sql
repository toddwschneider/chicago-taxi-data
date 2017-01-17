INSERT INTO taxis (external_id)
SELECT DISTINCT external_taxi_id
FROM trips_raw
WHERE external_taxi_id NOT IN (SELECT external_id FROM taxis);

INSERT INTO trips
SELECT
  trip_id,
  taxis.id,
  trip_start,
  trip_end,
  trip_seconds,
  trip_miles,
  pickup_census_tract,
  dropoff_census_tract,
  pickup_community_area,
  dropoff_community_area,
  fare::money::numeric,
  tips::money::numeric,
  tolls::money::numeric,
  extras::money::numeric,
  trip_total::money::numeric,
  payment_type,
  company,
  pickup_centroid_latitude,
  pickup_centroid_longitude,
  dropoff_centroid_latitude,
  dropoff_centroid_longitude,
  community_areas
FROM trips_raw t, taxis
WHERE t.external_taxi_id = taxis.external_id;

TRUNCATE TABLE trips_raw;
