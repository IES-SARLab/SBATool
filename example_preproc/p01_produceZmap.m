%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example script to produce Z-score map
%   from a stack of amplitude images
%
% NinaLin@2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

stackdir  = './stack_tif';
flist  = dir(sprintf('%s/*tif',stackdir)); %supported format: tif, img, isce formats
%stackdir  = './stack_isce';
%flist  = dir(sprintf('%s/*geo',stackdir)); %supported format: tif, img, isce formats
eventdate = datetime('20161011','InputFormat','yyyyMMdd');
dolee     = 1;
leeWin    = [5 5];

fnames = extractfield(flist,'name');
for ii=1:numel(fnames)
    [~,prefix]=fileparts(fnames{ii});
    dates(ii)=datetime(prefix,'InputFormat','yyyyMMdd');
end
refInd = find( dates == eventdate);
bkInd  = setdiff(1:numel(flist),refInd);

% apply lee filter (the following scripts assume amplitude as input files)  
[ampEvent,X,Y] = readRaster(sprintf('%s/%s',stackdir,flist(refInd).name),'isce');
stackDn   = zeros(size(ampEvent,1),size(ampEvent,2),numel(bkInd));
if dolee
    for ii = 1:numel(bkInd)   
        infile = sprintf('%s/%s',stackdir,fnames{bkInd(ii)});
        display(sprintf('Loading file %s',infile));
        stackDn(:,:,ii) = 10*log10(lee(readRaster(infile),leeWin,1).^2); %turn into sigma_0 in dB
    end
else
    for ii = 1:numel(bkInd)   
        infile = sprintf('%s/%s',stackdir,fnames{bkInd(ii)});
        display(sprintf('Loading file %s',infile));
        stackDn(:,:,ii) = 10*log10(readRaster(infile).^2); %turn into sigma_0 in dB
    end
end

ampMean  = nanmean(stackDn,3);
ampStdDn = nanstd(stackDn,0,3);
ampEventNorm = (ampEvent-ampMean)./ampStdDn;
mat2geotiff(ampEventNorm,X,Y,'lumberton.tif','geotiff')
