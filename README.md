# SBATool
Split-Based Approach (SBA) for SAR-based Change Detection.
This tool contains two algorithms:
1. ```GSBA```: Growing Split-Based Approach. Parallel computation is supported.
2. ```HSBA```: Hierarchical Split-Based Approach. 

**Note: This work is currently under review. All source codes will be available after the review process is complete.**

## Environment Preparation
It is recommended that you run SBATool in MATLAB 2019b or later versions.

Add subfolder ```main``` and ```kernel``` to MATLAB path by

```matlab
addpath('{SBATool folder}/main')  %{SBATool folder} is the path to SBATool
addpath('{SBATool folder}/kernel')
```

## Input Data Files
An example of the input files are shown in the ```example``` folder
|File Name|Description|Required/Optional|
|:---|:---|:---|
|lumberton.tif|Z-score map|Required|
|lumberton_mask.tif|Layover and shadow mask<br />0=non-masked<br />other values=masekd|Optional|
|lumberton_hand.tif|HANDEM values in meters|Optional|
|lumberton_lia.tif|Local incidence angles (LIA) in degrees|Optional|
|lumberton_val.tif|Validation data<br />0=no change<br />1=change|Optional|

All input files need to share the same prefix. The suffix can be **.tif** (recommended), **.img** or **any isce suffix**.

If any of the optional files is not present in the folder, the corresponding step (masking/hand masking/lia masking/validation) will be omitted.

The first four tif files need to be in the same image size. The validation file can have a different image size, usually smaller than the other four files. 

All files need to be in the same reference frame.

For information about **HANDEM**, refer to:

Rennó, C. D., Nobre, A. D., Cuartas, L. A., Soares, J. V., Hodnett, M. G., Tomasella, J., & Waterloo, M. J. (2008). HAND, a new terrain descriptor using SRTM-DEM: Mapping terra-firme rainforest environments in Amazonia. Remote Sensing of Environment, 112(9), 3469-3481. https://doi.org/https://doi.org/10.1016/j.rse.2008.03.018

For information about **LIA**, refer to:

Shibayama, T., Yamaguchi, Y., & Yamada, H. (2015). Polarimetric Scattering Properties of Landslides in Forested Areas and the Dependence on the Local Incidence Angle. Remote Sensing, 7(11). https://doi.org/10.3390/rs71115424 

## Input Config Files
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

## GSBA
### Job Configuration
Here is an example of the job configuration file ```config_gsba.txt``` for GSBA:
```matlab
%%% Parallel setting
npool=12                 % set number of workers for parallel processing

%%% data preparation (g01)
filename=lumberton.tif
projdir=./                % the relative or absolute path that contains data, mask, hand and val directories 
usemask=false             % use mask with same input filename but under {projdir}/mask folder (false)
dolee=false               % true for additional lee filter (false)
split=false               % split image into 2x2 sub-images (memory issue) (false)
splitsize=[2 2]           % [split_y  split_x] split image into split_y by split_x subimages
%aoi=[x1 y1; x2 y2]       % aoi for cropping (pixel and line)
%filtwin=3                % lee filter window 
%pixelres=10               % pixel posting in meter (for area calculation); usually estimated automatically; uncomment to set manually

%%% initialization (g02)
tsize=50             % initialize tile size
changetype=0         % change detection type; 1=Z-, 3=Z+, 0=both (default)
%         AD   BC   SR   AS    M  NIA
threshG1=[1.9 .980 .10 0.10 -2.0];      % for flood
threshG3=[1.9 .980 .05 0.05  2.5 0.4];  % for flood
%threshG1=[1.9 .980 .05 0.10 -1.5];       % for landslide
%threshG3=[1.9 .980 .05 0.10  2.5 0.4];   % for landslide
%         BC   C1lower C1upper C2lower C2upper   (thresholds for single-mode method)
%threshG =[.80 -5      -1      1       5]  % for single mode

%%% tile growing (g03-g04)
%useG2=true                 % use statistics from 2nd Gaussian. If false, u
se mean=0 and std=1 (true)
nthresh=1                   % [>=1] min number of connected tiles needed
methodlow=const_mean        % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodhigh=const_mean       % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodlowq=0.5             % [0-1] supply this value when methodlow=quantile
methodhighq=0.5            % [0-1] supply this value when methodhigh=quantile
pcutlow=0.5                % [0-1] cut-off probability for changes w. Z-
pcuthigh=0.5               % [0-1] cut-off probability for changes w. Z+
minpatchlow=640            % [m^2] min area for the changed patch w. Z-
minpatchhigh=640           % [m^2] min area for the changed patch w. Z+
%lookpF=1;                 % look number for Bayesian probably (for display purpose)
%lookRk=1;                 % look number on binary change map over whick ripley coeff will be estimated

%%% fill statistics (g05-g06)
Rkfinallow=med             % choose the change map of Z- with the Rk level (low, med, high), default: med
Rkfinalhigh=med            % choose the change map of Z+ with the Rk level (low, med, high), default: med

%%% qc plots (g07-g09)
qlow=.05                   % the lower Rk quantile for selected plotting
qmid=.50                   % the mid Rk quantile for selected plotting
qhigh=.95                  % the higher Rk qunatile for selected plotting

%%% geospatial processing (g10-g11 suggested for landslide) 
docluster=false             % run geospatial clustering (g12)
dohandem=true               % apply handem mask (g13)
clusterdist=100             % [m] max distance btw points within a landslide cluster
clusterarea=3000            % [m^2] min area for a landslide cluster shown in the tif file
clusterlarge=10000          % [m^2] min area for a large landslide cluster (with area report)
handthresh=[5 nan]         % [m] [nan 20] means to keep values with handem>20
                            %     [20 nan] means to keep values with handem<20
                            %     [10  20] means to keep values in between

%%% validation (g12-g13)
liathresh=80                  % [deg] max local incidence angle (above which the validation will be masked out)
%AOIs are separated by ";", and the format is lon1 lat1 lon2 lat2 for UL and LR corner coordinates
valaoi=[-79.0751011 34.650042 -78.974849 34.599916; -79.029483 34.619153 -79.014066 34.601942; -79.0223 34.6230 -79.0147 34.6148; -79.0064 34.6278 -78.9996 34.6197]
valaoiID=[1,2,3,3]
%[val_small; urban_old; urban_new1; urban_new2]
valtifout=true              % output the validation tiff for each aoi, [TP,FP,TN,FN]=[1 2 -1 -2]
```

### Job Execution Flow
Driver file: ```gsba_driver```

Launch MATLAB, and you can get the help menu direction by using ```help```:
```
>> help gsba_driver
 function gsba_driver(startfrom,endat,fconfig,[splitid])
  Execute GSBA (Growing Split Based Approach) for change detection
  
  Note: current input file should be a Z-score map
        to change default histogram fitting setup, go to
        SBATool/kernel/setGaussianInitials.m
 
  fconfig: user-specified configuration file
  splitid: the split ID when the image is too large 
           and is split into multiple subimages
           for a (2x2) split, the splitid is
            1 2
            3 4
 
  step can be the following. 
    step 1:  g01_filter       : data preparation
    step 2:  g02_init         : initialize tile splitting and histogram fitting
    step 3:  g03_growlow.m    : tile growing for Z- changes
    step 4:  g04_growhigh.m   : tile growing for Z+ changes
    step 5:  g05_interplow.m  : fill statistics for Z- changes
    step 6:  g06_interphigh.m : fill statistics for Z+ changes
    step 7:  g07_qcmetrics.m  : calculate QC metrics
    step 8:  g08_qcplotlow.m  : QC plot for Z- changes
    step 9:  g09_qcplothigh.m : QC plot for Z+ changes
    step 10: g10_cluster.m    : geospatial clustering 
    step 11: g11_applyhand.m  : apply HANDEM
    step 12: g12_xv.m         : cross-validation between two tracks (stand alone)
    step 13: g13_validate.m   : validate over known results
                                calculate ROC curve (optional)
 
  NinaLin@2023
```


To run the entire flow in one go, do:
```
>>gsba_driver(1,13,'config_flood_gsba.txt')
```

### Output Files
Refer to the folder and files under ```example``` directory
|Folder|File Name|Description|
|:---|:---|:---|
|**out**|lumberton.tif<br />(full resolution)|The Z-score map used in change detection<br /><sub>This file will be different from the input file if dolee=true in ```config*.txt``` |
| |lumberton_intp_lo_const_mean_p50_bw50.tif<br />(full resolution)|binary map for Z- change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_intp_hi_const_mean_p50_bw100.tif<br />(full resolution)|binary map for Z+ change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw100*: min patch size in pixels</sub>|
| |lumberton_intp_lo_const_mean_prob.tif<br />(full resolution)|probability map for Z- change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_intp_hi_const_mean_prob.tif<br />(full resolution)|probability map for Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_clstX_const_mean_bw50_100.tif<br />full resolution)|binary map for both Z- and Z+ change detection<sub><br />*clstX*: no geospatial clustering<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels for Z- changes<br />*100*: min patch size in pixels for Z+ changes</sub>|
| |lumberton_clstX_const_mean_prob.tif<br />(full resolution)|probability map for both Z- and Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_hand5_clstX_const_mean_bw50_100.tif<br />(full resolution)|binary map for change detection after post-processing<sub><br />*hand5*: HANDEM threshold of 5 m<br />*clstX*: no geospatial clustering applied<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels for Z- changes<br />*100*: min patch size in pixels for Z+ changes</sub>|
|**qc**|06_qcplothsba.png|QC plot for step 6|
| |02_hsba.log<br />03_hsba.log<br />04_hsbaplow.log<br />05_hsbaphigh.log<br />10_cluster.log|Log files for different steps|
| |04_hsbaplow.txt<br />05_hsbaphigh.txt|Performance information for step 04-05|
| |time_h02<br />time_h03<br />time_h04<br />time_h05|Runtime information for individual steps|
| |finalfile_const_mean_bw50_100.txt|Current constituting probability files (Z- and Z+) for the final change map (generated at step 06)|
| |lumberton_hsba_G1.mat|MATLAB file to store parameters estimated at step 02|
| |lumberton_hsba_G3.mat|MATLAB file to store parameters estimated at step 03|
| |lumberton_intp_lo_const_mean.mat|MATLAB file to store parameters estimated at step 04|
| |lumberton_intp_hi_const_mean.mat|MATLAB file to store parameters estimated at step 05|
| |06_qcplothsba.png|QC plot at step 06|
| |10_clusterX_const_mean_bw50_100.png|QC plot at step 10|
| |11_hand5_clstX_const_mean_bw50_100.png|QC plot at step 11|
| |lumberton_intp_lo_const_mean_G1M.tif (full resolution)|mean for the 1st Gaussian|
| |lumberton_intp_lo_const_mean_G1S.tif (full resolution)|std for the 1st Gaussian|
| |lumberton_intp_hi_const_mean_G3M.tif (full resolution)|mean for the 3rd Gaussian|
| |lumberton_intp_hi_const_mean_G3S.tif (full resolution)|std for the 3rd Gaussian|
|**val**|13_val.log|Log file for step 13|
| |lumberton_val_full.tif  (full resolution)|Validation plot for full area|
| |lumberton_val_aoi1.tif<br />lumberton_val_aoi2.png<br />lumberton_val_aoi3.png|Validation plot for AOIs<br /><sub>Set AOIs in ```config*.txt```</sub>|
| |val_lumberton_clstX_const_mean_bw50_100_full.png|QC plot for validation of full area|
| |val_lumberton_clstX_const_mean_bw50_100_AOI1.png<br />val_lumberton_clstX_const_mean_bw50_100_AOI2.png<br />val_lumberton_clstX_const_mean_bw50_100_AOI3.png|QC plot for validation of AOIs|
| |roc_lumberton_clstX_const_mean_bw50_100.mat|MATLAB file to store parameters about ROC cuves|
| |roc_lumberton_clstX_const_mean_bw50_100.png|QC plot of ROC cuves|

## HSBA
### Job Configuration
Here is an example of the job configuration file ```config_hsba.txt``` for HSBA:
```matlab
%%% Parallel setting
npool=12                 % set number of workers for parallel processing

%%% data preparation (g01)
filename=ampEventNorm_lee3_large_para500.tif
projdir=./                % the relative or absolute path that contains data, mask, hand and val directories 
usemask=false             % use mask with same input filename but under {projdir}/mask folder (false)
dolee=false               % true for additional lee filter (false)
%aoi=[x1 y1; x2 y2]       % aoi for cropping (pixel and line)
%filtwin=3                % lee filter window 
%pixelres=10               % pixel posting in meter (for area calculation); usually estimated automatically; uncomment to set manually

%%% selection thresholds (h02-h03)
%         AD   BC   SR   AS    M  NIA
threshG1=[1.9 .980 .10 0.10 -2.0];      % for flood
threshG3=[1.9 .980 .05 0.05  2.5 0.4];  % for flood
%threshG1=[1.9 .980 .05 0.10 -1.5];       % for landslide
%threshG3=[1.9 .980 .05 0.10  2.5 0.4];   % for landslide
%         BC   C1lower C1upper C2lower C2upper   (thresholds for single-mode method)
threshG =[.80 -5      -1      1       5]  % for single mode

%%% fill statistics and generate flood map (h04-h05)
%useG2=true                % use statistics from 2nd Gaussian. If false, use mean=0 and std=1 (true)
methodlow=const_mean       % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodhigh=const_mean      % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodlowq=0.5             % [0-1] supply this value when methodlow=quantile
methodhighq=0.5            % [0-1] supply this value when methodhigh=quantile
pcutlow=0.5                % [0-1] cut-off probability for changes w. Z-
pcuthigh=0.5               % [0-1] cut-off probability for changes w. Z+
minpatchlow=3200           % [m^2] min area for the changed patch w. Z-
minpatchhigh=6400          % [m^2] min area for the changed patch w. Z+
%lookpF=1;                 % look number for Bayesian probably (for display purpose)
%lookRk=1;                 % look number on binary change map over whick ripley coeff will be estimated

%%% geospatial processing (g10-g11 suggested for landslide) 
docluster=false             % run geospatial clustering (g12)
dohandem=true               % apply handem mask (g13)
clusterdist=100             % [m] max distance btw points within a landslide cluster
clusterarea=3000            % [m^2] min area for a landslide cluster shown in the tif file
clusterlarge=10000          % [m^2] min area for a large landslide cluster (with area report)
handthresh=[5 nan]          % [m] [nan 20] means to keep values with handem>20
                            %     [20 nan] means to keep values with handem<20
                            %     [10  20] means to keep values in between

%%% validation (g12-g13)
liathresh=80                  % [deg] max local incidence angle (above which the validation will be masked out)
%AOIs are separated by ";", and the format is lon1 lat1 lon2 lat2 for UL and LR corner coordinates
valaoi=[-79.0751011 34.650042 -78.974849 34.599916; -79.029483 34.619153 -79.014066 34.601942; -79.0223 34.6230 -79.0147 34.6148; -79.0064 34.6278 -78.9996 34.6197]
valaoiID=[1,2,3,3]
%[val_small; urban_old; urban_new1; urban_new2]
valtifout=true              % output the validation tiff for each aoi, [TP,FP,TN,FN]=[1 2 -1 -2]
```

### Job Execution Flow
Driver file: ```hsba_driver```

Launch MATLAB, and you can get the help menu direction by using ```help```:
```
>> help hsba_driver
 function hsba_driver(startfrom,endat,fconfig)
  Execute HSBA (Hierarchical Split Based Approach) for change detection
 
  Note: current input file should be a Z-score map
        to change default histogram fitting setup, go to
        SBATool/kernel/setGaussianInitials.m
 
  fconfig: configure file 
  step can be the following. 
    step 1:  g01_filter       : data preparation
    step 2:  h02_hsba_G1.m    : hsba for Z- changes
    step 3:  h03_hsba_G3.m    : hsba for Z+ changes
    step 4:  h04_hsbaplow.m   : interpolate prob and create proxy maps for Z- changes
    step 5:  h05_hsbaphigh.m  : interpolate prob and create proxy maps for Z+ changes
    step 6:  h06_qcplothsba.m : QC plots
    step 10: g10_cluster.m    : geospatial clustering 
    step 11: g11_appyhand.m   : apply HANDEM
    step 12: g12_xv.m         : cross-validation between two tracks (standalone)
    step 13: g13_validate.m   : validate over known results 
                                calculate ROC curve (optional)
 
  NinaLin@2023
```


To run the entire flow in one go, do:
```
>>hsba_driver(1,13,'config_flood_hsba.txt')
```

### Output Files 
|Folder|File Name|Description|
|:---|:---|:---|
|**out**|lumberton.tif<br />(full resolution)|The Z-score map used in change detection<br /><sub>This file will be different from the input file if dolee=true in ```config*.txt``` |
| |lumberton_intp_lo_const_mean_p50_bw50.tif<br />(full resolution)|binary map for Z- change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_intp_hi_const_mean_p50_bw100.tif<br />(full resolution)|binary map for Z+ change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw100*: min patch size in pixels</sub>|
| |lumberton_intp_lo_const_mean_prob.tif<br />(full resolution)|probability map for Z- change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_intp_hi_const_mean_prob.tif<br />(full resolution)|probability map for Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_clstX_const_mean_bw50_100.tif<br />full resolution)|binary map for both Z- and Z+ change detection<sub><br />*clstX*: no geospatial clustering<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels for Z- changes<br />*100*: min patch size in pixels for Z+ changes</sub>|
| |lumberton_clstX_const_mean_prob.tif<br />(full resolution)|probability map for both Z- and Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_hand5_clstX_const_mean_bw50_100.tif<br />(full resolution)|binary map for change detection after post-processing<sub><br />*hand5*: HANDEM threshold of 5 m<br />*clstX*: no geospatial clustering applied<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels for Z- changes<br />*100*: min patch size in pixels for Z+ changes</sub>|
|**qc**|06_qcplothsba.png|QC plot for step 6|
| |02_hsba.log<br />03_hsba.log<br />04_hsbaplow.log<br />05_hsbaphigh.log<br />10_cluster.log|Log files for different steps|
| |04_hsbaplow.txt<br />05_hsbaphigh.txt|Performance information for step 04-05|
| |time_h02<br />time_h03<br />time_h04<br />time_h05|Runtime information for individual steps|
| |finalfile_const_mean_bw50_100.txt|Current constituting probability files (Z- and Z+) for the final change map (generated at step 06)|
| |lumberton_hsba_G1.mat|MATLAB file to store parameters estimated at step 02|
| |lumberton_hsba_G3.mat|MATLAB file to store parameters estimated at step 03|
| |lumberton_intp_lo_const_mean.mat|MATLAB file to store parameters estimated at step 04|
| |lumberton_intp_hi_const_mean.mat|MATLAB file to store parameters estimated at step 05|
| |06_qcplothsba.png|QC plot at step 06|
| |10_clusterX_const_mean_bw50_100.png|QC plot at step 10|
| |11_hand5_clstX_const_mean_bw50_100.png|QC plot at step 11|
| |lumberton_intp_lo_const_mean_G1M.tif (full resolution)|mean for the 1st Gaussian|
| |lumberton_intp_lo_const_mean_G1S.tif (full resolution)|std for the 1st Gaussian|
| |lumberton_intp_hi_const_mean_G3M.tif (full resolution)|mean for the 3rd Gaussian|
| |lumberton_intp_hi_const_mean_G3S.tif (full resolution)|std for the 3rd Gaussian|
|**val**|13_val.log|Log file for step 13|
| |lumberton_val_full.tif  (full resolution)|Validation plot for full area|
| |lumberton_val_aoi1.tif<br />lumberton_val_aoi2.png<br />lumberton_val_aoi3.png|Validation plot for AOIs<br /><sub>Set AOIs in ```config*.txt```</sub>|
| |val_lumberton_clstX_const_mean_bw50_100_full.png|QC plot for validation of full area|
| |val_lumberton_clstX_const_mean_bw50_100_AOI1.png<br />val_lumberton_clstX_const_mean_bw50_100_AOI2.png<br />val_lumberton_clstX_const_mean_bw50_100_AOI3.png|QC plot for validation of AOIs|
| |roc_lumberton_clstX_const_mean_bw50_100.mat|MATLAB file to store parameters about ROC cuves|
| |roc_lumberton_clstX_const_mean_bw50_100.png|QC plot of ROC cuves|
