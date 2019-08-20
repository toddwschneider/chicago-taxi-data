#!/bin/bash

echo "`date`: beginning raw taxi data load"
schema=`head -n 1 data/taxi_trips.csv | tr -s ' ' | tr ' ' '_' | tr '[:upper:]' '[:lower:]'`
cat data/taxi_trips.csv | psql chicago-taxi-data -c "COPY taxi_trips_raw (${schema}) FROM stdin CSV HEADER;"

echo "`date`: finished raw taxi data load; populating trips data"
psql chicago-taxi-data -f setup_files/populate_taxi_trips.sql

echo "`date`: populated taxi trips data"
