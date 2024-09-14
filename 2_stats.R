#!/usr/bin/env Rscript

library(parallel)
library(foreach)
library(iterators)
library(doMC)
library(sp)
library(raster)
library(spdep)

setwd('~/data/uw/tiles/')
dir.create('csv', showWarnings = FALSE)

tiles <- list.files(pattern = '\\.tif$')

# for testing spatial autocorrelation, each tile will need the neighbor list for grid cells
# so we'll use the Queen’s case (a 3x3 neighborhood)
nb <- cell2nb(200, 200, type = 'queen')
lw <- nb2listw(nb, style = 'W') # convert neighbors to a spatial weights list

nc <- parallel::detectCores() - 1
registerDoMC(nc)

df <- foreach(i = 1:length(tiles), .combine = rbind, .packages = c('raster')) %dopar% {

	f.tile <- tiles[i]
	h <- strsplit(f.tile, split = '\\_|\\.')[[1]][6]
	v <- strsplit(f.tile, split = '\\_|\\.')[[1]][7]
	
	r.tile <- raster(f.tile)
	v.tile <- values(r.tile)
	v.tile[is.na(v.tile)] <- 0
	v.num.samples.gt0 <- length(v.tile[v.tile > 0])
	v.pct.samples.gt0 <- (v.num.samples.gt0/length(v.tile)) * 100
	
	# check that 95% of cells contain useful data
	if (v.pct.samples.gt0 > 80) {
		
		# get descriptive stats
		v.min <- min(v.tile)
		v.max <- max(v.tile)
		v.mean <- mean(v.tile)
		v.median <- median(v.tile)

		# normalize values from 0 to 100
		v.tile.norm <- ((v.tile - v.min) / (v.max - v.min)) * 100
		
		# test for uniform distribution using chi-square test
		brks <- seq(0, 100, length.out = 11) # define bin breaks
		obs <- hist(v.tile.norm, breaks = brks, plot = F)$counts # create the observed frequencies for the bins
		exp <- rep(mean(obs), length(obs)) # expected frequencies for uniform distribution
		chi <- chisq.test(x = obs, p = exp, rescale.p = T) # perform the chi-square test
		uniform.flag <- !(chi$p.value <= 0.05) # if p-value is small, there is significant evidence to suggest that the data does NOT follow a uniform distribution

		# test for spatial autocorrelation
		v.moran.test <- moran.test(v.tile, lw, alternative = 'two.sided')
		v.moran <- unname(v.moran.test$estimate[1]) # indicates direction of spatial autocorrelation
		autocorr.flag <- (v.moran.test$p.value <= 0.05) # if p-value is small, the spatial autocorrelation is statistically significant
		
		# note on Moran's I interpretation (if statistically significant):
		#  positive = clustering of similar values
		#  negative = dispersion of similar values
		#  close to zero = randomly distributed across space (no spatial autocorrelation)
		
	} else {
		
		v.min <- NA
		v.max <- NA
		v.mean <- NA
		v.median <- NA
		uniform.flag <- NA
		autocorr.flag <- NA
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
		uniform = uniform.flag,
		autocorr = autocorr.flag,
		moran = v.moran,
		n = v.num.samples.gt0,
		pct = v.pct.samples.gt0
	)
	
	write.csv(df.tmp, file = paste0('csv/', gsub('.tif', '.csv', f.tile)), row.names = F)
	
	return(df.tmp)
	
}

f.csv <- '~/repos/uw/tile_stats_V6.csv'
cat(paste('Writing', f.csv, '...\n'))
write.csv(df, file = f.csv, row.names = F)
