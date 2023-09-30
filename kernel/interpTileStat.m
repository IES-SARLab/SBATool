function [GAhat,GMhat,GShat,GMhattile,GShattile] = interpTileStat(ampEventNorm,GAt,GMt,GSt,xtilevec,ytilevec,method,varargin)
%function [GAhat,GMhat,GShat,GMhattile,GShattile] = interpTileStat(ampEventNorm,GAt,GMt,GSt,xtilevec,ytilevec,method,[quantile])

bsize = 2000;

%display(sprintf('Begin interpolating tile statistics using method %s',method))


[xx,yy] = meshgrid(1:size(GMt,2),1:size(GMt,1));
indg1  = find(GMt~=0);
indg1n = setdiff(1:numel(GMt),indg1);
vala1 = GAt(indg1);
valm1 = GMt(indg1);
vals1 = GSt(indg1);
if numel(valm1)>0
    GAhattile = GAt;
    GMhattile = GMt;
    GShattile = GSt;
    switch method
        case 'wmean'
            GAhattile(indg1n) = mean(vala1);
            GMhattile(indg1n) = mean(valm1);
            GShattile(indg1n) = mean(vals1);
            tmp    = imgaussfilt(GAhattile,1);
            scaleA = GAhattile(indg1)./tmp(indg1);
            tmp    = imgaussfilt(GMhattile,1);
            scaleM = GMhattile(indg1)./tmp(indg1);
            tmp    = imgaussfilt(GShattile,1);
            scaleS = GShattile(indg1)./tmp(indg1);
            GAhat = tile2Img(imgaussfilt(GAhattile,1)*quantile(scaleA(:),1), xtilevec, ytilevec);        
            GMhat = tile2Img(imgaussfilt(GMhattile,1)*quantile(scaleM(:),1), xtilevec, ytilevec);        
            GShat = tile2Img(imgaussfilt(GShattile,1)*mean(scaleS(:)), xtilevec, ytilevec); 
        case 'mean'
            GAhattile(indg1n) = mean(unique(vala1));
            GMhattile(indg1n) = mean(unique(valm1));
            GShattile(indg1n) = mean(unique(vals1));
            % smooth the boundary at a finer tsize 
            [GMt2,xtilevec2,ytilevec2] = divideTile(GMt,xtilevec,ytilevec,3);
            GAt2 = divideTile(GAt,xtilevec,ytilevec,3);
            GSt2 = divideTile(GSt,xtilevec,ytilevec,3);
            GAt2 = dilate(GAt2,1);
            GMt2 = dilate(GMt2,1);
            GSt2 = dilate(GSt2,1);
            GAt2((GAt2==0))=mean(unique(vala1));
            GMt2((GMt2==0))=mean(unique(valm1));
            GSt2((GSt2==0))=mean(unique(vals1));
            GAhat = tile2Img(imgaussfilt(GAt2,1),xtilevec2,ytilevec2);
            GMhat = tile2Img(imgaussfilt(GMt2,1),xtilevec2,ytilevec2);
            GShat = tile2Img(imgaussfilt(GSt2,1),xtilevec2,ytilevec2);
        case 'quantile'
            methodq = varargin{1};
            GAhattile(indg1n) = mean(unique(vala1));
            GMhattile(indg1n) = quantile(unique(abs(valm1)),methodq)*sign(mean(valm1));
            GShattile(indg1n) = mean(unique(vals1));
            tmp    = imgaussfilt(GAhattile,1);
            scaleA = GAhattile(indg1)./tmp(indg1);
            tmp    = imgaussfilt(GMhattile,1);
            scaleM = GMhattile(indg1)./tmp(indg1);
            tmp    = imgaussfilt(GShattile,1);
            scaleS = GShattile(indg1)./tmp(indg1);
            GAhat = tile2Img(imgaussfilt(GAhattile,1)*mean(scaleA(:)), xtilevec, ytilevec); 
            GMhat = tile2Img(imgaussfilt(GMhattile,1)*quantile(scaleM(:),1), xtilevec, ytilevec);        
            GShat = tile2Img(imgaussfilt(GShattile,1)*mean(scaleS(:)), xtilevec, ytilevec); 
        case 'const_mean'
            GAhattile = GAt*0+mean(unique(vala1));
            GMhattile = GMt*0+mean(unique(valm1));
            GShattile = GSt*0+mean(unique(vals1));
            GAhat = tile2Img(GAhattile, xtilevec, ytilevec);        
            GMhat = tile2Img(GMhattile, xtilevec, ytilevec);        
            GShat = tile2Img(GShattile, xtilevec, ytilevec);        
        case 'const_med'
            GAhattile = GAt*0+median(unique(vala1));
            GMhattile = GMt*0+median(unique(valm1));
            GShattile = GSt*0+median(unique(vals1));
            GAhat = tile2Img(GAhattile, xtilevec, ytilevec);        
            GMhat = tile2Img(GMhattile, xtilevec, ytilevec);        
            GShat = tile2Img(GShattile, xtilevec, ytilevec);        
        case 'const_max'
            GAhattile = GAt*0+mean(unique(vala1));
            GMhattile = GMt*0+quantile(unique(abs(valm1)),0.95)*sign(mean(valm1));
            GShattile = GSt*0+mean(unique(vals1));
            GAhat = tile2Img(GAhattile, xtilevec, ytilevec);        
            GMhat = tile2Img(GMhattile, xtilevec, ytilevec);        
            GShat = tile2Img(GShattile, xtilevec, ytilevec);  
        case 'const_q'
            methodq = varargin{1};
            GAhattile = GAt*0+mean(unique(vala1));
            GMhattile = GMt*0+quantile(unique(abs(valm1)),methodq)*sign(mean(valm1));
            GShattile = GSt*0+quantile(unique(abs(vals1)),methodq);
            GShattile = GSt*0+mean(unique(vals1));
            %GShattile = GSt*0+mean(unique(vals1));
            GAhat = tile2Img(GAhattile, xtilevec, ytilevec);        
            GMhat = tile2Img(GMhattile, xtilevec, ytilevec);        
            GShat = tile2Img(GShattile, xtilevec, ytilevec);  
        case 'invdist'
            GAhattile = invdistfill(GAt,bsize);
            GMhattile = invdistfill(GMt,bsize);
            GShattile = invdistfill(GSt,bsize);
            GAhat = tile2Img(imgaussfilt(GAhattile,.5), xtilevec, ytilevec);        
            GMhat = tile2Img(imgaussfilt(GMhattile,.5), xtilevec, ytilevec);        
            GShat = tile2Img(imgaussfilt(GShattile,.5), xtilevec, ytilevec);  
    end  
else
    GAhat = tile2Img(GAt, xtilevec, ytilevec);        
    GMhat = tile2Img(GMt, xtilevec, ytilevec);        
    GShat = tile2Img(GSt, xtilevec, ytilevec);        
    GAhattile = GAt*0;
    GMhattile = GMt*0;
    GShattile = GSt*0;
end

%display(sprintf('Done interpolating tile statistics using method %s',method))

