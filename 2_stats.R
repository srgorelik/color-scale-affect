#!/usr/bin/env Rscript

library(parallel)
library(foreach)
library(iterators)
library(doMC)
library(sp)
library(raster)

setwd('~/data/uw/tiles/')

tiles <- list.files()

# set.seed(1)
# tiles.sample <- sample(tiles, size = 10, replace = F)

nc <- parallel::detectCores() - 1
registerDoMC(nc)

df <- foreach(i = 1:length(tiles), .combine = rbind, .packages = c('raster')) %dopar% {

	f.tile <- tiles[i]
	h <- strsplit(f.tile, split = '\\_|\\.')[[1]][6]
	v <- strsplit(f.tile, split = '\\_|\\.')[[1]][7]
	
	r.tile <- raster(f.tile)
	v.tile <- getValues(r.tile)
	v.num.samples <- sum(!is.na(v.tile))
	
	if (v.num.samples > 0) {
		v.min <- min(v.tile, na.rm = T)
		v.max <- max(v.tile, na.rm = T)
		v.mean <- mean(v.tile, na.rm = T)
		v.median <- median(v.tile, na.rm = T)
		v.moran <- Moran(r.tile)
	} else {
		v.min <- NA
		v.max <- NA
		v.mean <- NA
		v.median <- NA
		v.moran <- NA
	}
	
	df.tmp <- data.frame(
		file = f.tile,
		h = h,
		v = v,
		xmin = xmin(r.tile),
		xmax = xmax(r.tile),
		ymin = ymin(r.tile),
		ymax = ymax(r.tile),
		min = v.min,
		max = v.max,
		mean = v.mean,
		median = v.median,
		moran = v.moran,
		n = v.num.samples
	)
	
	return(df.tmp)
	
}


