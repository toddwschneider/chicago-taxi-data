INSERT INTO taxis (external_id)
SELECT DISTINCT taxi_id
FROM taxi_trips_raw
WHERE taxi_id NOT IN (SELECT external_id FROM taxis);

DELETE FROM trips
WHERE trip_type = 'taxi'
  AND trip_id IN (SELECT trip_id FROM taxi_trips_raw);

INSERT INTO trips
(
  trip_type, trip_id, taxi_id, trip_start, trip_end, trip_seconds, trip_miles,
  pickup_census_tract, dropoff_census_tract, pickup_community_area,
  dropoff_community_area, fare, tips, tolls, extras, trip_total, payment_type,
  company, pickup_centroid_latitude, pickup_centroid_longitude,
  dropoff_centroid_latitude, dropoff_centroid_longitude, community_areas
)
SELECT
  'taxi'::text,
  trip_id,
  taxis.id,
  trip_start_timestamp,
  trip_end_timestamp,
  trip_seconds,
  trip_miles,
  pickup_census_tract,
  dropoff_census_tract,
  pickup_community_area,
  dropoff_community_area,
  fare,
  tips,
  tolls,
  extras,
  trip_total,
  payment_type,
  company,
  pickup_centroid_latitude,
  pickup_centroid_longitude,
  dropoff_centroid_latitude,
  dropoff_centroid_longitude,
  community_areas
FROM taxi_trips_raw t
  INNER JOIN taxis ON t.taxi_id = taxis.external_id
ON CONFLICT DO NOTHING;

TRUNCATE TABLE taxi_trips_raw;
