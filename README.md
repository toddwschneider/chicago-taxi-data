# Chicago Taxi Data

Used in support of this post: http://toddwschneider.com/posts/chicago-taxi-data/

Code to download, process, and analyze [Chicago's publicly available taxi data](http://digital.cityofchicago.org/index.php/chicago-taxi-data-released/).

Something of a companion to the [nyc-taxi-data](https://github.com/toddwschneider/nyc-taxi-data) repo. The repos share some similar code and structure, but do not explicitly depend on each other.

## Instructions

##### 1. Install [PostgreSQL](http://www.postgresql.org/download/) and [PostGIS](http://postgis.net/install)

Both are available via [Homebrew](http://brew.sh/) on Mac OS X

##### 2. Download and import Chicago taxi data

```
./download_raw_data.sh
./initialize_database.sh
./import_trip_data.sh
```

##### 3. Analysis

`prepare_analysis.sql` and `analysis.R` scripts to do analysis in Postgres and [R](https://www.r-project.org/)

## Some differences between Chicago and NYC taxi data

- Chicago includes anonymous medallion id, New York does not
- Chicago does not include precise location coordinates, only census tracts and community areas (and even then, only sometimes)
- Chicago does not include precise timestamps, instead rounds pickups and drop offs to 15-minute intervals
- Chicago does not include any data from ridesharing companies like Uber and Lyft
- Chicago contains just over 100 million rows, making it significantly smaller than NYC's 1.3 billion rows
- Chicago requires significantly less preprocessing and has fewer unexplained data abnormalities than the NYC data.

The last two points in particular suggest that the Chicago dataset is easier to work with than the NYC dataset

## Additional data sources included

- Chicago daily weather data [from the NCDC](https://www.ncdc.noaa.gov/cdo-web/datasets/GHCND/stations/GHCND:USW00094846/detail)
- Chicago [community area](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas-current-/cauq-8yn6) and [census tract](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Census-Tracts-2010/5jrd-6zik) shapefiles from the City of Chicago
- [NYC yellow taxi monthly data](http://www.nyc.gov/html/tlc/html/about/statistics.shtml) from the NYC Taxi & Limousine Commission
- [Cubs home schedules](http://www.baseball-reference.com/teams/CHC/2016-schedule-scores.shtml) from Baseball Reference

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
