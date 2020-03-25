# Chicago ride-hail surge pricing analysis

Code in support of this post: [Reverse Engineering Ride-Hail Surge Pricing Trends in Chicago](https://toddwschneider.com/posts/chicago-ridehail-surge-pricing/)

## Usage

1. Download and import the TNP trips data file following the instructions in the root directory of this repo
2. Export trips to csv: `psql chicago-taxi-data -f export_trips_to_csv.sql`
3. Assorted R scripts can be run interactively from R terminal. `estimate_historical_surge_pricing.R` should be run first

## Data on Amazon S3

The exact `chicago_trips_20181101_20191231.csv` file I used for my post is available for download from a requester pays Amazon S3 bucket:

https://chicago-ridehail-data.s3.amazonaws.com/chicago_trips_20181101_20191231.csv.gz

The data is from Nov 1, 2018 through Dec 31, 2019, and around 11 GB as an uncompressed csv. [See here](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) for instructions on how to download from a requester pays S3 bucket.

## Note about performance and memory usage

The code is generally not optimized for performance or memory footprint. For example, although it uses `data.table::fread()` to read the csv file, it then uses `tidyverse` tibbles and `dplyr` the rest of the way. It would probably improve performance and memory footprint to use `data.table` more extensively. There are also plenty of extra variables that could be omitted. But the easiest solution is to throw more RAM at the problem...

I ran the code on a local machine with 64 GB RAM. If you need more RAM, I'd recommend Louis Astett's [RStudio AWS AMI](http://www.louisaslett.com/RStudio_AMI/). I was able to run the code on an r5.4xlarge EC2 instance. You could also try the [googleComputeEngineR package](https://cloudyr.github.io/googleComputeEngineR/), though I have not personally worked with it.
