#!/bin/bash

createdb chicago-taxi-data

psql chicago-taxi-data -f setup_files/create_schema.sql

shp2pgsql -d -I shapefiles/community_areas/community_areas.shp | psql -d chicago-taxi-data
shp2pgsql -d -I shapefiles/census_tracts/census_tracts.shp | psql -d chicago-taxi-data

weather_schema="station_id, station_name, date, average_wind_speed, precipitation, snowfall, snow_depth, max_temperature, min_temperature"
cat data/chicago_weather_data.csv | psql chicago-taxi-data -c "COPY weather_observations (${weather_schema}) FROM stdin WITH CSV HEADER;"
psql chicago-taxi-data -c "UPDATE weather_observations SET average_wind_speed = NULL WHERE average_wind_speed = -9999;"

cat data/cubs_home_games.csv |  psql chicago-taxi-data -c "COPY cubs_home_games FROM stdin WITH CSV HEADER;"
