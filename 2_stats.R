#!/usr/bin/env Rscript

library(parallel)
library(foreach)
library(iterators)
library(doMC)
library(sp)
library(raster)
library(spdep)

setwd('~/data/uw/tiles100')

csv.dir <- 'csv'
dir.create(csv.dir, showWarnings = F)

tiles <- list.files(pattern = '\\.tif$')

# for testing spatial autocorrelation, each tile will need the neighbor list for grid cells
# so we'll use the Queen’s case (a 3x3 neighborhood)
# nb <- cell2nb(200, 200, type = 'queen')
# lw <- nb2listw(nb, style = 'W') # convert neighbors to a spatial weights list

registerDoMC(parallel::detectCores() - 1)

df <- foreach(i = 1:length(tiles), .combine = rbind, .packages = c('raster')) %dopar% {

	f.tile <- tiles[i]
	f.split <- strsplit(f.tile, split = '\\_|\\.')[[1]]
	h <- f.split[length(f.split)-2]
	v <- f.split[length(f.split)-1]
	
	r.tile <- raster(f.tile)
	v.tile <- values(r.tile)
	
	na.index <- is.na(v.tile)
	na.count <- sum(na.index)
	v.tile[na.index] <- 0
	num.samples.gt0 <- length(v.tile[v.tile > 0])
	pct.samples.gt0 <- (num.samples.gt0/length(v.tile)) * 100
	
	df.tmp <- data.frame(
		file = f.tile,
		h = h,
		v = v,
		xmin = xmin(r.tile),
		xmax = xmax(r.tile),
		ymin = ymin(r.tile),
		ymax = ymax(r.tile),
		min_mgha = NA,
		max_mgha = NA,
		mean_mgha = NA,
		median_mgha = NA,
		rmsd = NA,
		chisq_stat = NA,
		chisq_pval = NA,
		ks_stat = NA,
		ks_pval = NA,
		# moran_stat = NA,
		# moran_pval = NA,
		# gearys_stat = NA,
		# gearys_pval = NA,
		# n = num.samples.gt0,
		# pct = pct.samples.gt0,
		na_count = na.count
	)
	
	# check that a high percent of cells contain useful data
	if (pct.samples.gt0 > 85) {

		# get descriptive stats
		df.tmp$min_mgha <- min(v.tile)
		df.tmp$max_mgha <- max(v.tile)
		df.tmp$mean_mgha <- mean(v.tile)
		df.tmp$median_mgha <- median(v.tile)

		# normalize values from 0 to 100
		v.tile.norm <- ((v.tile - df.tmp$min_mgha) / (df.tmp$max_mgha - df.tmp$min_mgha)) * 100

		# --------------------------------------------
		# tests for uniform distribution
		# --------------------------------------------
		
		# chi-square test:
		# if p-value is small, there is significant evidence to suggest that the data does NOT follow a uniform distribution: uniform.flag <- !(chi$p.value <= 0.05)
		brks <- seq(0, 100, length.out = 9) # define bin breaks
		obs <- hist(v.tile.norm, breaks = brks, plot = F)$counts # create the observed frequencies for the bins
		exp <- rep(mean(obs), length(obs)) # expected frequencies for uniform distribution
		chisq.test.results <- chisq.test(x = obs, p = exp, rescale.p = T) # perform the chi-square test
		df.tmp$chisq_stat <- unname(chisq.test.results$statistic)
		df.tmp$chisq_pval <- chisq.test.results$p.value
		
		# root mean square deviation (RMSD)
		df.tmp$rmsd <- sqrt(mean((obs - exp)^2))
		
		# kolmogorov-smirnov (ks) test (requires slight jittering to avoid duplicate values)
		# ks statistic:
		#   close to 0 = the empirical and theoretical distributions are identical (perfect match)
		#   close to 1 = the largest possible discrepancy between the empirical and theoretical distributions
		# thus:
		#   small ks stat and large p-value = close to a uniform distribution
		#	large ks stat and small p-value = NOT close to a uniform distribution
		v.tile.norm_jittered <- jitter(v.tile.norm, amount = 1e-8)  # adds small random noise
		ks.test.results <- ks.test(v.tile.norm_jittered, 'punif', min = 0, max = 100)
		df.tmp$ks_stat <- unname(ks.test.results$statistic)
		df.tmp$ks_pval <- ks.test.results$p.value
		
		# --------------------------------------------
		# tests for spatial autocorrelation
		# --------------------------------------------
		
		# moran's i (ranges from -1 to 1):
		#   >0 = positive spatial autocorrelation (clustering of similar values)
		#   ≈0 = no spatial autocorrelation (randomly distributed across space)
		#   <0 = degative spatial autocorrelation (dispersion of similar values)
		# if p-value is small, the spatial autocorrelation is statistically significant
		# moran.test.results <- moran.test(v.tile, lw, alternative = 'two.sided')
		# df.tmp$moran_stat <- unname(moran.test.results$estimate[1])
		# df.tmp$moran_pval <- moran.test.results$p.value
		
		# geary's c (ranges from 0 to 2):
		#   <1 = positive spatial autocorrelation (clustering of similar values)
		#   ≈1 = no spatial autocorrelation (randomly distributed across space)
		#   >1 = negative spatial autocorrelation (dispersion of similar values)
		# if p-value is small, the spatial autocorrelation is statistically significant
		# gearys.test.results <- geary.test(v.tile, lw, alternative = 'two.sided')
		# df.tmp$gearys_stat <- unname(gearys.test.results$estimate[1])
		# df.tmp$gearys_pval <- gearys.test.results$p.value
		
	}
	
	write.csv(df.tmp, file = paste0(csv.dir, '/', gsub('.tif', '.csv', f.tile)), row.names = F)
	
	return(df.tmp)
	
}

f.csv <- '~/repos/uw/results/tile_stats_100G_V1.csv'
cat(paste('Writing', f.csv, '...\n'))
write.csv(df, file = f.csv, row.names = F)
