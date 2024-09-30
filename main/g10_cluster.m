function g10_cluster(fconfig,varargin)
%function g10_cluster(fconfig,[savefile])
% Cluster the detection results
%
% fconfig: user-specified configuration file
% savefile: save the plot to PNG file
%           1=yes(default), 0=no
%
% NinaLin@2023

loadparam;

if numel(varargin)>=1; savefile=varargin{1}; else; savefile=1; end

docluster = eval(config('docluster'));
dosmode   = eval(config('dosmode'));

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
methodlow  = config('methodlow');
methodhigh = config('methodhigh'); 
pcutlow  = eval(config('pcutlow'));
pcuthigh = eval(config('pcuthigh'));
bwp1low  = initBWarea(eventImg,config,'minpatchlow');
bwp1high = initBWarea(eventImg,config,'minpatchhigh');
lookRk   = initLook(eventImg,config,'lookRk');
pixelres = getPixelRes(eventImg,config,'pixelres');
areafact = pixelres^2; %m^2
cdist    = initDist(eventImg,config,'clusterdist'); %pixel
csize    = initBWarea(eventImg,config,'clusterarea');    %pixel
psize    = initBWarea(eventImg,config,'clusterlarge'); %pixel
bsize    = eval(config('bsize'));
olratio  = eval(config('olratio'));

if ~exist(fpmdir,'dir')
  mkdir(fpmdir);
end
if ~exist(qcdir,'dir')
  mkdir(qcdir);
end

info  = geotiffinfo(eventImg);
[X,Y] = geotiffinfo2xy(info);
[~,qcprefix] = fileparts(qcImg);
qctxt = sprintf('%s/10_cluster.log',qcdir);
farea  = sprintf('%s/10_clusterL_%s.txt',qcdir,methodstr);
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end
if docluster
    logging(qctxt,sprintf('Max distance between points in a cluster [m]:   %d',eval(config('clusterdist'))))
    logging(qctxt,sprintf('Max distance between points in a cluster [pxl]: %d',cdist))
    logging(qctxt,sprintf('Min area for a cluster [m^2]:                   %d',eval(config('clusterarea'))))
    logging(qctxt,sprintf('Min area for a cluster [pxl]:                   %d',csize))
    logging(qctxt,sprintf('Min area for a large cluster [m^2]:             %d',eval(config('clusterlarge'))))
    logging(qctxt,sprintf('Min area for a large cluster [pxl]:             %d',psize))
    logging(qctxt,sprintf('Looks taken for QC plot:                        %d',lookRk))
else
    logging(qctxt,'docluster=false in config file')
    logging(qctxt,'Merge amp- and amp+ changes only. No clustering processing.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
fclustX = sprintf('%s/%s_clstX_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
pclustX = sprintf('%s/%s_clstX_%s_prob.tif',fpmdir,prefix,methodstr);
FPMboth = geotiffread(fclustX);
pboth   = geotiffread(pclustX);
outpng   = sprintf('%s/10_clusterX_%s_bw%d_%d.png',qcdir,methodstr,bwp1low,bwp1high);

if ~docluster
    I = readRaster(sprintf('%s/%s.tif',fpmdir,prefix));

    figure('rend','painters','pos',[100 100 1200 400]); 
    gap = [.02 .05];
    marg_h = [.15 .08];
    marg_w = [.08 .05];

    tight_subplot(1,3,1,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(I,[-5 5]);
    colormap(gca,blue2red(32));
    cb1=colorbar('h');
    set(cb1,'Position',[0.15,0.05,0.1,0.015])    
    title('Z-score')

    tight_subplot(1,3,2,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(pboth/100,[0 1]);
    colormap(gca,'parula');
    cb2=colorbar('h');
    set(cb2,'Position',[0.465,0.05,0.1,0.015])   
    title('Probability')

    tight_subplot(1,3,3,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    switch ct
        case 0
            cb3 = [0 0 0;0 0 1;1 0 0];
        case 1
            cb3 = [0 0 0;0 0 1];
        case 3
            cb3 = [0 0 0;1 0 0];
    end
    imagesc(FPMboth,'AlphaData',(FPMboth~=0));
    colormap(gca,cb3)
    hold on;
    fh1=fill([0 0 0 0],[0 0 0 0],[1 1 1]);
    fh2=fill([0 0 0 0],[0 0 0 0],[0 0 1]);
    fh3=fill([0 0 0 0],[0 0 0 0],[1 0 0]);
    legend([fh1,fh2,fh3],'No Change','Change (Z-)','Change (Z+)')
    title('Non-clustered')

    if savefile
        print(gcf, outpng, '-dpng', '-r300');
    end
    return;
end


%%% Section for the actual clustering
fid  = fopen(farea, 'w');
fprintf(fid,'\n');
fprintf(fid,'tlow   thigh  clusterID  minArea(m^2) maxArea(m^2)\n');

if numel(find(FPMboth~=0))>5000
    logging(qctxt,'Start clustering for large files');
    logging(qctxt,sprintf('Split the image per %d x %d pixels (bsize)', bsize, bsize))
    logging(qctxt,sprintf('Split overlapping ratio (olratio): %0.2f',olratio));
    logging(qctxt,'You can specify bsize and olratio in config file')
    FPMpatchc = getCluster(FPMboth,cdist,csize,qctxt,bsize,olratio);
else
    logging(qctxt,'Start clustering calculation')
    FPMpatchc = getCluster(FPMboth,cdist,csize,qctxt);
end
FPMpatch = cell2mat(FPMpatchc);
FPMpatchlarge = zeros(size(FPMpatch));
cc       = bwconncomp((FPMpatch>0),8); 
numfun   = @(a) numel(a);
numcomp  = cellfun(numfun,cc.PixelIdxList);
indlarge = find(numcomp>psize);
if isKey(config,'tsize') %GSBA
    tsize    = eval(config('tsize'));
    logging(qctxt,'tsize  clusterID  minArea(m^2) maxArea(m^2)\n');
    logging(qctxt,'---------------------------------------------------\n');
    for ss = 1:numel(indlarge)
        indg = cc.PixelIdxList{indlarge(ss)};
        minsize = (sum(FPMlow(indg)>0)+sum(FPMhigh(indg)>0))*areafact;
        maxsize = numcomp(indlarge(ss))*areafact;
        fprintf(fid,sprintf('%-6d %-10d %-12.2f %-12.2f\n',tsize,ss,minsize,maxsize));
        logging(qctxt,sprintf('%-6d %-10d %-12.2f %-12.2f\n',tsize,ss,minsize,maxsize));
        FPMpatchlarge(indg) = ss;
    end
else %HSBA
    logging(qctxt,'clusterID  minArea(m^2) maxArea(m^2)\n');
    logging(qctxt,'---------------------------------------------------\n');
    for ss = 1:numel(indlarge)
        indg = cc.PixelIdxList{indlarge(ss)};
        minsize = (sum(FPMlow(indg)>0)+sum(FPMhigh(indg)>0))*areafact;
        maxsize = numcomp(indlarge(ss))*areafact;
        fprintf(fid,sprintf('%-10d %-12.2f %-12.2f\n',ss,minsize,maxsize));
        logging(qctxt,sprintf('%-10d %-12.2f %-12.2f\n',ss,minsize,maxsize));
        FPMpatchlarge(indg) = ss;
    end
end

outfile2 = sprintf('%s/%s_clst_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
outfile3 = sprintf('%s/%s_clstL_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
outpng   = sprintf('%s/10_cluster_%s_bw%d_%d.png',qcdir,methodstr,bwp1low,bwp1high);
mat2geotiff(FPMpatch,X,Y,outfile2,'geotiff',ctype,8,[],info);
mat2geotiff(FPMpatchlarge,X,Y,outfile3,'geotiff',ctype,8,[],info);
logging(qctxt,sprintf('Output clustered file %s\n',outfile2));
logging(qctxt,sprintf('Output clustered-large file %s\n',outfile3));
fprintf(fid2,'%s\n',outfile2);
fprintf(fid2,'%s\n',outfile3);

FPMbothLK  = FPMboth;
FPMpatchLK = FPMpatch;
FPMpatchlargeLK = FPMpatchlarge;

figure('rend','painters','pos',[100 100 1000 1100]); 
gap = [.02 .05];
marg_h = [.08 .08];
marg_w = [.08 .05];

tight_subplot(2,2,1,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(pboth/100,[0 1]);
colormap(gca,'jet')
title('Probability')

tight_subplot(2,2,2,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(FPMbothLK,'AlphaData',(FPMbothLK~=0));
colormap(gca,'jet')
title('Non-clustered')

tight_subplot(2,2,3,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(FPMpatchLK,'AlphaData',(FPMpatchLK~=0));
colormap(gca,'jet')
title('Clustered')
set(gca,'YTickLabel',[])

tight_subplot(2,2,4,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(FPMpatchlargeLK,'AlphaData',(FPMpatchlargeLK~=0));
colormap(gca,'jet')
title('Clustered-large')
set(gca,'YTickLabel',[])

if savefile
    print(gcf, outpng, '-dpng', '-r300');
end

fclose(fid);
fclose(fid2);
ttt = toc;

 
return;

