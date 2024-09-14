#!/usr/bin/env Rscript

library(sf)
library(dplyr)

setwd('~/data/uw/tiles100')

df.tiles <- read.csv('~/repos/uw/tile_stats_V6.csv', stringsAsFactors = F)

sp.tiles <- df.tiles %>%
	rowwise() %>%
	mutate(geometry = list(st_polygon(list(matrix(c(xmin, ymin, xmin, ymax, xmax, ymax, xmax, ymin, xmin, ymin), ncol = 2, byrow = T))))) %>%
	ungroup() %>% 
	st_as_sf(crs = '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs')

st_write(sp.tiles, 'tile_grid_200x200pxl.shp')
