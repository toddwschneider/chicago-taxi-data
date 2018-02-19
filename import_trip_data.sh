#!/bin/bash

echo "`date`: beginning raw data load"
schema=`head -n 1 data/taxi_trips.csv | tr -s ' ' | tr ' ' '_' | tr '[:upper:]' '[:lower:]'`
cat data/taxi_trips.csv | psql chicago-taxi-data -c "COPY trips_raw (${schema}) FROM stdin CSV HEADER;"

echo "`date`: finished raw data load; populating trips data"
psql chicago-taxi-data -f populate_trips.sql

echo "`date`: populated trips data"
