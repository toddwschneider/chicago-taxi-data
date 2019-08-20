#!/bin/bash

ts=$(psql -P t -P format=unaligned -d chicago-taxi-data -c "SELECT date(max(trip_start) - '2 days'::interval) FROM trips WHERE trip_type = 'tnp'")
url="https://data.cityofchicago.org/resource/m6dm-c72p.csv?%24where=trip_start_timestamp%20>=%20'${ts}'&%24limit=1000000000"

echo "downloading updated tnp data from ${url}"
wget -O data/tnp_trips.csv ${url}

./import_tnp_trip_data.sh
