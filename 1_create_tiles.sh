#!/bin/bash
set -e

# 1_create_tiles.sh
#
# Purpose:
#	To download Harris et al. 2021 (Nature Climate Change) 30m aboveground biomass 
#	tiles (40,000 x 40,000 pixels) and split them in smaller (1,000 x 1,000 pixel) 
#	tiles, only keeping subtiles that have valid data pixels.
#
# History:
#	written by seth gorelik, 10/5/25
#
# Notes:
#	downloaded tile list from:
#	https://data.globalforestwatch.org/datasets/gfw::aboveground-live-woody-biomass-density/about
#

# set output directory
OUTPUT_DIR=~/data/harris30m/tiles
mkdir -p $OUTPUT_DIR
echo "Output Directory: $OUTPUT_DIR"

# loop through list of tiles
tail -n +2 etc/Aboveground_Live_Woody_Biomass_Density.csv | while read ROW
do

    # get tile id
    BIGTILE_ID=$(echo $ROW | cut -d ',' -f 1)
    
    # set output tile path
    BIGTILE_FILE=~/data/harris30m/harris_"$BIGTILE_ID".tif

    # get tile url
    URL=$(echo $ROW | cut -d ',' -f 2)

    # download tile
    wget --quiet --output-document=$BIGTILE_FILE $URL
    
    # split the big tile even further into subtiles
    ./etc/split_bigtile.sh $BIGTILE_ID $BIGTILE_FILE $OUTPUT_DIR
    
    # upload subtiles to bucket
    gsutil -m cp $OUTPUT_DIR/*.tif gs://uw-ks-data/harris30m/tiles1000/ &> /dev/null
    
    # delete tile and subtiles
    rm $BIGTILE_FILE $OUTPUT_DIR/*.tif
    
done


