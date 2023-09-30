function [outX,outY,varargout]  = xyconvert(inX,inY,type)
%function [outX,outY,(R)] = xyconvert(inX,inY,type)
%
% type: isce2tif, tif2isce
% R: the Spatial Reference information for geotiff 

switch type
    case 'tif2isce' %gridline to gridnode
            outX = (inX(1:end-1)+inX(2:end))/2;
            outY = (inY(1:end-1)+inY(2:end))/2;
            R = [];
            varargout{1} = R; 
    case 'isce2tif' %gridnode to gridline 
            dx = abs(mean(diff(inX)));
            dy = abs(mean(diff(inY)));
            nx = numel(inX);
            ny = numel(inY);
            outX = linspace(min(inX)-dx/2,max(inX)-dx/2,nx+1);
            outY = linspace(min(inY)-dy/2,max(inY)+dy/2,ny+1);
            latlim = [min(outY) max(outY)];
            lonlim = [min(outX) max(outX)];
            rasterSize=[ny nx];
            R = georefcells(latlim,lonlim,[ny nx],'ColumnsStartFrom','north');
            varargout{1} = R;
    otherwise
        error('type can only be tif2isce or isce2tif!');
end
