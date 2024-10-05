#!/bin/bash

mkdir -p tiles

tail -n +2 Aboveground_Live_Woody_Biomass_Density.csv | while read ROW
do
    
    # get tile id
    TILEID=$(echo $ROW | cut -d ',' -f 1)
    TILEPATH="tiles/tile_${TILEID}.tif"
    echo "$TILEPATH"
    
    # get tile url
    URL=$(echo $ROW | cut -d ',' -f 2)
    echo "$URL"
    
    # download tile
    wget --output-document=$TILEPATH $URL
    
done

