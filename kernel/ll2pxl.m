function pxlXY = ll2pxl(lonvec,latvec,lon,lat)

% check latvec direction
if (latvec(1)-latvec(end))<0
    latvec = latvec(end:-1:1);
end

for ii=1:numel(lon)
    Dx = (lonvec-lon(ii)).^2;
    Dy = (latvec-lat(ii)).^2;
    
    ix = find( Dx==min(Dx) );
    iy = find( Dy==min(Dy) );
    
    pxlXY(ii,:)=[ix iy];
end
