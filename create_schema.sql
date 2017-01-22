CREATE EXTENSION postgis;

CREATE TABLE trips_raw (
  trip_id varchar primary key,
  taxi_id varchar,
  trip_start_timestamp timestamp without time zone,
  trip_end_timestamp timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract varchar,
  dropoff_census_tract varchar,
  pickup_community_area int,
  dropoff_community_area int,
  fare varchar,
  tips varchar,
  tolls varchar,
  extras varchar,
  trip_total varchar,
  payment_type varchar,
  company varchar,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  pickup_centroid_location varchar,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  dropoff_centroid_location varchar,
  community_areas int
);

CREATE TABLE taxis (
  id serial primary key,
  external_id varchar
);

CREATE UNIQUE INDEX idx_taxis_on_external_id ON taxis (external_id);

CREATE TABLE trips (
  trip_id varchar primary key,
  taxi_id int,
  trip_start timestamp without time zone,
  trip_end timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract varchar,
  dropoff_census_tract varchar,
  pickup_community_area int,
  dropoff_community_area int,
  fare numeric,
  tips numeric,
  tolls numeric,
  extras numeric,
  trip_total numeric,
  payment_type varchar,
  company varchar,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  community_areas int
);

CREATE TABLE weather_observations (
  station_id varchar,
  station_name varchar,
  date date,
  precipitation numeric,
  snow_depth numeric,
  snowfall numeric,
  max_temperature numeric,
  min_temperature numeric,
  average_wind_speed numeric
);

CREATE UNIQUE INDEX index_weather_observations ON weather_observations (date, station_id);

CREATE TABLE cubs_home_games (
  season int,
  date date,
  opponent varchar,
  cubs_won boolean,
  day_game boolean,
  attendance numeric,
  winning_pct numeric,
  postseason boolean
);
