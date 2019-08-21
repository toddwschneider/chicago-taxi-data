DELETE FROM trips
WHERE trip_type = 'tnp'
  AND trip_id IN (SELECT trip_id FROM tnp_trips_raw);

INSERT INTO trips
(
  trip_type, trip_id, trip_start, trip_end, trip_seconds, trip_miles,
  pickup_census_tract, dropoff_census_tract, pickup_community_area,
  dropoff_community_area, fare, tips, extras, trip_total,
  pickup_centroid_latitude, pickup_centroid_longitude,
  dropoff_centroid_latitude, dropoff_centroid_longitude,
  shared_trip_authorized, trips_pooled
)
SELECT
  'tnp'::text,
  trip_id,
  trip_start_timestamp,
  trip_end_timestamp,
  trip_seconds,
  trip_miles,
  pickup_census_tract,
  dropoff_census_tract,
  pickup_community_area,
  dropoff_community_area,
  fare,
  tip,
  additional_charges,
  trip_total,
  pickup_centroid_latitude,
  pickup_centroid_longitude,
  dropoff_centroid_latitude,
  dropoff_centroid_longitude,
  shared_trip_authorized,
  trips_pooled
FROM tnp_trips_raw
ON CONFLICT DO NOTHING;

TRUNCATE TABLE tnp_trips_raw;
