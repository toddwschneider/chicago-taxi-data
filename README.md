# Chicago Taxi and Transportation Network Provider Data

Code to download, process, and analyze Chicago's publicly available taxi and Transportation Network Provider (Uber/Lyft) data. Raw data comes from the City of Chicago:

- [Taxi trips](https://data.cityofchicago.org/Transportation/Taxi-Trips/wrvz-psew)
- [TNP (Uber/Lyft) trips](https://data.cityofchicago.org/Transportation/Transportation-Network-Providers-Trips/m6dm-c72p)

Used originally in support of this post: https://toddwschneider.com/posts/chicago-taxi-data/. Note that at the time that post was written, TNP data was not yet available.

This repo is something of a companion to the [nyc-taxi-data](https://github.com/toddwschneider/nyc-taxi-data) repo. The repos share some similar code and structure, but do not explicitly depend on each other.

Statistics through June 30, 2019:

- 256 million trips
  - 183 million taxi
  - 73 million TNP

## Instructions

##### 1. Install [PostgreSQL](https://www.postgresql.org/download/) and [PostGIS](https://postgis.net/install)

Both are available via [Homebrew](https://brew.sh/) on Mac OS X

##### 2. Download and import Chicago taxi/TNP data

Note: the raw taxi data is a single uncompressed 70GB+ .csv file, it will take a little while to download!

If you prefer, you can download and process either the taxi or TNP dataset without the other

```
./initialize_database.sh
./download_raw_taxi_data.sh && ./download_raw_tnp_data.sh
./import_taxi_trip_data.sh && ./import_raw_tnp_data.sh
```

##### 3. Incremental updates

New taxi data is available monthly; new TNP data quarterly. Once you've run the full setup, in the future you can download and process only the latest data by running

```
./update_taxi_trips_data.sh
./update_tnp_trips_data.sh
```

This has the advantage of not downloading the entire datasets every time you want to get the latest data

##### 3. Analysis

Within the `analysis/` subfolder, `prepare_analysis.sql` and `analysis.R` scripts to do analysis in Postgres and [R](https://www.r-project.org/)

## Some differences between Chicago and NYC taxi data

- Chicago includes anonymous taxi medallion IDs, NYC does not
- Chicago includes fare info for TNP trips, NYC's comparable FHV dataset does not
- Chicago does not include information about which TNP provided which trip, NYC does
- Chicago does not include precise location coordinates, only census tracts and community areas (and even then, only sometimes)
  - Since July 2016, NYC also does not provide precise coordinates
- Chicago does not include precise timestamps, instead rounds pickups and drop offs to 15-minute intervals

## Additional data sources included

- Chicago daily weather data [from the NCDC](https://www.ncdc.noaa.gov/cdo-web/datasets/GHCND/stations/GHCND:USW00094846/detail)
- Chicago [community area](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas-current-/cauq-8yn6) and [census tract](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Census-Tracts-2010/5jrd-6zik) shapefiles from the City of Chicago
- [NYC yellow taxi monthly data](https://www1.nyc.gov/site/tlc/about/data.page) from the NYC Taxi & Limousine Commission
- [Cubs home schedules](https://www.baseball-reference.com/teams/CHC/2016-schedule-scores.shtml) from Baseball Reference

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
