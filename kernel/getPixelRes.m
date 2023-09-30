function pixelres = getPixelRes(imgFile,varargin)
%function pixelres = getPixelRes(imgFile,[config,keyname])
% imgFile: name of the image file
% config:  config dictionary
% keyname: name in the config dictionary to obtain the
%          target value

if numel(varargin)==2
    config  = varargin{1};
    keyname = varargin{2};
end

if exist('config','var')
    if isKey(config,keyname)
        pixelres=eval(config(keyname));
    else
        pixelres = calcPixelRes(imgFile);
    end
else
    pixelres = calcPixelRes(imgFile);
end


