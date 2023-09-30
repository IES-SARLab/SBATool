function [tile, xtilevec, ytilevec] = img2Tile(I,tsize,shift,varargin)
%function [tile, xtilevec, ytilevec] = img2Tile(I,tsize,shift,[method])
% method: mean, median, max, min, geom (export xtilevec, ytilevec only)

if numel(varargin)>0; method=varargin{1}; else; method='mean'; end

[xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(size(I),tsize,shift);

xtilevec = [xtileStart; xtileEnd];
ytilevec = [ytileStart; ytileEnd];

nxtile = numel(xtileStart);
nytile = numel(ytileStart);

tile = zeros(nytile,nxtile);
switch method
    case 'geom'
        return
    case 'mean'
        for ii=1:nytile
            for jj=1:nxtile
                tmpImg = I(ytileStart(ii):ytileEnd(ii),xtileStart(jj):xtileEnd(jj));
                tile(ii,jj) = nanmean(tmpImg(:));
            end
        end
    case 'median'
        for ii=1:nytile
            for jj=1:nxtile
                tmpImg = I(ytileStart(ii):ytileEnd(ii),xtileStart(jj):xtileEnd(jj));
                tile(ii,jj) = nanmedian(tmpImg(:));
            end
        end
    case 'max'
        for ii=1:nytile
            for jj=1:nxtile
                tmpImg = I(ytileStart(ii):ytileEnd(ii),xtileStart(jj):xtileEnd(jj));
                tile(ii,jj) = nanmax(tmpImg(:));
            end
        end
    case 'min'
        for ii=1:nytile
            for jj=1:nxtile
                tmpImg = I(ytileStart(ii):ytileEnd(ii),xtileStart(jj):xtileEnd(jj));
                tile(ii,jj) = nanmin(tmpImg(:));
            end
        end
    otherwise
        error('Method can only be: mean, median, max or min');
end
