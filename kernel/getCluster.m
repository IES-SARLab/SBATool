function FPMpatchc = getCluster(FPMboth,cdist,csize,qcfile,varargin)
%function clusters = getCluster(Img,cdist,csize,qcfile,[bsize])
% get clustering point sets for the input Img (non-zero parts)
% 
% input:
% Img  : non-zero values for existance of events
% cdist: [pixels] Maximum distance between points for the clustering
% csize: [pixels] Minimum number of points per cluster 
% qcfile: qcfile name
% bsize: specifiy to process the Img into different splits
%        if not specified, the Img will be processing as a whole
%
% output:
% clusters: cell with each cell unit representing
%           different splits of the Img
%           if bsize not specified, clusters has only 1 cell unit
%           Different integer values for different clusters

if numel(varargin)>0; bsize=varargin{1}; end
if numel(varargin)>1; olratio=varargin{2}; else; olratio=0; end

csizelist = [0    50 100 250 500 1000 1000000];  % cluster size
sfactlist = [.01 .01 .02 .1  .2  .5   .5]; %shrink factor; larger shrink factor
                                           %means the final patch will be tightly
                                           %close to the edge of the clusters 
[ny,nx] = size(FPMboth);
if exist('bsize','var')
    if nx > bsize*2; splitx = round(nx/bsize); else; splitx=1; end;
    if ny > bsize*2; splity = round(ny/bsize); else; splity=1; end;
else
    splitx = 1;
    splity = 1;
end   
[splitStartX,splitEndX,splitStartY,splitEndY,~,~,~,~,sxm0,sxm1,sym0,sym1] = splitImg(size(FPMboth),[splitx splity],'gridline',olratio);
allcnt = splity*splitx;
for cnt=1:allcnt
    [mm,nn]=ind2sub([splity,splitx],cnt);
    tmpImg{cnt}=FPMboth(splitStartY(mm):splitEndY(mm),splitStartX(nn):splitEndX(nn));
end


FPMpatchtmp={};
%for mm = 1:splity
%    for nn = 1:splitx
for cnt=1:allcnt
        [mm,nn]=ind2sub([splity,splitx],cnt);        
        logging(qcfile,sprintf('Start processing part %d out of %d',cnt,allcnt))
        subImg   = tmpImg{cnt};
        tmpPatch = subImg*0;
        [xx,yy]  = meshgrid(1:size(subImg,2),1:size(subImg,1));
        indFPM   = find( subImg>0 );
        XY       = [xx(indFPM) yy(indFPM)];
        [~,~,cxy] = clusterXYpoints(XY,cdist,csize,'point','merge',0,qcfile);
        for kk = 1:size(cxy,1)
            pts = cxy{kk};
            cpx = pts(:,1);
            cpy = pts(:,2);
            sfact = interp1(csizelist,sfactlist,numel(cpx));
            if numel(unique(cpx))>1 && numel(unique(cpy))>1
                indbound  = boundary(cpx,cpy,sfact);
                xv = cpx(indbound);
                yv = cpy(indbound);
                indinpoly = inpolygon(xx,yy,xv,yv);
                if numel(find(subImg(indinpoly)>0))>0
                    tmpPatch(indinpoly) = kk;
                end
            else %along only 1 row or 1 col
                indinpoly = sub2ind(size(xx),cpy,cpx);
                tmpPatch(indinpoly) = kk;
            end     
        end
        FPMpatchtmp{cnt} = tmpPatch([sym0(mm):sym1(mm)]-splitStartY(mm)+1,[sxm0(nn):sxm1(nn)]-splitStartX(nn)+1);
end

for cnt=1:allcnt
    [mm,nn]=ind2sub([splity,splitx],cnt);
    FPMpatchc{mm,nn}=FPMpatchtmp{cnt};
end

