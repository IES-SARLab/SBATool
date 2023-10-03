# SBATool
Split-Based Approach (SBA) for SAR-based Change Detection.
This tool contains two algorithms:
  - ```GSBA```: Growing Split-Based Approach. Parallel computation is supported.
  - ```HSBA```: Hierarchical Split-Based Approach. 

For detailed information about **HSBA**, refer to:

Chini, M., Hostache, R., Giustarini, L., & Matgen, P. (2017). A hierarchical split-based approach for parametric thresholding of SAR images: Flood inundation as a test case. Ieee Transactions On Geoscience and Remote Sensing, 55(12), 6975-6988. https://doi.org/10.1109/TGRS.2017.2737664

Detailed information about **GSBA** is still under review (as of 2 Oct 2023).

## Contents

1. [Environment Preparation](#environment-preparation)
2. [Input Data Files](#input-data-files)
3. [Input Config Files](#input-config-files)
4. [GSBA](https://github.com/IES-SARLab/SBATool/blob/main/docs/GSBA.md)
5. [HSBA](https://github.com/IES-SARLab/SBATool/blob/main/docs/HSBA.md)
------

## Environment Preparation
It is recommended that you run SBATool in MATLAB 2019b or later versions. **Note:** Errors may appear if you run in MATLAB 2023 or later versions.

Add SBATool to MATLAB path by doing:

```matlab
addpath(genpath('{SBATool folder}'))  %{SBATool folder} is the path to SBATool
```

You will also need to install the following MATLAB Toolbox:

```Deep Learning Toolbox```

## Input Data Files
An example of the input files are shown in the ```example``` folder:
|File Name|Description|Required/Optional|
|:---|:---|:---|
|lumberton.tif|Z-score map|Required|
|lumberton_mask.tif|Layover and shadow mask<br />0=non-masked<br />other values=masekd|Optional|
|lumberton_hand.tif|HANDEM values in meters|Optional|
|lumberton_lia.tif|Local incidence angles (LIA) in degrees|Optional|
|lumberton_val.tif|Validation data<br />0=no change<br />1=change|Optional|

All input files need to share **the same prefix**. The suffix can be **.tif** (recommended), **.img** or **any isce suffix**.

If any of the optional files is not present in the folder, the corresponding step (masking/hand masking/lia masking/validation) will be omitted.

The first four tif files need to be in the same image size. The validation file can have a different image size, usually smaller than the other four files. 

All files need to be in the same reference frame.

For information about **HANDEM**, refer to:

Rennó, C. D., Nobre, A. D., Cuartas, L. A., Soares, J. V., Hodnett, M. G., Tomasella, J., & Waterloo, M. J. (2008). HAND, a new terrain descriptor using SRTM-DEM: Mapping terra-firme rainforest environments in Amazonia. Remote Sensing of Environment, 112(9), 3469-3481. https://doi.org/https://doi.org/10.1016/j.rse.2008.03.018

For information about **LIA**, refer to:

Shibayama, T., Yamaguchi, Y., & Yamada, H. (2015). Polarimetric Scattering Properties of Landslides in Forested Areas and the Dependence on the Local Incidence Angle. Remote Sensing, 7(11). https://doi.org/10.3390/rs71115424 

## Input Config Files
Example of the config files are shown in the ```config``` folder:
|File Name|Description|Required/Optional|
|:---|:---|:---|
|config_flood_gsba.txt|Job configuration file for GSBA|Required|
|config_flood_hsba.txt|Job configuration file for HSBA|Required|

You should run different algorithms under different folders. For example, to test the ```gsba``` example, do:
```
cp example example_gsba -rf
cp config/config_flood_gsba.txt example_gsba
```
The same applies to the ```hsba``` example.

