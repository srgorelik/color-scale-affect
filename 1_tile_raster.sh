#!/bin/bash
set -e

cd ~/data/uw

# download global 500m AGB map
# gsutil -m cp gs://walker_etal_2022_pnas/Base_Cur_AGB_MgCha_500m.tif .

#----------------------------------------------------
# Attempt 1: 200x200 tiles globally
#----------------------------------------------------

OUTDIR=tiles100
mkdir -p $OUTDIR

gdal_retile.py \
	-ps 100 100 \
	-of GTiff \
	-ot Int16 \
	-co COMPRESS=LZW \
	-targetDir $OUTDIR \
	-tileIndex tile_index_100G.shp \
	Base_Cur_AGB_MgCha_500m.tif

#----------------------------------------------------
# Attempt 2: 50x50 tiles for South America 
#----------------------------------------------------

# # extent (based on 200x200 tiles)
# ULX=-8988266.700704960152507
# ULY=1297275.606329970061779
# LRX=-3799164.275624949950725
# LRY=-6208390.401375049725175
# 
# # crop
# gdal_translate \
# 	-projwin $ULX $ULY $LRX $LRY \
# 	-of GTiff \
# 	-ot Int16 \
# 	-co COMPRESS=LZW \
# 	Base_Cur_AGB_MgCha_500m.tif \
# 	Base_Cur_AGB_MgCha_500m_SouthAmerica.tif
# 
# # tile (produces 18144 tiles)
# OUTDIR=tiles50SA
# mkdir -p $OUTDIR
# gdal_retile.py \
# 	-ps 50 50 \
# 	-of GTiff \
# 	-ot Int16 \
# 	-co COMPRESS=LZW \
# 	-targetDir $OUTDIR \
# 	Base_Cur_AGB_MgCha_500m_SouthAmerica.tif
# 
# # create tile index shapefile (for visualization)
# gdaltindex tile_index_50SA.shp *.tif

