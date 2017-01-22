#!/bin/bash

ts=$(psql -P t -P format=unaligned -d chicago-taxi-data -c "SELECT date(max(trip_start) - '2 days'::interval) FROM trips")
url="https://data.cityofchicago.org/resource/wrvz-psew.csv?%24where=trip_start_timestamp%20>=%20'${ts}'&%24limit=1000000000"

echo "downloading data from ${url}"
wget -O data/taxi_trips.csv ${url}

./import_trip_data.sh
