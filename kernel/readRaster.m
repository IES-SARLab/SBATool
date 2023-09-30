function [I,X,Y,varargout] = readRaster(filename,varargin)
%function [I,X,Y,(info)] = readRaster(filename,[out_xyformat])
% out_xyformat: 'isce' or 'tif' for output XY format conversion
%               'isce'--> gridnode 
%               'tif' --> gridline
%               Leave blank if output the same xyformat as indicated by the file type
% info: the info used for geotiff

if numel(varargin)>0; xyformat=varargin{1}; else; xyformat='none'; end

[fpath,fname,fext] = fileparts(filename);

if ~exist(filename,'file')
    error(sprintf('File %s does not exist!',filename));
end

switch fext
    case '.tif'
        I = geotiffread(filename);
        info  = geotiffinfo(filename);
        [X,Y] = geotiffinfo2xy(info);
        if strcmp(xyformat,'isce')
            [X,Y] = xyconvert(X,Y,'tif2isce');
        end
        varargout{1}=info;
    case '.img'
        fhdr = strrep(filename,'.img','.hdr');
        [I, info] = enviread(filename,fhdr);
        X = info.x;
        Y = info.y;
        if strcmp(xyformat,'tif')
            [X,Y,R] = xyconvert(X,Y,'isce2tif');
            info.SpatialRef = R;
        end
        varargout{1}=info;
    otherwise
        try
            [I,X,Y] = isceread(filename);
            if strcmp(xyformat,'tif')
                [X,Y,R] = xyconvert(X,Y,'isce2tif');
                info={};
                info.SpatialRef = R;
                varargout{1}=info;
            else
                varargout{1}={};
            end
        catch ME
            error('Suported format: .tif, .img or isce formats')
        end
end    
