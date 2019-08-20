CREATE EXTENSION postgis;

CREATE UNLOGGED TABLE taxi_trips_raw (
  trip_id text,
  taxi_id text,
  trip_start_timestamp timestamp without time zone,
  trip_end_timestamp timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract text,
  dropoff_census_tract text,
  pickup_community_area int,
  dropoff_community_area int,
  fare numeric,
  tips numeric,
  tolls numeric,
  extras numeric,
  trip_total numeric,
  payment_type text,
  company text,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  pickup_centroid_location text,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  dropoff_centroid_location text,
  community_areas int
);

CREATE UNLOGGED TABLE tnp_trips_raw (
  trip_id text,
  trip_start_timestamp timestamp without time zone,
  trip_end_timestamp timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract text,
  dropoff_census_tract text,
  pickup_community_area int,
  dropoff_community_area int,
  fare numeric,
  tip numeric,
  additional_charges numeric,
  trip_total numeric,
  shared_trip_authorized boolean,
  trips_pooled int,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  pickup_centroid_location text,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  dropoff_centroid_location text
);

CREATE TABLE taxis (
  id serial primary key,
  external_id text
);

CREATE UNIQUE INDEX ON taxis (external_id);

CREATE UNLOGGED TABLE trips (
  trip_type text,
  trip_id text,
  taxi_id int,
  trip_start timestamp without time zone,
  trip_end timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract text,
  dropoff_census_tract text,
  pickup_community_area int,
  dropoff_community_area int,
  fare numeric,
  tips numeric,
  tolls numeric,
  extras numeric,
  trip_total numeric,
  payment_type text,
  company text,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  community_areas int,
  shared_trip_authorized boolean,
  trips_pooled int
);

CREATE TABLE weather_observations (
  station_id text,
  station_name text,
  date date,
  precipitation numeric,
  snow_depth numeric,
  snowfall numeric,
  max_temperature numeric,
  min_temperature numeric,
  average_wind_speed numeric
);

CREATE UNIQUE INDEX ON weather_observations (date, station_id);

CREATE TABLE cubs_home_games (
  season int,
  date date,
  opponent text,
  cubs_won boolean,
  day_game boolean,
  attendance numeric,
  winning_pct numeric,
  postseason boolean
);
