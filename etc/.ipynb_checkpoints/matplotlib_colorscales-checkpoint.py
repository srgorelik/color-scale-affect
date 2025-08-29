#!/usr/bin/python

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from colormath.color_objects import sRGBColor, LCHabColor
from colormath.color_conversions import convert_color

# -------------------------------------------------------------------
# color scales
# -------------------------------------------------------------------

# see https://matplotlib.org/stable/gallery/color/colormap_reference.html#sphx-glr-gallery-color-colormap-reference-py

# color_scales = [
#     # perceptually uniform sequential
#     'viridis', 'plasma', 'inferno', 'magma', 'cividis',

#     # sequential
#     'Greys', 'Purples', 'Blues', 'Greens', 'Oranges', 'Reds', 'YlOrBr', 
#     'YlOrRd', 'OrRd', 'PuRd', 'RdPu', 'BuPu', 'GnBu', 'PuBu', 'YlGnBu', 
#     'PuBuGn', 'BuGn', 'YlGn',

#     # sequential 2
#     'bone', 'pink', 'spring', 'summer', 'autumn', 'winter', 'cool', 'Wistia', 
#     'hot', 'afmhot', 'gist_heat', 'copper',

#     # diverging
#     'PiYG', 'PRGn', 'BrBG', 'PuOr', 'RdGy', 'RdBu', 'RdYlBu', 'RdYlGn', 
#     'Spectral', 'coolwarm', 'bwr', 'seismic', 'berlin', 'managua', 'vanimo', 
    
#     # cyclic
#     'twilight', 'twilight_shifted', 'hsv',

#     # misc
#     'ocean', 'gist_earth', 'terrain', 'gist_stern', 'gnuplot', 'gnuplot2', 
#     'CMRmap', 'cubehelix', 'brg', 'rainbow','turbo'
# ]

color_scales = [
    
    # perceptually uniform sequential
    'viridis', 'plasma', 'inferno', 'magma', 'cividis',

    # sequential
    'Greys', 'Purples', 'Blues', 'Greens', 'Oranges', 'Reds',
    'YlOrBr', 'YlOrRd', 'OrRd', 'PuRd', 'RdPu', 'BuPu',
    'GnBu', 'PuBu', 'YlGnBu', 'PuBuGn', 'BuGn', 'YlGn',

    # diverging
    'PiYG', 'PRGn', 'BrBG', 'PuOr', 'RdGy', 'RdBu',
    'RdYlBu', 'RdYlGn', 'Spectral', 'coolwarm', 'bwr', 'seismic',
    'berlin', 'managua', 'vanimo',

    # misc
    'gist_earth', 'rainbow'
]

len(color_scales) # 40

# -------------------------------------------------------------------
# plot color scales
# -------------------------------------------------------------------

gradient = np.linspace(0, 1, 256)
gradient = np.vstack((gradient, gradient))

def plot_color_scales(color_scales_list):
    # create figure and adjust figure height to number of color scales
    nrows = len(color_scales_list)
    figh = 0.35 + 0.15 + (nrows + (nrows-1)*0.1)*0.22
    fig, axs = plt.subplots(nrows=nrows, figsize=(6.4, figh))
    fig.subplots_adjust(top=1-.35/figh, bottom=.15/figh, left=0.2, right=0.99)
    
    axs[0].set_title("color scales", fontsize=14)
    
    for ax, color_scale in zip(axs, color_scales_list):
        ax.imshow(gradient, aspect='auto', cmap=color_scale)
        ax.text(-.01, .5, color_scale, va='center', ha='right', fontsize=10, transform=ax.transAxes)
    
    for ax in axs:
        ax.set_axis_off()

plot_color_scales(color_scales)

# -------------------------------------------------------------------
# export values to csv
# -------------------------------------------------------------------

# get list of color values for each 
rows = []
for color_scale_name in color_scales:
    color_scale = plt.get_cmap(color_scale_name)
    values = np.linspace(0, 1, 256)
    rgba_colors = color_scale(values)
    rgb_colors = rgba_colors[:, :3] # drop alpha

    for i in range(256):
        r, g, b = rgb_colors[i] # 0–1 floats
        
        # convert from RGB to CIE LCH with a white point of D65
        rgb = sRGBColor(float(r), float(g), float(b), is_upscaled=False)
        lch = convert_color(rgb, LCHabColor, target_illuminant='d65')
        
        rows.append([
            color_scale_name, i+1, r, g, b,  # original RGB
            lch.lch_l, lch.lch_c, lch.lch_h  # L, C, H
        ])

# convert to dataframe
df = pd.DataFrame(rows, columns=["colorscale", "index", "R", "G", "B", "L", "C", "H"])

# export to CSV
df.to_csv("matplotlib_colorscales.csv", index=False)
