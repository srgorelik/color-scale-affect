#!/bin/bash
set -e

cd ~/data/uw

#gsutil -m cp gs://walker_etal_2022_pnas/Base_Cur_AGB_MgCha_500m.tif .

mkdir -p tiles

gdal_retile.py \
	-ps 200 200 \
	-of GTiff \
	-ot Int16 \
	-co COMPRESS=LZW \
	-targetDir tiles \
	Base_Cur_AGB_MgCha_500m.tif


