# GSBA (Growing Split-Based Approach)

## Content
1. [Job Configuration](#job-configuration)
2. [Job Execution Flow](#job-execution-flow)
3. [Output Files](#output-files)

------

## Job Configuration
Here is an example of the job configuration file ```config_flood_gsba.txt``` for GSBA:
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
%useG2=true                 % use statistics from 2nd Gaussian. If false, use mean=0 and std=1 (true)
nthresh=1                   % [>=1] min number of connected tiles needed
methodlow=const_mean        % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodhigh=const_mean       % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodlowq=0.5             % [0-1] supply this value when methodlow=quantile
methodhighq=0.5            % [0-1] supply this value when methodhigh=quantile
pcutlow=0.5                % [0-1] cut-off probability for changes with Z-
pcuthigh=0.5               % [0-1] cut-off probability for changes with Z+
minpatchlow=640            % [m^2] min area for the changed patch with Z-
minpatchhigh=640           % [m^2] min area for the changed patch with Z+

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
%AOIs are separated by ";", and the format is lon1 lat1 lon2 lat2 for UL and LR corner coordinates
valaoi=[-79.0751011 34.650042 -78.974849 34.599916; -79.029483 34.619153 -79.014066 34.601942; -79.0223 34.6230 -79.0147 34.6148; -79.0064 34.6278 -78.9996 34.6197]
valaoiID=[1,2,3,3]
%[val_small; urban_old; urban_new1; urban_new2]
valtifout=true              % output the validation tiff for each aoi, [TP,FP,TN,FN]=[1 2 -1 -2]
```

## Job Execution Flow
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


To validate using a different change detection result, such as the one with HANDEM applied, do:
```
>>g13_validate('config_flood_gsba.txt',1,'./out/lumberton_hand5_clstX_const_mean_bw10_10.tif')
```

## Output Files
Refer to the folder and files under ```example``` directory
|Folder|File Name|Description|
|:---|:---|:---|
|**out**|lumberton.tif<br />(full resolution)|The Z-score map used in change detection<br /><sub>This file will be different from the input file if dolee=true in ```config*.txt``` |
| |lumberton_intp_lo50_const_mean_p50_bw10.tif<br />(full resolution)|binary map for Z- change detection<sub><br />*lo50*: Z- at tsize=50<br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw10*: min patch size in pixels</sub>|
| |lumberton_intp_hi50_const_mean_p50_bw10.tif<br />(full resolution)|binary map for Z+ change detection<sub><br />*hi50*: Z+ at tsize=50<br />*const_mean*: fill method<br />*p50*: cutoff probability=0.5<br />*bw10*: min patch size in pixels</sub>|
| |lumberton_intp_lo50_const_mean_prob.tif<br />(full resolution)|probability map for Z- change detection<sub><br />*lo50*: Z- at tsize=50<br />*const_mean*: fill method</sub>|
| |lumberton_intp_hi50_const_mean_prob.tif<br />(full resolution)|probability map for Z+ change detection<sub><br />*hi50*: Z+ at tsize=50<br />*const_mean*: fill method</sub>|
| |lumberton_clstX_const_mean_bw10_10.tif<br />(full resolution)|binary map for both Z- and Z+ change detection<sub><br />*clstX*: no geospatial clustering<br />*const_mean*: fill method<br />*bw10*: min patch size in pixels for Z- changes<br />*10*: min patch size in pixels for Z+ changes</sub>|
| |lumberton_clstX_const_mean_prob.tif<br />(full resolution)|probability map for both Z- and Z+ change detection<sub><br />*const_mean*: fill method</sub>|
| |lumberton_hand5_clstX_const_mean_bw10_10.tif<br />(full resolution)|binary map for change detection after post-processing<sub><br />*hand5*: HANDEM threshold of 5 m<br />*clstX*: no geospatial clustering applied<br />*const_mean*: fill method<br />*bw10*: min patch size in pixels for Z- changes<br />*10*: min patch size in pixels for Z+ changes</sub>|
|**qc**|02_init.log<br />03_growlow.log<br />04_growhigh.log<br />05_interplow.log<br />06_interphigh.log<br />10_cluster.log|Log files for different steps|
| |05_interplow.txt<br />06_interphigh.txt<br />finalfile_const_mean_bw10_10.txt|Performance information for step 05<br />Performance information for step 06<br />Current constituting probability files (Z- and Z+) for the final change map (generated at step 07)|
| |time_h02<br />time_h03<br />time_h04<br />time_h05<br />time_h06|Runtime information for individual steps|
| |lumberton_init.mat<br />lumberton_grow_lo50.mat<br />lumberton_grow_hi50.mat<br />lumberton_intp_lo50_const_mean.mat<br />lumberton_intp_hi50_const_mean.mat|MATLAB file to store parameters estimated at step 02<br />MATLAB file to store parameters estimated at step 03<br />MATLAB file to store parameters estimated at step 04<br />MATLAB file to store parameters estimated at step 05<br />MATLAB file to store parameters estimated at step 06|
| |[08_qcplotlow.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/08_qcplotlow.png)<br />[09_qcplothigh.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/09_qcplothigh.png)<br />[10_clusterX_const_mean_bw10_10.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/10_clusterX_const_mean_bw10_10.png)<br />[11_hand5_clstX_const_mean_bw10_10.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/11_hand5_clstX_const_mean_bw10_10.png)|QC plot for step 08<br />QC plot for step 09<br />QC plot for step 10<br />QC plot for step 11|
| |lumberton_intp_lo50_const_mean_G1A.tif<br />lumberton_intp_lo50_const_mean_G1M.tif<br />lumberton_intp_lo50_const_mean_G1S.tif<br />lumberton_intp_hi50_const_mean_G3A.tif<br />lumberton_intp_hi50_const_mean_G3M.tif<br />lumberton_intp_hi50_const_mean_G3S.tif<br />(full resolution)|amplitude for the 1st Gaussian<br />mean for the 1st Gaussian<br />std for the 1st Gaussian<br />amplitude for the 3rd Gaussian<br />mean for the 3rd Gaussian<br />std for the 3rd Gaussian<br /><sub>**Note:** The values are after multiplying the actual floating values with 100 and truncating to integer</sub>|
|**val**|13_val.log|Log file for step 13|
| |lumberton_val_full.tif<br />lumberton_val_aoi1.tif<br />lumberton_val_aoi2.tif<br />lumberton_val_aoi3.tif|Output validation files for full area and AOIs<br /><sub>Set AOIs in ```config*.txt```<br />These files are saved if valtifout=true in ```config*.txt```</sub>|
| |[val_lumberton_clstX_const_mean_bw10_10_full.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/val_lumberton_clstX_const_mean_bw10_10_full.png)<br />[val_lumberton_clstX_const_mean_bw10_10_AOI1.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/val_lumberton_clstX_const_mean_bw10_10_AOI1.png)<br />[roc_lumberton_clstX_const_mean_bw10_10.png](https://github.com/IES-SARLab/SBATool/blob/main/images/gsba/roc_lumberton_clstX_const_mean_bw10_10.png)|QC plot for validation of full area<br />QC plot for validation of AOIs<br />QC plot of ROC cuves|
| |roc_lumberton_clstX_const_mean_bw10_10.mat|MATLAB file to store parameters about ROC cuves|

