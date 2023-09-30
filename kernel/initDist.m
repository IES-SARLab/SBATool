function distInPixel = initDist(imgFile,varargin)
% function distInPixel = initDist(imgFile,config,keyname)
% or
% function distInPixel = initDist(imgFile,D)
%
% imgFile: name of the image file
% D:       [m] distance to be converted into pixels
% 
% config:  config dictionary
% keyname: name in the config dictionary to obtain the
%          distance in meter

if numel(varargin)==0
    error('Need to supply [config, keyname] or distance for the conversion!')
elseif numel(varargin)==1
    minDist = varargin{1};
elseif numel(varargin)==2
    config  = varargin{1};
    keyname = varargin{2};
end

if exist('config','var')
    if isKey(config,keyname)
        minDist=eval(config(keyname));
        pixelres = getPixelRes(imgFile,config,'pixelres');
        distInPixel=round(minDist/pixelres);
    else
        error(sprintf('The key %s does not exsit in config.txt file!\n',keyname));
    end
elseif exist('minDist','var')
    pixelres = getPixelRes(imgFile);
    distInPixel=round(minDist/pixelres);
end

