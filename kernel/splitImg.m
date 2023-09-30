function [sx0,sx1,sy0,sy1,scx0,scx1,scy0,scy1,sxm0,sxm1,sym0,sym1]=splitImg(Isizes,splitsize,type,varargin)
%function [sx0,sx1,sy0,sy1,scx0,scx1,scy0,scy1,sxm0,sxm1,sym0,sym1]=splitImg(Isizes,splitsize,type,[overlapRatio])
%
% INPUT:
% Isize:   [nx ny]
% splitsize: number of splits in x and y [splitx, splity] or a single value
% type = grideline or gridnode for the output x and y coordinates 
% overlapRatio: overlapping ratio between splits, must be <1 (default=0)
%
% OUTPUT:
% sx0:  starting x indices for splits
% sx1:  endingi  x indices for splits
% sy0:  starting y indices for splits
% sy1:  ending   y indices for splits
% scx0: starting x coordinates for splits
% scx1: endingi  x coordinates for splits
% scy0: starting y coordinates for splits
% scy1: ending   y coordinates for splits
% sxm0: starting x indices to merge overlapping splits
% sxm1: endingi  x indices to merge overlapping splits
% sym0: starting y indices to merge overlapping splits
% sym1: ending   y indices to merge overlapping splits

if numel(varargin)>0; olratio=varargin{1}; else; olratio=0; end 
if olratio==1; error('overlapRatio must be less than 1!'); end

if numel(splitsize)==2
    splitx = splitsize(1);
    splity = splitsize(2);
else
    splitx = splitsize;
    splity = splitsize;
end

incX   = ceil(Isizes(2)/splitx);
incY   = ceil(Isizes(1)/splity);
mvupx = round((1-olratio)*incX); %moving up in x
mvupy = round((1-olratio)*incY); %moving up in y
incXmrg = round((olratio/2)*incX);
incYmrg = round((olratio/2)*incY);

sx0 = 1:mvupx:Isizes(2);
sx1 = incX:mvupx:Isizes(2);
sy0 = 1:mvupy:Isizes(1);
sy1 = incY:mvupy:Isizes(1);
if abs(sx0(end)-Isizes(2))<incX/2; sx0 = sx0(1:end-1); end
if abs(sx1(end)-Isizes(2))<incX/2; sx1 = [sx1(1:end-1) Isizes(2)]; else; sx1 = [sx1 Isizes(2)]; end
if abs(sy0(end)-Isizes(1))<incY/2; sy0 = sy0(1:end-1); end
if abs(sy1(end)-Isizes(1))<incY/2; sy1 = [sy1(1:end-1) Isizes(1)]; else; sy1 = [sy1 Isizes(1)]; end
switch type
    case 'gridline' %geotiff
        scx0 = sx0;
        scx1   = sx1+1;
        scy0 = sy0;
        scy1   = sy1+1;
    case 'gridnode' %isce
        scx0 = sx0;
        scx1   = sx1;
        scy0 = sy0;
        scy1   = sy1;
    otherwise
        error('type needs to be either gridline or gridnoe')
end

sxm0 = [1 sx0(2:end)+incXmrg];
sxm1 = [sx1(1:end-1)-incXmrg sx1(end)];
sym0 = [1 sy0(2:end)+incYmrg];
sym1 = [sy1(1:end-1)-incYmrg sy1(end)];

end
