function [X,Y] = geotiffinfo2xy(info,varargin)
% [X,Y] = geotiffinfo2xy(info,[type])
%
% type: geotiff (default) or isce
%

if numel(varargin)>0
    type = varargin{1};
else
    type = 'geotiff';
end

switch type

    case 'geotiff' %gridline
        try 
            bbox  = info.BoundingBox;
            ny = info.Height;
            nx = info.Width;
            X = linspace(bbox(1,1),bbox(2,1),nx+1);
            Y = linspace(bbox(1,2),bbox(2,2),ny+1);
        catch ME
            bboxLon=info.LongitudeLimits;
            bboxLat=info.LatitudeLimits;
            nsize  =info.RasterSize;
            X = linspace(bboxLon(1),bboxLon(2),nsize(2)+1);
            Y = linspace(bboxLat(1),bboxLat(2),nsize(1)+1);
        end
    case 'isce' %gridnode
        try 
            bbox  = info.BoundingBox;
            ny = info.Height;
            nx = info.Width;
            dx = abs(bbox(1,1)-bbox(2,1))/nx;
            dy = abs(bbox(1,2),bbox(2,2))/ny;
            X = linspace(bbox(1,1)+dx/2,bbox(2,1)-dx/2,nx);
            Y = linspace(bbox(1,2)+dy/2,bbox(2,2)-dy/2,ny);
        catch ME
            bboxLon=info.LongitudeLimits;
            bboxLat=info.LatitudeLimits;
            nsize  =info.RasterSize;
            dx = abs(bboxLon(1)-bboxLon(2))/nsize(2);
            dy = abs(bboxLat(1)-bboxLat(2))/nsize(1);
            X = linspace(bboxLon(1)+dx/2,bboxLon(2)-dx/2,nsize(2));
            Y = linspace(bboxLat(1)+dy/2,bboxLat(2)-dy/2,nsize(1));
        end
    otherwise
        error('type can only be geotiff or isce!');
end
