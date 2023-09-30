function lookpF = initLook(imgFile,varargin)
%function lookpF = initLook(imgFile,[config,keyname])
% config:  config dictionary
% keyname: name in the config dictionary to obtain the
%          target value
% imgFile: name of the image file

%Use Sentinel as reference
%Basic QC resolution is 100m
QCres = 100; %m
minLook = 1;
maxLook = 10;
noLookArea = 500^2;

if numel(varargin)==2
    config  = varargin{1};
    keyname = varargin{2};
end 

if exist('config','var')
    if isKey(config,keyname)
        lookpF=eval(config(keyname));
    elseif exist(imgFile,'file')
        if numel(readRaster(imgFile))<noLookArea
            lookpF=minLook;
        else
            pixelres = getPixelRes(imgFile,config,'pixelres');
            lookpF = min([floor(QCres/pixelres) maxLook]);
        end
    else
        error(sprintf('File %s does not exist!',imgFile));
    end
    if lookpF<minLook; lookpF=minLook; end
else
    if exist(imgFile,'file')
        if numel(readRaster(imgFile))<noLookArea
            lookpF=minLook;
        else
            pixelres = getPixelRes(imgFile);
            lookpF = min([floor(QCres/pixelres) maxLook]);
        end
    else
        error(sprintf('File %s does not exist!',imgFile));
    end
    if lookpF<minLook; lookpF=minLook; end
end

