function mat2geotiff(A,X,Y,fnameGeotiff,xyformat,varargin)
% FUNCTION mat2geotiff(A,X,Y,fnameGeotiff,xyformat,[ref_type,image_depth,option,geotiffinfo])
%
% A: input matrix
% X: vector for X coordinates
% Y: vector for Y coordinates
% fnameGeotiff: output geotiff fname
% xyformat: 'geotiff' or 'isce'
% ref_type: 1: geographic - default (lon/lat); 2: planar (x/y)
% image_depth: 1 for 1-bit monochrome data (i.e. binary or bilevel)
%              8 for 8-bit unsigned integer
%              16 for 16-bit signed integer
%              32 for 32-bit floating point (default)
%              -16 for 16-bit unsigned integer
%              -32 for 32-bit signed integer
% option: option for geotiffwrite2
% geotiffinfo: info file from geotiffinfo (if ref_type = 2)
%
% To export ordinary matlab matrix into tif (lon/lat coordinates ONLY), do:
%
% mat2geotiff(A,X,Y,'outputName.tif','isce',1)
%
% Nina Lin @ 2019

if numel(varargin) >= 1; ref_type = varargin{1}; else; ref_type = 1; end
if numel(varargin) >= 2; img_depth = varargin{2}; end
if numel(varargin) >= 3; option = varargin{3}; end
if numel(varargin) >= 4; info = varargin{4}; end

% extent = 1/3600;
incX = abs(mean(diff(X)));
incY = abs(mean(diff(Y)));

switch xyformat
  case 'geotiff'
    latlim = [min(Y(:)) max(Y(:))];  % to be compatible with QGIS SaveAS
    lonlim = [min(X(:)) max(X(:))];  % same as above
    bbox   = [min(X(:)) min(Y(:));
              max(X(:)) max(Y(:))];
  case 'isce'
    latlim = [min(Y(:))-incY/2 max(Y(:))+incY/2];  % to be compatible with 
    lonlim = [min(X(:))-incX/2 max(X(:))+incX/2];  % allras15n6c file
    bbox   = [min(X(:))-incX/2 min(Y(:))-incY/2;   % change back to this on 2020-04-10
              max(X(:))+incX/2 max(Y(:))+incY/2];
  otherwise
    error('Need to specify input xy format. 1=from geotiff, 2=frome isce.')
end
rasterSize = size(A);
switch ref_type
    case 1 % geographic; lon/lat
        R = georefcells(latlim,lonlim,rasterSize,'ColumnsStartFrom','north');
        if exist('info','var')
            R = info.SpatialRef;
        end
        geotiffwrite(fnameGeotiff,A,R);
%         if numel(varargin) == 3
%             geotiffwrite2(fnameGeotiff,bbox,A,img_depth,option);
%         elseif numel(varargin) == 2
%             geotiffwrite2(fnameGeotiff,bbox,A,img_depth);
%         else            
%             geotiffwrite2(fnameGeotiff,bbox,A);
%         end
        % R = georefcells(latlim,lonlim,rasterSize,'ColumnsStartFrom','north');
        % R.LatitudeLimits          = [min(Y(:)) max(Y(:))];
        % R.LongitudeLimits         = [min(X(:)) max(X(:))];
        % R.RasterSize              = size(A);
        % R.ColumnsStartFrom        = 'north';
        % R.CellExtentInLatitude    = range(Y)/(numel(Y)-1);
        % R.CellExtentInLongitude   = range(X)/(numel(X)-1);
        % R.RasterExtentInLatitude  = range(Y);
        % R.RasterExtentInLongitude = range(X);
        % R.XIntrinsicLimits        = [0.5 max(X(:))+0.5];
        % R.YIntrinsicLimits        = [0.5 max(Y(:))+0.5];
    case 2 % planar; x/y
        R = maprefcells(lonlim,latlim,rasterSize,'ColumnsStartFrom','north');
        if ~exist('info','var')
            error('Need to supply geotiffinfo in order to save geotiff as planar reference frame')
        end
        geoTags = info.GeoTIFFTags.GeoKeyDirectoryTag;
        geotiffwrite(fnameGeotiff,A,R,'GeoKeyDirectoryTag',geoTags);
end
        
