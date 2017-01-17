#!/bin/bash

createdb chicago-taxi-data

psql chicago-taxi-data -f create_schema.sql

shp2pgsql -d -I community_areas/community_areas.shp | psql -d chicago-taxi-data
shp2pgsql -d -I census_tracts/census_tracts.shp | psql -d chicago-taxi-data

cat data/chicago_weather_data.csv | psql chicago-taxi-data -c "COPY weather_observations FROM stdin WITH CSV HEADER;"
psql chicago-taxi-data -c "UPDATE weather_observations SET average_wind_speed = NULL WHERE average_wind_speed = -9999;"

cat data/cubs_home_games.csv |  psql chicago-taxi-data -c "COPY cubs_home_games FROM stdin WITH CSV HEADER;"
