function hsba_driver(startfrom,endat,fconfig)
%function hsba_driver(startfrom,endat,fconfig)
% Execute HSBA (Hierarchical Split Based Approach) for change detection
%
% Note: current input file should be a Z-score map
%       to change default histogram fitting setup, go to
%       SBATool/kernel/setGaussianInitials.m
%
% fconfig: configure file 
% step can be the following. 
%   step 1:  g01_filter       : data preparation
%   step 2:  h02_hsba_G1.m    : hsba for Z- changes
%   step 3:  h03_hsba_G3.m    : hsba for Z+ changes
%   step 4:  h04_hsbaplow.m   : interpolate prob and create proxy maps for Z- changes
%   step 5:  h05_hsbaphigh.m  : interpolate prob and create proxy maps for Z+ changes
%   step 6:  h06_qcplothsba.m : QC plots
%   step 10: g10_cluster.m    : geospatial clustering 
%   step 11: g11_appyhand.m   : apply HANDEM
%   step 12: g12_xv.m         : cross-validation between two tracks (standalone)
%   step 13: g13_validate.m   : validate over known results 
%                               calculate ROC curve (optional)
%
% NinaLin@2023

startt=tic;

if ~exist(fconfig,'file'); error(sprintf('Config file %s does not exist!',fconfig)); end

loadparam;
display(sprintf('Image under process: %s',config('filename')));

if startfrom==1
    display('=============================================');
    display('step 1: prepare image');
    g01_filter(fconfig);
    if endat~=1; 
        if (ct==0)|(ct==1) %ct (changetype) is specified in fconfig
            startfrom=2;
        elseif ct==3
            startfrom=3;
        end
    end
end

if startfrom==2
    display('=============================================');
    display('step 2: running HSBA for Z- changes');
    h02_hsba_G1(fconfig);
    if endat~=2; 
        if (ct==0)|(ct==3) %ct (changetype) is specified in fconfig
            startfrom=3;
        elseif ct==1
            startfrom=4;
        end
    end
end

if startfrom==3
    display('=============================================');
    display('step 3: running HSBA for Z+ changes');
    h03_hsba_G3(fconfig);
    if endat~=3
        if (ct==0)|(ct==1) %ct (changetype) is specified in fconfig
            startfrom=4;
        elseif ct==3
            startfrom=5;
        end
    end
end

if startfrom==4
    display('=============================================');
    display('step 4: fill statistics for Z- changes');
    h04_hsbaplow(fconfig);
    if endat~=4 
        if (ct==0)|(ct==3) %ct (changetype) is specified in fconfig
            startfrom=5;
        elseif ct==1
            startfrom=6;
        end
    end
end

if startfrom==5
    display('=============================================');
    display('step 5: fill statistics for Z+ changes');
    h05_hsbaphigh(fconfig);
    if endat~=5 
        startfrom=6; 
    end
end

if startfrom==6 
    display('=============================================');
    display('step 6: plot QC metrics');
    h06_qcplothsba(fconfig);
    if endat~=6; startfrom=10; end
end

if startfrom==10  % not a standard flow
    display('=============================================');
    display('step 10: apply geospatial clustering');
    g10_cluster(fconfig);
    if endat~=10; startfrom=11; end
end

if startfrom==11  % not a standard flow
    display('=============================================');
    display('step 11: apply handem thresholding');
    if dohandem
        g11_applyhand(fconfig);
    else
        display('Step skipped because dohandem=false');
    end
    if endat~=11; startfrom=12; end
end

if startfrom==12  % not a standard flow
    display('=============================================');
    display('step 12: cross validationing using two files (two tracks)');
    display('         run this function separately by: ');
    display('         g12_xv(file1,file2,configfile)');
    display('         or');
    display('         g12_xv(file1,file2,clusterdist,clusterarea)');
    if endat~=12; startfrom=13; end
end

if startfrom==13  % not a standard flow
    display('=============================================');
    display('step 13: validation using other mapping results');
    display('         By default, it validates all the files specified in');
    display('         ./qc/finalfile*.txt');
    display('         To validate separate files, do:');
    display('         g13_validate(configfile,infile)');
    g13_validate(fconfig); 
end

if startfrom>13 || endat>13 || startfrom<1 || endat<1
    error('start and end step can only be between 1 and 13.');
end

tt=toc(startt);
fprintf(1,'HSBA ends. Total runtime is %0.1f seconds.\n',tt);

return;
