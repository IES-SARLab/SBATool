# SBATool
Split-Based Approach (SBA) for SAR-based Change Detection.
This tool contains two algorithms:
1. ```GSBA```: Growing Split-Based Approach. Parallel computation is supported.
2. ```HSBA```: Hierarchical Split-Based Approach. 

**Note**: This work is currently under review now. All source codes will be available after the review process is complete.

## Environment Preparation
Add subfolder ```main``` and ```kernel``` to MATLAB path by

```matlab
addpath('{SBATool folder}/main')  %{SBATool folder} is the path to SBATool
addpath('{SBATool folder}/kernel')
```

## Input Files
An example of the input files are shown in the ```example``` folder
|File Name|Description|Required|
|:---|:---|:---|
|config.txt|Job configuration file|Yes|
|lumberton.tif|Z-score map|Yes|
|lumberton_mask.tif|Layover and shadow mask<br />0=non-masked<br />other values=masekd|No|
|lumberton_hand.tif|HANDEM values in meters|No|
|lumberton_lia.tif|Local incidence angles in degrees|No|
|lumberton_val.tif|Validation data<br />0=no change<br />1=change|No|

Note that all input files need to share the same prefix.

## Job configuration
Here is an example of the job configuration file ```config.txt``` for GSBA:
```matlab
%%% Parallel setting
npool=12                  % set number of workers for parallel processing

%%% initiation (g01-g04)
filename=ampEventNorm_lee3_large_para500.tif
projdir=./                % the relative or absolute path that contains data, mask, hand and val directories 
usemask=false             % use mask with same input filename but under {projdir}/mask folder (false)
dolee=false               % true for additional lee filter (false)
split=false               % split image into 2x2 sub-images (memory issue) (false)
splitsize=[2 2]           % [split_y  split_x] split image into split_y by split_x subimages
crop=false                % crop a sub area (false)
%aoi=[x1 y1; x2 y2]       % aoi for cropping; x1 y1 x2 y2 are in pixels
%filtwin=3                % lee filter window 
%tsize=50                 % tile size (default is 50)

%%% selection thresholds (g05-g06)
%         AD    BC   SR   NA
threshG1=[1.9  .99  .10  0.4];  
threshG3=[1.9  .99  .05  0.4];  

%%% tile growing (g07-g08)
nthresh=1                  % [>=1] min number of connected tiles needed
methodlow=const_mean       % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodhigh=const_mean      % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodlowq=0.5             % [0-1] supply this value when methodlow=quantile
methodhighq=0.5            % [0-1] supply this value when methodhigh=quantile
pcutlow=0.5                % [0-1] cut-off probability for changes w. amp drop
pcuthigh=0.5               % [0-1] cut-off probability for changes w. amp jump
minpatchlow=3200           % [m^2] min area for the changed patch w. amp drop
minpatchhigh=3200          % [m^2] min area for the changed patch w. amp jump
%lookpF=1;                 % look number for Bayesian probably (for display purpose)

%%% geospatial processing (g12-g13; suggested for landslide) 
docluster=false             % run geospatial clustering (g12)
dohandem=true               % apply handem mask (g13)
noplow=false                % ignore probability for amp- changes
clusterdist=100             % [m] max distance btw points within a landslide cluster
clusterarea=3000            % [m^2] min area for a landslide cluster shown in the tif file
clusterlarge=10000          % [m^2] min area for a large landslide cluster (with area report)
handthresh=[5 nan]          % [m] [nan 20] means to keep values with handem>20
                            %     [20 nan] means to keep values with handem<20
                            %     [10  20] means to keep values in between

%%% validation (g15)
liathresh=80                % [deg] max local incidence angle (above which the validation will be masked out)
%multiple AOIs are separated by ";", the format is lon1 lat1 lon2 lat2 for UL and LR corner coordinates
valaoi=[lon11 lat11 lon12 lat12; lon21 lat21 lon22 lat22]
valaoiID=[1,2]
valtifout=true              % output the validation tiff for each aoi, [TP,FP,TN,FN]=[1 2 -1 -2]
```

Here is an example of the job configuration file ```config.txt``` for HSBA:
```matlab
%%% Parallel setting
npool=12                  % set number of workers for parallel processing

%%% initiation (h01)
filename=ampEventNorm_lee3_large_para500.tif
projdir=./                % the relative or absolute path that contains data, mask, hand and val directories 
usemask=false             % use mask with same input filename but under {projdir}/mask folder (false)
dolee=false               % true for additional lee filter (false)
crop=false                % crop a sub area (false)
%aoi=[x1 y1; x2 y2]       % aoi for cropping
%filtwin=3                % lee filter window 

%%% selection thresholds (h02,h04)
%         AD    BC   SR   NA
threshG1=[1.9  .99  .10  0.4];  
threshG3=[1.9  .99  .05  0.4];  

%%% generate flood map (h03,h05)
methodlow=const_mean       % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodhigh=const_mean      % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodlowq=0.5             % [0-1] supply this value when methodlow=quantile
methodhighq=0.5            % [0-1] supply this value when methodhigh=quantile
pcutlow=0.5                % [0-1] cut-off probability for changes w. amp drop
pcuthigh=0.5               % [0-1] cut-off probability for changes w. amp jump
minpatchlow=3200           % [m^2] min area for the changed patch w. amp drop
minpatchhigh=3200          % [m^2] min area for the changed patch w. amp jump
%lookpF=1;                 % look number for Bayesian probably (for display purpose)

%%% geospatial processing (g12-g13 suggested for landslide) 
docluster=false             % run geospatial clustering (g12)
dohandem=false              % apply handem mask (g13)
noplow=false                % ignore probability for amp- changes
clusterdist=100             % [m] max distance btw points within a landslide cluster
clusterarea=3000            % [m^2] min area for a landslide cluster shown in the tif file
clusterlarge=10000          % [m^2] min area for a large landslide cluster (with area report)
handthresh=[nan 20]         % [m] [nan 20] means to keep values with handem>20
                            %     [20 nan] means to keep values with handem<20
                            %     [10  20] means to keep values in between

%%% validation (g15)
liathresh=80                % [deg] max local incidence angle (above which the validation will be masked out)
%multiple AOIs are separated by ";", the format is lon1 lat1 lon2 lat2 for UL and LR corner coordinates
valaoi=[lon11 lat11 lon12 lat12; lon21 lat21 lon22 lat22]
valaoiID=[1,2]
valtifout=true              % output the validation tiff for each aoi, [TP,FP,TN,FN]=[1 2 -1 -2]
```

## GSBA Job Execution Flow
Driver file: ```gsba_driver```

Launch MATLAB, and you can get the help menu direction by using ```help```:
```
>> help gsba_driver
 function gsba_driver(startfrom,endat,fconfig,[ct,splitid])
  fconfig: configure file 
  ct: change type, 1=Z- changes
                   3=Z+ changes
                   0=both types
      if ct not specified, steps will be executed in sequence
  step can be the following. 
    step 1:  g01_filter       : data preparation
    step 2:  g02_init         : tile initiation step 1
    step 3:  g03_inito        : tile initiation step 2
    step 4:  g04_selshift     : tile initiation step 3
    step 5:  g05_fpmlow.m     : select tiles for amp- changes
    step 6:  g06_fpmhigh.m    : select tiles for amp+ changes
    step 7:  g07_interplow.m  : growing tiles for amp- changes
    step 8:  g08_interphigh.m : growing tiles for amp+ changes
    step 9:  g09_qcmetrics.m  : QC plot for metrics
    step 10: g10_qcplotlow.m  : QC plot for amp- changes
    step 11: g11_qcplothigh.m : QC plot for amp+ changes
    step 12: g12_cluster.m    : geospatial clustering 
    step 13: g13_handem.m     : apply HANDEM
    step 14: g14_xv.m         : cross-validation between two tracks (standalone)
    step 15: g15_validate.m   : validate over known results (val file required)
```


To run the entire flow in one go, do:
```
>>gsba_driver(1,15,'config.txt')
```

### GSBA Output Files
Refer to the folder and files under ```example``` directory
|Folder|File Name|Description|
|:---|:---|:---|
|**out**|lumberton.tif|The Z-score map used in change detection<br /><sub>This file will be different from the input file if dolee=true in ```config.txt``` |
| |lumberton_lo_const_mean_p50_bw50.tif|binary map for Z- change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_hi_const_mean_p50_bw50.tif|binary map for Z+ change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_const_mean_bw50.tif|binary map for both Z- and Z+ change detection<sub><br />*const_mean*: fill method<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_hand5_clstX_const_mean_bw50.tif|binary map for change detection after post-processing<sub><br />*hand5*: HANDEM threshold of 5 m<br />*clstX*: no geospatial clustering applied<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_intp_lo_const_mean_prob.tif|probability map for Z- change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_intp_hi_const_mean_prob.tif|probability map for Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_const_mean_prob.tif|probability map for both Z- and Z+ change detection<sub><br />*const_mean*: fill method</sub>|
|**qc**|10_qcplotlow.png<br />11_qcplothigh.png<br />12_clusterX_const_mean_bw50.pn<br />13_hand5_clstX_const_mean_bw50.png|QC plot for step 10-13|
| |02_init.log<br />05_growlow.log<br />06_growhigh.log<br />07_interplow.log<br />08_interphigh.log<br />12_cluster.log|Log files for different steps|
| |07_interplow.txt<br />08_interphigh.txt|Performance information for step 07-08|
| |12_finalfile_const_mean_bw50.txt|Current constituting files (Z- and Z+) for the final change map|
| |time_g02<br />time_g05<br />time_g06<br />time_g07<br />time_g08|Conputation time (in sec) for critical steps|
|**val**|lumberton_hand5_clstX_const_mean_bw50_full.png|Validation plot for full area|
| |lumberton_hand5_clstX_const_mean_bw50_AOI1.png<br />lumberton_hand5_clstX_const_mean_bw50_AOI2.png|Validation plot for AOI1 and AOI2<br /><sub>Set AOI1 and AOI2 in ```config.txt```</sub>|
| |15_val.log|Log file for step 15|
| |val_Z_lee3_hand5_clstX_const_mean_bw50.txt|Output metrics for validation|


## HSBA Job Execution Flow
Driver file: ```hsba_driver```

Launch MATLAB, and you can get the help menu direction by using ```help```:
```
>> help hsba_driver
 function gsba_driver(startfrom,endat,fconfig,[ct,splitid])
  fconfig: configure file 
  ct: change type, 1=Z- changes
                   3=Z+ changes
                   0=both types
      if ct not specified, steps will be executed in sequence
  step can be the following. 
    step 1:  g01_filter       : data preparation
    step 2:  h02_hsba_G1.m    : hsba for amp- changes
    step 3:  h03_hsba_G3.m    : hsba for amp+ changes
    step 4:  h04_hsbaplow.m   : generate prob and proxy maps for amp- changes
    step 5:  h05_hsbaphigh.m  : generate prob and proxy maps for amp+ changes
    step 6:  h06_qcplothsba.m : QC plots
    step 12: g12_cluster.m    : geospatial clustering 
    step 13: g13_handem.m     : apply HANDEM
    step 14: g14_xv.m         : cross-validation between two tracks (standalone)
    step 15: g15_validate.m   : validate over known results (val file required)
```


To run the entire flow in one go, do:
```
>>hsba_driver(1,15,'config.txt')
```

### HSBA Output Files
|Folder|File Name|Description|
|:---|:---|:---|
|**out**|lumberton.tif|The Z-score map used in change detection<br /><sub>This file will be different from the input file if dolee=true in ```config.txt``` |
| |lumberton_hsbaintp_lo_const_mean_p50_bw50.tif|binary map for Z- change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_hsbaintp_hi_const_mean_p50_bw50.tif|binary map for Z+ change detection<sub><br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_hsbaclstX_const_mean_bw50.tif|binary map for both Z- and Z+ change detection<sub><br />*clstX*: no geospatial clustering<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_hand5_hsbaclstX_const_mean_bw50.tif|binary map for change detection after post-processing<sub><br />*hand5*: HANDEM threshold of 5 m<br />*clstX*: no geospatial clustering applied<br />*const_mean*: fill method<br />*bw50*: min patch size in pixels</sub>|
| |lumberton_hsbaintp_lo_const_mean_prob.tif|probability map for Z- change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_hsbaintp_hi_const_mean_prob.tif|probability map for Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_hsbaclstX_const_mean_prob.tif|probability map for both Z- and Z+ change detection<sub><br />*const_mean*: fill method</sub>|
|**qc**|06_qcplothsba.png|QC plot for step 6|
| |02_hsba.log<br />04_hsbaplow.log<br />05_hsbaphigh.log|Log files for different steps|
| |04_hsbaplow.txt<br />05_hsbaphigh.txt|Performance information for step 04-05|
| |12_finalfile_mean_bw50.txt|Current constituting files (Z- and Z+) for the final change map|
|**val**|lumberton_hand5_hsbaclstX_const_mean_bw50_full.png|Validation plot for full area|
| |lumberton_hand5_hsbaclstX_const_mean_bw50_AOI1.png<br />lumberton_hand5_hsbaclstX_const_mean_bw50_AOI2.png|Validation plot for AOI1 and AOI2<br /><sub>Set AOI1 and AOI2 in ```config.txt```</sub>|
| |15_val.log|Log file for step 15|
| |val_Z_lee3_hand5_hsbaclstX_const_mean_bw50.txt|Output metrics for validation|
