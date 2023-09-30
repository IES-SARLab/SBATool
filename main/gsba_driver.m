function gsba_driver(startfrom,endat,fconfig,varargin)
%function gsba_driver(startfrom,endat,fconfig,[splitid])
% Execute GSBA (Growing Split Based Approach) for change detection
% 
% Note: current input file should be a Z-score map
%       to change default histogram fitting setup, go to
%       SBATool/kernel/setGaussianInitials.m
%
% fconfig: user-specified configuration file
% splitid: the split ID when the image is too large 
%          and is split into multiple subimages
%          for a (2x2) split, the splitid is
%           1 2
%           3 4
%
% step can be the following. 
%   step 1:  g01_filter       : data preparation
%   step 2:  g02_init         : initialize tile splitting and histogram fitting
%   step 3:  g03_growlow.m    : tile growing for Z- changes
%   step 4:  g04_growhigh.m   : tile growing for Z+ changes
%   step 5:  g05_interplow.m  : fill statistics for Z- changes
%   step 6:  g06_interphigh.m : fill statistics for Z+ changes
%   step 7:  g07_qcmetrics.m  : calculate QC metrics
%   step 8:  g08_qcplotlow.m  : QC plot for Z- changes
%   step 9:  g09_qcplothigh.m : QC plot for Z+ changes
%   step 10: g10_cluster.m    : geospatial clustering 
%   step 11: g11_applyhand.m  : apply HANDEM
%   step 12: g12_xv.m         : cross-validation between two tracks (stand alone)
%   step 13: g13_validate.m   : validate over known results
%                               calculate ROC curve (optional)
%
% NinaLin@2023

startt=tic;

if ~exist(fconfig,'file'); error(sprintf('Config file %s does not exist!',fconfig)); end

loadparam;
display(sprintf('Image under process: %s',config('filename')));

if numel(varargin)>0; splitid=varargin{1}; end
 
if startfrom==1
    display('=============================================');
    display('step 1: data preparation');
    g01_filter(fconfig);
    if endat~=1; startfrom=2; end
end

if startfrom==2
    display('=============================================');
    display('step 2: initialize tile splitting and histogram fitting');
    if doparallel&&~exist('gp','var')&&numel(gcp('nocreate'))==0; 
        gp=parpool(npool);
        fprintf(1,'Initialize parpool with %d processors',npool)
    end
    if dosplit
        if exist('splitid','var')
            g02_init(fconfig,splitid);
        else
            error('Need to specify which splitid to process!');
        end
    else
        g02_init(fconfig);
    end
    if endat~=2; 
        if (ct==0)|(ct==1) %ct (changetype) is specified in fconfig
            startfrom=3;
        elseif ct==3
            if ~split
                startfrom=4;
            else
                display('if dosplit=true, need to manually check if all splits finishes')
                display('Once done, continue to step 4');
                error('Cannot automatically continue to step 4 in split mode');
            end
        end
    end
end

if startfrom==3
    display('=============================================');
    display('step 3: tile growing for Z- changes');
    if doparallel&&~exist('gp','var')&&numel(gcp('nocreate'))==0; 
        gp=parpool(npool);
        fprintf(1,'Initialize parpool with %d processors',npool)
    end
    if dosplit
        if exist('splitid','var')
            g03_growlow(fconfig,splitid);
        else
            error('Need to specify which splitid to process!');
        end
    else
        g03_growlow(fconfig);
    end
    if endat~=3
        if (ct==0)|(ct==3) %ct (changetype) is specified in fconfig
            startfrom=4;
        elseif ct==1
            if ~split
                startfrom=5;
            else
                display('if dosplit=true, need to manually check if all splits finishes')
                display('Once done, continue to step 7');
                error('Cannot automatically continue to step 7 in split mode');
            end
        end
    end
end

if startfrom==4
    display('=============================================');
    display('step 4: tile growing for Z+ changes');
    if doparallel&&~exist('gp','var')&&numel(gcp('nocreate'))==0; 
        gp=parpool(npool);
        fprintf(1,'Initialize parpool with %d processors',npool)
    end
    if dosplit
        if exist('splitid','var')
            g04_growhigh(fconfig,splitid);
        else
            error('Need to specify which splitid to process!');
        end
    else
        g04_growhigh(fconfig);
    end
    if endat~=4
        if (ct==0)|(ct==1) %ct (changetype) is specified in fconfig
            startfrom=5; 
        elseif ct==3
            if ~split
                startfrom=6;
            else
                display('if dosplit=true, need to manually check if all splits finishes')
                display('Once done, continue to step 8');
                error('Cannot automatically continue to step 8 in split mode');
            end
        end
    end
end

if startfrom==5
    display('=============================================');
    display('step 5: fill statistics for Z- changes');
    if doparallel&&~exist('gp','var')&&numel(gcp('nocreate'))==0; 
        gp=parpool(npool);
        fprintf(1,'Initialize parpool with %d processors',npool)
    end
    g05_interplow(fconfig);
    flag_step5=1;
    save('step5.flag','flag_step5','-ascii');
    if endat~=5 
        if (ct==0)|(ct==3) %ct (changetype) is specified in fconfig
            startfrom=6; 
        elseif ct==1
            if exist('step6.flag','file') 
                startfrom=7;
            else
                display('Step 5 finished.');
                display('Becasue step 6 is not finished (step6.flag not exist)');
                display('and ct=1, cannot continue to the next step.');
                display('Try to set ct=3 and start from step 6');
                error('Cannot continue to step 7');
            end
        end
    end
end

if startfrom==6
    display('=============================================');
    display('step 6: fill statistics for Z+ changes');
    if doparallel&&~exist('gp','var')&&numel(gcp('nocreate'))==0; 
        gp=parpool(npool);
        fprintf(1,'Initialize parpool with %d processors',npool)
    end
    g06_interphigh(fconfig);
    flag_step6=1;
    save('step6.flag','flag_step6','-ascii');
    if endat~=6 
        if (ct==0)|(ct==1) %ct (changetype) is specified in fconfig
            startfrom=7; 
        elseif ct==3
            if exist('step5.flag','file') 
                startfrom=7;
            else
                display('Step 6 finished.');
                display('Becasue step 5 is not finished (step5.flag not exist)');
                display('and ct=3, cannot continue to the next step.');
                display('Try to set ct=1 and start from step 5');
                error('Cannot continue to step 7');
            end
        end
    end
end

if startfrom==7 
    display('=============================================');
    display('step 7: calculate QC metrics');
    g07_qcmetrics(fconfig);
    if endat~=7 
        if (ct==0)|(ct==1) %ct (changetype) is specified in fconfig
            startfrom=8; 
        elseif ct==3
            startfrom=10;
        end
    end
end

if startfrom==8
    display('=============================================');
    display('step 8: plot QC images for Z- changes');
    g08_qcplotlow(fconfig);
    if endat~=8 
        if (ct==0)|(ct==3) %ct (changetype) is specified in fconfig
            startfrom=9; 
        elseif ct==1
            startfrom=10;
        end
    end
end

if startfrom==9
    display('=============================================');
    display('step 9: plot QC images for Z+ changes');
    g09_qcplothigh(fconfig);
    if endat~=9; startfrom=10; end
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
fprintf(1,'GSBA ends. Total runtime is %0.1f seconds.\n',tt);

end

