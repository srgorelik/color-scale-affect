#!/usr/bin/env Rscript
#
# 4_final_csv_output.R
# 
# Purpose:
#
# History:
#	Written by Seth Gorelik, 10/17/24
#

source('etc/functions.R')

# final list of maps from karen
map.id.list <- c(02, 05, 07, 10, 12, 13, 15, 23, 26, 27, 28, 30, 33, 37, 41, 44)
num.maps <- length(map.id.list) # 16

# get initial tile set
df <- read.csv('output/stats_filtered_tiles_set1.csv', stringsAsFactors = F)
nrow(df) # 44

# get geotiff assocaited with each map id
df.f <- df %>% 
	filter(map_id %in% map.id.list) %>% 
	select(map_id, file)

# double check number of maps
stopifnot(nrow(df.f) == num.maps)

# export map values to single csv
csv.out <- paste0('output/all_values_for_', num.maps, '_maps.csv')
for (i in 1:num.maps) {
	
	cat(paste0('Map ', i, '/', num.maps, ':'), fill = T)
	
	map.id <- df.f$map_id[i]
	cat(paste(' Map ID:', map.id), fill = T)

	inp.tif <- df.f$file[i]
	cat(paste(' Input:', inp.tif), fill = T)
	
	# get raster values, rescaled and converted to integer vector
	r <- get.rescaled.raster(inp.tif)
	v <- round2(values(r))
	
	# write map id and values to row of output csv on disk
	row <- paste0(map.id, ',', paste0(v, collapse = ','))
	write(row, file = csv.out, append = T)
}
