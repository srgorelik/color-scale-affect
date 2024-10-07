#!/usr/bin/env Rscript
#
# 4_plot_maps.R
# 
# Purpose:
#	This script will export maps with the user-provided color scale as
#	PNG files to the user-provided output directory. The output files
#	will have the following naming convention:
#		"[color scale name]_[tile name].png"
#
# History:
#	Written by Seth Gorelik, 9/22/24
#	Updated by Seth Gorelik, 10/6/24, to plot 30m tiles
#
# ====================================================================
# USER SETTINGS
# ====================================================================

# replace with 9 colors (as hex codes) from Color Crafter: https://danielleszafir.com/ColorCrafter/
color.scale.hex <- c('#FFFFFF', '#F0F0F0', '#E0E0E0', '#CECECE', '#BABABA', '#A3A3A3', '#888888', '#636363', '#000000')

# give color scale a code name
color.scale.name <- 'gray'

# set path to input CSV file
inp.csv <- 'output/values_44_tiles.csv'

# set output directory
out.dir <- '~/projects/uw/output_grayscale_maps/'

# ====================================================================
# DON'T CHANGE CODE BELOW
# ====================================================================

# input table of map values (one row per map)
df <- data.table::fread(file = inp.csv, header = F, data.table = F)

# create user-provided output directory if it doesn't exist
dir.create(out.dir, showWarnings = F)

# loop through maps
for (i in 1:nrow(df)) {

	# create map name, from input raster file name
	map.name <- paste0(out.dir, color.scale.name, '_', sprintf("%02d", i), '.png')
	cat(paste('Writing', map.name, '...'), fill = T)
	
	# get map values, transform into matrix
	v <- as.numeric(df[i, -1])
	m <- matrix(data = v, nrow = 1000, ncol = 1000)
	mr <- apply(m, 1, rev)
	mrt <- t(mr)
	
	# save map to PNG file in output directory, applying user-provided color scale
	png(filename = map.name, width = 1000, height = 1000, units = 'px')
	par(mar = c(0, 0, 0, 0))
	image(mrt, axes = F, asp = 1, useRaster = T, col = color.scale.hex)
	dev.off()
	
}
