# SBATool
Split-based Approach for SAR-based Change Detection

## Environment Preparation
Add subfolder ```main``` and ```kernel``` to your Matlab path

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
