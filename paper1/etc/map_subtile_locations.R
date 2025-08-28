#!/usr/bin/env Rscript
#
# map_subtile_locations.R
# 
# Purpose:
#	To create a reference map of the final subtile locations globally.
#
# History:
#	Written by Seth Gorelik, 8/7/25
#

library(dplyr)
library(sf)
library(ggplot2)
library(rnaturalearth)

# stats for the 44 subtiles
df.44 <- read.csv('../output/stats_filtered_tiles_set1.csv', stringsAsFactors = F)

# keep the 16 subtiles used in Exp 1
map.id.list <- c(02, 05, 07, 10, 12, 13, 15, 23, 26, 27, 28, 30, 33, 37, 41, 44)

df.16 <- df.44 %>% 
	filter(map_id %in% map.id.list)

# create list of polygon geoms
poly.list <- mapply(function(xmin, xmax, ymin, ymax) {
	st_polygon(list(rbind(
		c(xmin, ymin),
		c(xmin, ymax),
		c(xmax, ymax),
		c(xmax, ymin),
		c(xmin, ymin)  # close the polygon
	)))
}, df.16$xmin, df.16$xmax, df.16$ymin, df.16$ymax, SIMPLIFY = F)

# convert to sfc object
poly.geoms <- st_sfc(poly.list, crs = 4326)

# bind with attributes
sp.16 <- st_sf(df.16, geometry = poly.geoms)

# get bounding box
roi <- sp.16 %>% 
	st_buffer(dist = 1e6) %>% 
	st_bbox %>% 
	st_as_sfc()

# get world country boundaries
world <- ne_countries(scale = 'small', returnclass = 'sf')

# create global bbox for display
create.poly <- function(lon.seq, lat.seq) {
	bottom <- cbind(lon.seq, -90)
	right <- cbind(180, lat.seq)
	top <- cbind(rev(lon.seq), 90)
	left <- cbind(-180, rev(lat.seq))
	coords <- rbind(bottom, right, top, left, bottom[1, ])
	poly <- st_polygon(list(coords)) %>% st_sfc(crs = 4326)
	return(poly)
}
lon.seq <- seq(-180, 180, by = 1)
lat.seq <- seq(-90, 90, by = 1)
globe <- create.poly(lon.seq, lat.seq)

ggplot() +
	geom_sf(data = globe, fill = 'white', color = 'black') +
	geom_sf(data = world, fill = 'gray', color = NA, linewidth = 0.3) +
	geom_sf(data = roi, fill = NA, color = 'red', linewidth = 1) +
	geom_sf(data = sp.16, fill = 'red', color = 'red') +
	coord_sf(
		crs = st_crs(8857), # equal earth
		datum = st_crs(4326),
		label_graticule = '',
		expand = T,
		clip = 'off'
	) +
	# scale_x_continuous(breaks = seq(-180, 180, by = 60)) +
	# scale_y_continuous(breaks = seq(-90, 90, by = 40)) +
	theme_minimal() +
	theme(
		plot.margin = unit(c(2, 2, 2, 2), 'lines'),
		# panel.grid.major = element_blank(),
		# panel.grid.minor = element_blank()
	)



############ testing ############
df.all <- read.csv('../output/stats_all_tiles.csv', stringsAsFactors = F)
all.poly.list <- mapply(function(xmin, xmax, ymin, ymax) {
	st_polygon(list(rbind(
		c(xmin, ymin),
		c(xmin, ymax),
		c(xmax, ymax),
		c(xmax, ymin),
		c(xmin, ymin)  # close the polygon
	)))
}, df.all$xmin, df.all$xmax, df.all$ymin, df.all$ymax, SIMPLIFY = F)
all.poly.geoms <- st_sfc(all.poly.list, crs = 4326)
sp.all <- st_sf(df.all, geometry = all.poly.geoms)

poly.44.list <- mapply(function(xmin, xmax, ymin, ymax) {
	st_polygon(list(rbind(
		c(xmin, ymin),
		c(xmin, ymax),
		c(xmax, ymax),
		c(xmax, ymin),
		c(xmin, ymin)  # close the polygon
	)))
}, df.44$xmin, df.44$xmax, df.44$ymin, df.44$ymax, SIMPLIFY = F)
sp.44 <- st_sf(df.44, geometry = st_sfc(poly.44.list, crs = 4326))

roi.44 <- sp.44 %>% 
	st_buffer(dist = 1e6) %>% 
	st_bbox %>% 
	st_as_sfc()

ggplot() +
	geom_sf(data = globe, fill = 'white', color = 'black') +
	geom_sf(data = world, fill = 'gray', color = NA, linewidth = 0.3) +
	geom_sf(data = roi.44, fill = NA, color = 'red', linewidth = 1) +
	geom_sf(data = sp.44, fill = 'red', color = 'red') +
	coord_sf(
		crs = st_crs(8857), # equal earth
		datum = st_crs(4326),
		label_graticule = '',
		expand = T,
		clip = 'off'
	) +
	# scale_x_continuous(breaks = seq(-180, 180, by = 60)) +
	# scale_y_continuous(breaks = seq(-90, 90, by = 40)) +
	theme_minimal() +
	theme(
		plot.margin = unit(c(2, 2, 2, 2), 'lines'),
		# panel.grid.major = element_blank(),
		# panel.grid.minor = element_blank()
	)

