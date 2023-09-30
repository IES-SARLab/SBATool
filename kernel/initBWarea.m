function bw = initBWarea(imgFile,varargin)
% function areaInPixel = initBWarea(imgFile,config,keyname)
% or
% function areaInPixel = initBWarea(imgFile,A)
%
% imgFile: name of the image file
% A:       [m^2] area to be converted into pixels
% config:  config dictionary
% keyname: name in the config dictionary to obtain the
%          minimum patch area
% A minimum areaInPixel=2 is enforced at this current version

if numel(varargin)==0
    error('Need to supply [config, keyname] or area for the conversion!')
elseif numel(varargin)==1
    minArea = varargin{1};
elseif numel(varargin)==2
    config  = varargin{1};
    keyname = varargin{2};
end

minPixel = 2;

if exist('config','var')
    if isKey(config,keyname)
        minArea=eval(config(keyname));
        pixelres = getPixelRes(imgFile,config,'pixelres');
        pixelarea = pixelres*pixelres;
        bw = round(minArea/pixelarea);
        if bw<minPixel; bw=minPixel; end %ensure rookit neighbor is considered
    else
        error(sprintf('The key %s does not exsit in config.txt file!\n',keyname));
    end
elseif exist('minArea','var')
    pixelres = getPixelRes(imgFile);
    pixelarea = pixelres*pixelres;
    bw = round(minArea/pixelarea);
    if bw<minPixel; bw=minPixel; end %ensure rookit neighbor is considered
end

