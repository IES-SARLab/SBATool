function Gfill = invdistfill(G,bsize)
% Gfill = invdistfill(G,bsize)
% Inverse Distance Interpolation of holes in data
% G: matrix with wholes
% bsize: processing block size (for memory reason)
% Nina Lin @ 2020

[xxt,yyt] = meshgrid(1:size(G,2),1:size(G,1));
indt  = find(G~=0);
indnt = 1:numel(G);
indxt = xxt(indt);
indyt = yyt(indt);
indmt = G(indt);
nKnown   = numel(indt);
nUnknown = numel(indnt);

if nUnknown > bsize
    bstart = 1:bsize:nUnknown;
    bend   = [bstart(2:end)-1 indnt(end)];
    Gfill  = G;
    for ii = 1:numel(bstart)    
        indtmp  = bstart(ii):bend(ii);
        nindtmp = numel(indtmp);
        xMat0  = repmat(xxt(indtmp)',1,nKnown);
        yMat0  = repmat(yyt(indtmp)',1,nKnown);
        sxMat0 = repmat(indxt',nindtmp,1); 
        syMat0 = repmat(indyt',nindtmp,1);
        dMat0  = sqrt((xMat0-sxMat0).^2 + (yMat0-syMat0).^2);
        wMat0  = 1./dMat0;
        mMat0  = repmat(indmt',nindtmp,1);
        wmMat0 = wMat0.*mMat0;
        G1hat  = sum(wmMat0,2)./sum(wMat0,2);
        Gfill(indtmp) = G1hat;
    end
    Gfill(indt) = indmt;    
else
    xMat  = repmat(xxt(indnt)',1,nKnown);
    yMat  = repmat(yyt(indnt)',1,nKnown);
    sxMat = repmat(indxt',nUnknown,1); 
    syMat = repmat(indyt',nUnknown,1);
    dMat  = sqrt((xMat-sxMat).^2 + (yMat-syMat).^2);
    wMat  = 1./dMat;
    mMat  = repmat(indmt',nUnknown,1);
    wmMat = wMat.*mMat;
    Gfill = reshape(sum(wmMat,2)./sum(wMat,2),size(G));
    Gfill(indt) = indmt;
end