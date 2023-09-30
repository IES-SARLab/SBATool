function g12_xv(file1,file2,varargin)
% function g12_xv(file1,file2,config)
% or
% function g12_xv(file1,file2,clusterdist,clusterarea)
% or
% function g12_xv(file1,file2,clusterdist,clusterarea,printarea)
%
% Cross-validate change areas using file1 and file2
% usually from two different flight directions but with the same file size
%
% file1 : file 1 for cross-validation (e.g. asc track)
% file2 : file 2 for cross-validation (e.g. dsc track) 
% clusterdist : [m]   Maximum distance between points for the clustering
% clusterarea : [m^2] Minimum area per cluster 
% printarea   : [m^2] Minimum area to print out (default: clusterarea*10)
%
% output files in the following two names:
%
% file1.xv.tif (or any file extension) - raw xv result
% file1.xv.cluster.tif                 - xv and further clustering
%
% NinaLin@2023

if ~exist(file1,'file'); error(sprintf('Cannot find file %s!',file1)); end
if ~exist(file2,'file'); error(sprintf('Cannot find file %s!',file2)); end

if numel(varargin)==0
    error('Need to supply config or [clusterdist, clusterarea] for the conversion!')
elseif numel(varargin)==1
    fconfig = varargin{1};
    loadparam;
    cdist  = initDist(file1,config,'clusterdist');     %pixel
    csize  = initBWarea(file1,config,'clusterarea');   %pixel
    psize  = initBWarea(file2,config,'clusterlarge');  %pixel
    bsize  = eval(config('bsize'));
elseif numel(varargin)==2
    cdist  = initDist(file1,varargin{1});
    csize  = initBWarea(file1,varargin{2});
    psize  = initBWarea(file1,varargin{2}*10);
    bsize    = 500;
elseif numel(varargin)==3
    cdist  = initDist(file1,varargin{1});
    csize  = initBWarea(file1,varargin{2});
    psize  = initBWarea(file1,varargin{3});
    bsize    = 500;
end

lookRk   = initLook(file1);
[patch1,X1,Y1,info1] = readRaster(file1);
[patch2,X2,Y2,info2] = readRaster(file2);

if numel(patch1) ~= numel(patch2)
    error(sprintf('File %s and %s have different dimensions!',file1,file2));
end

pixelres = getPixelRes(file1);
areafact = (pixelres^2)*1e-6; %km^2
if mean(diff(X1))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end

qctxt = '12_xv.txt';
qclog = '12_xv.log';
fid = fopen(qctxt, 'w');
fprintf(fid,'clusterID  minArea(km)  maxArea(km)\n');
[path1,fname1,ext1] = fileparts(file1);
[path2,fname2,ext2] = fileparts(file2);
fout1 = sprintf('%s/%s-%s.xv.tif',path1,fname1,fname2);
fout2 = sprintf('%s/%s-%s.xv.clst.tif',path1,fname1,fname2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

patchjnt = zeros(size(patch1));
cnt = 0;

% loop through patch1
val1 = unique(patch1(patch1>0)); %ignore channels
for kk = 1:numel(val1)
    cnt = cnt+1;
    ind1 = find(patch1==val1(kk));
    if sum(patch2(ind1))~=0 
        patchjnt(ind1) = cnt;
        val2 = setdiff(unique(patch2(ind1)),0);
        for ll=1:numel(val2)
            ind2 = find(patch2==val2(ll));
            patchjnt(ind2) = cnt;
        end
    end
end

% clustering the merged file
patchfinal = patchjnt*0;
if numel(find(patchjnt~=0))>5000
    logging(qclog,'Start clustering for large files');
    logging(qclog,sprintf('Split the image per %d x %d pixels (default)', bsize, bsize))
    logging(qclog,'You can change this default by setting bsize in config file')
    patchc = getCluster(patchjnt,cdist,csize,qclog,bsize);
else
    logging(qctxt,'Start clustering calculation')
    patchc = getCluster(patchjnt,cdist,csize,qclog);
end
patchtmp = cell2mat(patchc);
cc       = bwconncomp((patchtmp>0),8); 
numfun   = @(a) numel(a);
numcomp  = cellfun(numfun,cc.PixelIdxList);
indlarge = find(numcomp>psize);
for ss = 1:numel(indlarge)
    indg = cc.PixelIdxList{indlarge(ss)};
    minsize = (sum(patch1(indg)>0)+sum(patch2(indg)>0))*areafact;
    maxsize = numcomp(ss)*areafact;
    fprintf(fid,sprintf('%-10d %-12.3f %-12.3f\n',ss,minsize,maxsize));
    patchfinal(indg) = ss;
end

mat2geotiff(patchjnt,X1,Y1,fout1,'geotiff',ctype,8,[],info1);
logging(qclog,sprintf('Output raw xv file %s\n',fout1));
mat2geotiff(patchfinal,X1,Y1,fout2,'geotiff',ctype,8,[],info1);
logging(qclog,sprintf('Output clustered xv file %s\n',fout2));
    
patch1LK  = patch1;
patch2LK  = patch2;
patchjntLK    = patchjnt;
patchfinalLK  = patchfinal;

figure('rend','painters','pos',[100 100 800 800]); 
gap = [.08 .05];
marg_h = [.05 .08];
marg_w = [.08 .05];

tight_subplot(2,2,1,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(patch1LK,'AlphaData',(patch1LK~=0));
colormap(gca,'jet');
title('file 1')
set(gca,'XTickLabel',[])

tight_subplot(2,2,2,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(patch2LK,'AlphaData',(patch2LK~=0));
colormap(gca,'jet');
title('file 2')
set(gca,'XTickLabel',[],'YTickLabel',[])

tight_subplot(2,2,3,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(patchjntLK,'AlphaData',(patchjntLK~=0));
colormap(gca,'jet');
title('XV, Non-clustered')

tight_subplot(2,2,4,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(patchfinalLK,'AlphaData',(patchfinalLK~=0));
colormap(gca,'jet');
title('XV, Clustered')
set(gca,'YTickLabel',[])

print(gcf, sprintf('%s/12_xv_%s-%s.png',qcdir,fname1,fname2), '-dpng', '-r300');



