#!/usr/bin/env Rscript
#
# 3_filter_tiles.R
# 
# Purpose:
#	To determine which tiles to use as stimuli, and compile single CSV of the
#	values for all tiles, i.e., each row contains all 1,000,000 values for a single
#	tile.
#
# History:
#	Written by Seth Gorelik, 9/22/24
#	Updated by Seth Gorelik, 10/6/24, to filter 30m tiles
#

source('etc/functions.R')

# read in table of tile stats
df <- read.csv('output/stats_all_tiles.csv', stringsAsFactors = F)

# bin count under uniform distribution
uniform.bin.cnt <- 1000*1000/9

# set lower and upper bounds for bin counts
lwr.cnt <- uniform.bin.cnt * (2/3)
upr.cnt <- uniform.bin.cnt * (4/3)

# filter tiles
df.f <- df %>%
	
	# remove tiles with NAs
	filter(na_cnt == 0) %>% 
	
	# remove tiles with skewed distribution
	filter((median_rscd > 40) & (median_rscd < 60)) %>% 
	
	# remove tiles with very low or very high bin counts
	filter(min_hist_cnt > lwr.cnt & max_hist_cnt < upr.cnt) %>% 
	
	# sort by std
	arrange(std_hist_cnt)

# number of tiles after filters
nrow(df.f)

# view tiles
df.f %>% 
	select(file, median_rscd, min_hist_cnt, max_hist_cnt, std_hist_cnt, range_hist_cnt)


# plot.results(paste0('tile_00N_020E_subtile_24000_39000', '.tif'))

# pretty ones form the amazon:
# tile_00N_060W_subtile_37000_04000.tif - so cool! rivers!
# tile_00N_060W_subtile_39000_04000.tif
# tile_00N_060W_subtile_36000_05000.tif

# gray color scale
gray.pal <- c('#FFFFFF', '#F0F0F0', '#E0E0E0', '#CECECE', '#BABABA', '#A3A3A3', '#888888', '#636363', '#000000')

# export all maps to single pdf
pdf(paste0('output/maps_', nrow(df.f), '_grayscale.pdf'), paper = 'letter', onefile = T)
for (i in 1:nrow(df.f)) {
	f <- df.f$file[i]
	cat(paste0(i, '. ', f), fill = T)
	plot.results(f, pal = gray.pal, with_hist = F, with_legend = F)
}
dev.off()

# export all tile values to single csv
csv.out <- paste0('output/values_', nrow(df.f), '_tiles.csv')
for (i in 1:nrow(df.f)) {
	f <- df.f$file[i]
	cat(paste0(i, '. ', f), fill = T)
	r <- get.rescaled.raster(f)
	v <- round2(values(r))
	row <- paste0(f, ',', paste0(v, collapse = ','))
	write(row, file = csv.out, append = T)
}

# offload to bucket (it's ~124MB)
system(paste('gsutil -m cp', csv.out, 'gs://uw-ks-data/harris30m/'), ignore.stdout = T, ignore.stderr = T)

