# SBATool
Split-based Approach for SAR-based Change Detection.
This tool contains two algorithms:
1. ```GSBA```: Growing Split-Based Approach. Parallel computation is supported.
2. ```HSBA```: Hierarchical Split-Based Approach. 

**Note**: This work is currently under review now. All source codes will be available afterwards.

## Environment Preparation
Add subfolder ```main``` and ```kernel``` to your MATLAB path

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
Key parameters for the processing and their explanations are offered directly in ```config.txt```
```matlab
%%% Parallel setting
npool=10                 % set number of workers in parpool

%%% initiation (g01-g04)
filename=lumberton.tif
projdir=./               % the relative or absolute path that contains data, mask, hand and val 
directories 
usemask=true              % use mask with same input filename but under {inputdir}_mask folder (false)
dolee=false               % true for additional lee filter (false)
split=false               % split image into 2x2 sub-images (memory issue) (false)
splitsize=[2 2]           % [split_y  split_x] split image into split_y by split_x subimages
crop=false                % crop a sub area (false)
%aoi=[x1 y1; x2 y2]       % aoi for cropping
%filtwin=3                % lee filter window 
pixelres=%pixelres        % pixel posting in meter (for area calculation)
%tlistlow=[31:10:101]     % overwrite default list of tile sizes for changes w. amp drop
%tlisthigh=[31:10:101]    % overwrite list of tile sizes for changes w. amp jump

%%% selection thresholds (g05-g06)
%         AD   BC   SR   AS    M  NIA
%threshG1=[1.9 .990 .10 0.10 -1.5];      % for flood
%threshG3=[1.9 .980 .05 0.05  2.5 0.4];  % for flood
%threshG1=[1.9 .950 .05 0.05 -1.5];      % for landslide
%threshG3=[1.9 .950 .05 0.05  2.5 0.4];  % for landslide
threshG1=[1.9 .980 .05 0.10 -1.5];       % for landslide
threshG3=[1.9 .980 .05 0.10  2.5 0.4];   % for landslide
%         BC   C1lower C1upper C2lower C2upper   (thresholds for single-mode method)
threshG =[.80 -5      -1      1       5]  % for single mode

%%% tile growing (g07-g08)
nthresh=1                  % [>=1] min number of connected tiles needed
methodlow=mean         % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodhigh=mean        % fill method (wmean, mean, quantile, const_max, const_mean, const_med, const_q, invdist)
methodlowq=0.5             % [0-1] supply this value when methodlow=quantile or const_q
methodhighq=0.5            % [0-1] supply this value when methodhigh=quantile or const_q
pcutlow=0.95               % [0-1] cut-off probability for changes w. amp drop
pcuthigh=0.95              % [0-1] cut-off probability for changes w. amp jump
minpatchlow=3000           % [m^2] min area for the changed patch w. amp drop
minpatchhigh=3000          % [m^2] min area for the changed patch w. amp jump
%lookpF=1;                 % look number for Bayesian probably (for display purpose)
%lookRk=1;                 % look number on binary change map over whick ripley coeff will be estimated

%%% qc plots (g09-g11)
qlow=.05                   % the lower Rk quantile for selected plotting
qmid=.50                   % the mid Rk quantile for selected plotting
qhigh=.95                  % the higher Rk qunatile for selected plotting
%tlistlowplot=[41 51 61]   % QC plots for particular tsize, a list of 3 values (amp drop)
%tlisthighplot=[41 51 61]  % QC plots for particular tsize, a list of 3 values (amp jump)
%xlims=[min(tlisthigh) max(tlisthigh)]   % x-axis for QC plots

%%% geospatial processing (g12-g13 suggested for landslide)
docluster=false             % run geospatial clustering (g12)
dohandem=false              % apply handem mask (g13)
noplow=false                % ignore probability for amp- changes
nophigh=false               % ignore probability for amp+ changes
%tlistpatchlow=[41]         % the list of image for geospatial processing w. amp drop
%tlistpatchhigh=[71]        % the list of image for geospatial processing w. amp jump
clusterdist=100             % [m] max distance btw points within a landslide cluster
clusterarea=3000            % [m^2] min area for a landslide cluster shown in the tif file
clusterlarge=10000          % [m^2] min area for a large landslide cluster (with area report)
handthresh=[nan 20]         % [m] [nan 20] means to keep values with handem>20
                            %     [20 nan] means to keep values with handem<20
                            %     [10  20] means to keep values in between

%%% validation (g15)
liathresh=80                  % [deg] max local incidence angle (above which the validation will be masked out during validation)
%Each set of AOI is separated by ";", and the format is lon1 lat1 lon2 lat2 for UL and LR corner coordinates
%valaoi=[lon1 lat1 lon2 lat2; lon1 lat1 lon2 lat2]
```
## GSBA Job Execution Flow
Driver file: ```gsba_driver```

Launch MATLAB, and you can get the help menu direction by using ```help```:
```
>>help gsba_driver
function gsba_driver(startfrom,endat,fconfig,[ft,splitid])
 fconfig: configure file 
 ct: change type, 1=amp- changes
                  3=amp+ changes
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
   step 16: g16_roc.m        : calculate ROC curve (val file required)
```

To run the entire flow in one go, do:
```
>>gsba_driver(1,15,'config.txt')
```

## HSBA Job Execution Flow
Driver file: ```hsba_driver```

Launch MATLAB, and you can get the help menu direction by using ```help```:
```
>>help hsba_driver
function hsba_driver(startfrom,endat,fconfig,[ft,splitid])
```
