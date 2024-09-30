# Histogram Plots

## Content
1. [Load the image](#load-the-image)
2. [Plot by setting a rectangular block](#plot-by-setting-a-rectangular-block)

------

## Load the image
You will need to load in the image to matlab to execute the histogram plots.

Let's use the files ```lumberton.tif``` as an example.

Launch MATLAB, and load and view the image by doing:
```
>> I = readRaster('lumberton.tif','tif');
>> figure; imagesc(I)
```

## Histogram plotting Functions
There are several histogram plotting functions available for you to view the histogram fitting result.

1. ```plotBlkStat```: Plot and fit the histogram of a selected block
2. ```plotP2TileStat```: Plot and fit the histogram of the tile where a given point (x,y) is located within
3. ```plotPc2TileStat```: Plot and fit the histogram of the tile where a given point (x,y) is located at the center
4. ```plotTileIDStat```: Plot and fit the histogram of the tile of a specified tileID
5. ```plotTileXYStat```: Plot and fit the histogram of the tile where its tileX and tileY are specified

Use ```help``` in MATLAB to get detailed usage for each function.
