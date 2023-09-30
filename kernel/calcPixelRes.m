function pixelres = calcPixelRes(imgFile)
%function pixelres = calcPixelRes(imgFile)
% 
% pixelres: in meters


[~,~,~,info] = readRaster(imgFile);
latc = mean(info.SpatialRef.LatitudeLimits);
lon1 = info.SpatialRef.LongitudeLimits(1);
lon2 = info.SpatialRef.LongitudeLimits(2);
latlon1 = [latc lon1];
latlon2 = [latc lon2];
dkm = lldistkm(latlon1, latlon2);
pixelres = round(dkm*1e3/info.SpatialRef.RasterSize(2));
