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

library(raster)
library(dplyr)
library(ggplot2)
library(patchwork)
library(ggh4x)
library(scales)
library(viridis)

df <- read.csv('results/tile_stats_1000px_V1.csv')

df.results <- df %>%
	mutate(
		# mean_norm = ((mean_mgha - min_mgha) / (max_mgha - min_mgha)) * 100,
		median_norm = ((median_mgha - min_mgha) / (max_mgha - min_mgha)) * 100
	) %>%
	filter((na_count == 0) & (median_norm > 40) & (median_norm < 60)) %>%

	rowwise() %>%
	mutate(
		# bind_cols(get.hist.cnts(file)),
		# bins_std = sd(c_across(c(starts_with('bin_'))))
		bind_cols(get.hist.range(file))
	) %>%
	ungroup() %>%

	arrange(bin_range) %>%
	select(file, bin_min, bin_max, bin_std, bin_range)

nrow(df.results)
print(df.results, n = 50)

plot(df.results$bin_std, df.results$bin_range)

e <- 100*100/9

df.p <- df.results %>%
	filter(bin_min > (e*1/3) & bin_max < (e*5/3)) %>%
	arrange(bin_std) %>%
	as.data.frame()


plot.results <- function(f, i = NULL, n = NULL) {
	
	# prep data
	r <- raster(paste0('~/data/harris30m/', f))
	r[is.na(r)] <- 0
	v <- values(r)
	v.norm <- ((v - min(v)) / (max(v) - min(v))) * 100
	values(r) <- v.norm
	names(r) <- 'value'
	r.df <- as.data.frame(r, xy = T)
	
	brks <- seq(0, 100, length.out = 10)
	r.hist <- hist(r, breaks = brks, plot = F)
	cnts <- r.hist$counts
	mids <- r.hist$mids
	
	title <- ifelse(is.null(i) | is.null(n), '', paste0(i, '/', n))
	
	p1 <- ggplot() +
		geom_col(aes(x = mids, y = cnts), color = 'black', fill = 'gray', width = brks[2]) + 
		scale_x_continuous(guide = guide_axis_truncated(), breaks = seq(0, 100, by = 20)) +
		scale_y_continuous(guide = guide_axis_truncated(trunc_lower = min, trunc_upper = max), labels = comma) + 
		expand_limits(y = max(cnts)+400) +
		labs(x = NULL, y = NULL, title = title, subtitle = f) +
		coord_fixed(ratio = 50/max(cnts), clip = 'off') +
		theme_classic() +
		theme(
			axis.text = element_text(size = 12),
			axis.ticks.length = unit(8, 'points'),
			plot.title = element_text(hjust = 0.5, face = 'bold'),
			plot.subtitle = element_text(hjust = 0.5)
		)
	
	p2 <- ggplot(data = r.df, aes(x = x, y = y, fill = value)) +
		geom_raster() +
		scale_fill_gradientn(colors = viridis(256, direction = -1), guide = guide_colorbar(
			frame.colour = 'black', 
			ticks = F, 
			barheight = unit(0.4, 'npc'),
			title = NULL,
			frame.linewidth = 1/.pt
		)) +
		coord_equal() +
		theme_void() +
		theme(
			legend.text = element_text(size = 12)
		)
	
	plot(p1 / p2)
	
}

# pretty ones form the amazon:
# tile_00N_060W_subtile_39000_04000.tif
# tile_00N_060W_subtile_37000_04000.tif - so cool! rivers!
# tile_00N_060W_subtile_36000_05000.tif

plot.results('tile_00N_060W_subtile_00000_00000.tif')


round2 <- function(x, digits = 0) {
	# credit: https://stackoverflow.com/a/12688836
	posneg <- sign(x)
	z <- abs(x)*10^digits
	z <- z + 0.5 + sqrt(.Machine$double.eps)
	z <- trunc(z)
	z <- z/10^digits
	return(z*posneg)
}

convert.raster.to.row <- function(f) {
	r <- raster(paste0('~/data/uw/tiles100/', f))
	v <- values(r)
	v.norm <- ((v - min(v)) / (max(v) - min(v))) * 100
	v.norm.int <- round2(v.norm)
	return(v.norm.int)
}

# export
for (i in 1:nrow(df.p)) {
	f <- df.p$file[i]
	cat(paste0(i, '. ', f), fill = T)
	vals <- convert.raster.to.row(f)
	line <- paste0(f, ',', paste0(vals, collapse = ','))
	write(line, file = '~/repos/uw/results/tiles.csv', append = T)
}
