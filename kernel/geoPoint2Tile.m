function [itx,ity] = geoPoint2Tile(px,py,xx,yy,tsize,shift)
%function [idx,idy] = geoPoint2Tile(px,py,I,xx,yy,tsize)
%
%  px, py:  geo-coordinates of target point (vector)
%  xx, yy:  geo-cooridnates of the entire image (matrix)
%  tsize:   tile size
%
%  itx, ity: tile x and y index for target point (vector)
%
%  Nina Lin @ 2020

[xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(xx,tsize,shift);
if yy(1) < yy(end)
  yy = flipud(yy);
end

for ii = 1:numel(px)
    dist = (xx-px(ii)).^2 + (yy-py(ii)).^2;
    [iy,ix] = ind2sub(size(xx),find( dist == min(dist(:)) ));
    ixtmp = find( ix > xtileStart );
    iytmp = find( iy > ytileStart ); 
    itx(ii) = ixtmp(end);
    ity(ii) = iytmp(end);
end

