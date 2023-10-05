# Generating Z-score Map

## Content
1. [Input Data](#Input-Data)
2. [Example Script](#Example-Script)
3. [Reference](#Reference)

------

## Input Data
In the folder ```example_preproc```, you should see two example folders:
 - ```stack_isce```
 - ```stack_tif```

In the folder ```stack_isce```, each image is the geocoded amplitude file (single-band) from ISCE. You can either produce this file from the geocoded SLC files by using ```imageMath.py``` in ISCE, or change the scripts [```p01_produceZmap.m```](https://github.com/IES-SARLab/SBATool/blob/main/example_preproc/p01_produceZmap.m) to suite your data format.

In the folder ```stack_tif```, each image is the geotiff amplitude file from SNAP (or another other software).

## Example Script
The script [```p01_produceZmap.m```](https://github.com/IES-SARLab/SBATool/blob/main/example_preproc/p01_produceZmap.m) provides examples of turning amplitude stack into Z-score map.

## Reference
For more information regarding Z-score map, refer to:

Lin, N. Y., Yun, S.-H., Bhardwaj, A., & Hill, M. E. (2019). Urban Flood Detection with Sentinel-1 Multi-Temporal Synthetic Aperture Radar (SAR) Observations in a Bayesian Framework: A Case Study for Hurricane Matthew. _Remote Sensing_, 11(15), 1-22. https://doi.org/10.3390/rs11151778 

Lin, Y. N., Chen, Y.-C., Kuo, Y.-T., & Chao, W.-A. (2022). Performance Study of Landslide Detection Using Multi-Temporal SAR Images. _Remote Sensing_, 14(10). https://doi.org/10.3390/rs14102444 
