#!/bin/bash

echo "`date`: beginning raw tnp data load"
schema=`head -n 1 data/tnp_trips.csv`
cat data/tnp_trips.csv | psql chicago-taxi-data -c "COPY tnp_trips_raw (${schema}) FROM stdin CSV HEADER;"

echo "`date`: finished raw tnp data load; populating trips data"
psql chicago-taxi-data -f setup_files/populate_tnp_trips.sql

echo "`date`: populated tnp trips data"
