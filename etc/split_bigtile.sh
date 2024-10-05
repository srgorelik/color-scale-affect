#!/bin/bash
set -e

# written by seth gorelik, 10/5/25

# get parameters
BIGTILE_ID="$1"
BIGTILE_FILE="$2"
OUTPUT_DIR="$3"

# make sure input file exists
if [ -f "$BIGTILE_FILE" ]; then
	echo "Splitting $BIGTILE_FILE ..."
else
	echo "  ERROR: File not found: $BIGTILE_FILE"
	exit 1
fi

# make sure output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
	echo "  ERROR: Directory doesn't exist: $OUTPUT_DIR"
	exit 1
fi

# dimensions of input raster
BIGTILE_WIDTH=40000
BIGTILE_HEIGHT=40000

# set output tile size
SUBTILE_SIZE=1000

# set number of cores to use
NUM_CPU=$(nproc --all)
NUM_CPU2=$(expr $NUM_CPU - 2)

# function to process each tile
process_tile() {
	
	# get parameters
	BIGTILE_FILE=$1
	SUBTILE_ID=$2
	SUBTILE_SIZE=$3
	X_OFFSET=$4
	Y_OFFSET=$5
	OUTPUT_DIR=$6
	
	# set output subtile name
	SUBTILE_FILE="${OUTPUT_DIR}/subtile_${SUBTILE_ID}.tif"
	
	# create tile
	gdal_translate -of GTiff -ot UInt16 -a_nodata 0 -co "COMPRESS=LZW" -srcwin "$X_OFFSET" "$Y_OFFSET" "$SUBTILE_SIZE" "$SUBTILE_SIZE" "$BIGTILE_FILE" "$SUBTILE_FILE" &> /dev/null

	# compute stats
	gdal_edit.py -stats "$SUBTILE_FILE" &> /dev/null

	# remove tile if it contains only nodata values
	if [ $(gdalinfo "$SUBTILE_FILE" | grep "STATISTICS_VALID_PERCENT" | cut -d "=" -f 2) == 0 ]; then
		rm "$SUBTILE_FILE"
	fi
	
}

export -f process_tile

# create subtiles in parallel
for ((Y = 0; Y < $BIGTILE_HEIGHT; Y += $SUBTILE_SIZE)); do
	for ((X = 0; X < $BIGTILE_WIDTH; X += $SUBTILE_SIZE)); do
		
		# pad the x and y values to 5 digits
		PADDED_X=$(printf "%05d" "$X")
		PADDED_Y=$(printf "%05d" "$Y")
		SUBTILE_ID="${PADDED_X}_${PADDED_Y}"
		
		X_OFFSET=$X
		Y_OFFSET=$Y
		
		# print to stdout for parallel to read
		echo "$BIGTILE_FILE,$SUBTILE_ID,$SUBTILE_SIZE,$X_OFFSET,$Y_OFFSET,$OUTPUT_DIR"
		
	done
done | parallel -j $NUM_CPU2 --colsep ',' 'process_tile {1} {2} {3} {4} {5} {6}'
