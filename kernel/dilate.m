function Inew = dilate(I,n)
%function Inew = dilate(I,n)
%
% I: inpute binary image
% n: dilate the nonezero area 
%    by n rounds
%
% Nina Lin @ 2021 


neigb=[-1 0; 1 0; 0 -1;0 1;-1 -1; -1 1;1 1;1 -1];
for kk = 1:n
    cc       = bwconncomp((I~=0),8);
    numfun   = @(a) numel(a);
    numcomp  = cellfun(numfun,cc.PixelIdxList); 
    indpatch = find(numcomp>0);
    [nytile,nxtile] = size(I);
    Inew = I;
    for ii = 1:numel(indpatch)
    
        indp = cc.PixelIdxList{indpatch(ii)};
        vals = unique(I(indp));
        for jj = 1:numel(vals)
            indg = indp( find( I(indp) == vals(jj) ) );
            [iy,ix] = ind2sub(size(I),indg);
            xn = repmat(neigb(:,1),numel(ix),1) + reshape(repmat(ix',size(neigb,1),1),[],1);
            yn = repmat(neigb(:,2),numel(iy),1) + reshape(repmat(iy',size(neigb,1),1),[],1);
            ins = (xn>=1)&(yn>=1)&(xn<=nxtile)&(yn<=nytile);
            xn = xn(ins);
            yn = yn(ins);
            indn = sub2ind(size(I),yn,xn);
            idiff = setdiff(indn,indp);
            Inew(idiff) = vals(jj);
        end 
        
    end
    I = Inew;
end
