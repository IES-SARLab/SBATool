function g01_filter(fconfig)
%function g01_filter(fconfig)
% Load image and configuration files
% 
% fconfig: user-specified configuration file
%
% Other default configurations can be changed at
% SBATool/main/sba.config
%
% NinaLin@2023

loadparam;

outImg   = sprintf('%s/%s.tif',fpmdir,prefix);

% read in image and apply lee filter
[ampEventNorm,X,Y,info]=readRaster(inpZmap,'tif');
if dolee
    ampEventNormLee = lee(ampEventNorm,[filtwin filtwin],3);
    ampEventNormLee(isnan(ampEventNorm)) = nan;
else
    ampEventNormLee = ampEventNorm;
end

% check if maskfile exist
if usemask
    maskfile = dir(sprintf('%s_mask.*',prefix));
    if numel(maskfile)==0
        error(sprintf('Cannot find mask file in the current folder!'));
    elseif numel(maskfile)>1
        error(sprintf('Find multiple mask files in the current folder!'));
    end
    masktmp=readRaster(maskfile.name); 
    mask=cast(masktmp,class(ampEventNorm));
    ampEventNormLee = ampEventNormLee.*(mask==0); %0 is for non-masked part
end

if mean(diff(X))>1  %projected
    mat2geotiff(ampEventNormLee, X,Y,outImg,'geotiff',2,16,[],info);
else %rereferenced
    mat2geotiff(ampEventNormLee, X,Y,outImg,'geotiff',1,16);
end

%% to split filts
if  isKey(config,'dosplit') & eval(config('dosplit'))
    sp = eval(config('splitsize'));
    Y = fliplr(Y);  % from top to bot
    [spx0,spx1,spy0,spy1,spcx0,spcx1,spcy0,spcy1] = splitImg(size(ampEventNorm),sp,'gridline');
    for ii = 1:sp(1)
        for jj = 1:sp(2)
            splitX   = X(spcx0(jj):spcx1(jj));
            splitY   = fliplr(Y(spcy0(ii):spcy1(ii)));  % from small to large
            outSplitImg = strrep(outImg,'.tif',sprintf('_%d.tif',sub2ind(sp,ii,jj)));
            cmd = sprintf('gdalwarp -te %f %f %f %f %s %s',splitX(1),splitY(1),splitX(end),splitY(end),outImg,outSplitImg);
            status=system(cmd);
            if status ~=0
                display(sprintf('ERROR splitting %s to %s; check if you have gdal installed.',outImg,outSplitImg));
            end
        end
    end
end
