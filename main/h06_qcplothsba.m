function h06_qcplot(fconfig,varargin);
%function h06_qcplot(fconfig,[savefile]);
% Compute QC metrics and generate QC plots
% merge Z- with Z+ results
%
%  fconfig: user-specified configuration file
% savefile: save the plot to PNG file
%           1=yes(default), 0=no
%
% NinaLin@2023

if numel(varargin)>=1; savefile=varargin{1}; else; savefile=1; end

loadparam;
methodlo = config('methodlow');
methodhi = config('methodhigh');
eventImg = sprintf('%s/%s.tif',fpmdir,prefix);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Get validation tile index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('rend','painters','pos',[100 100 800 650]); 
gap = [.08 .02];
marg_h = [.08 .06];
marg_w = [.05 .02];

cmap = parula(32);
cmap(end,:) = [1 1 1];
cmap2 = blueyellowred(32);

% plot FPMlow results
ii=1;
G1data = load(sprintf('%s/%s_hsba_G1',qcdir,prefix));
G1fpm = load(sprintf('%s/%s_intp_lo_%s.mat',qcdir,prefix,methodstr));

cnt = (ii-1)*3+1;
p(cnt)=tight_subplot(2,3,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(G1data.G1M,[-5 0]);
colormap(gca,cmap);
set(gca,'XTick',[],'YTick',[])
ylabel('Intensity Decrease');
title('(a) HSBA Stats','FontSize',7);
cb = colorbar('h');
set(cb,'Position',[0.10,0.52,0.15,0.015])
title(cb,{'Mean of the','1st Gaussian'},'Position',[105 -13 0]);

cnt = (ii-1)*3+2;
p(cnt)=tight_subplot(2,3,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(G1fpm.pFlowLK,[0 1])
colormap(gca,cmap2);
set(gca,'XTick',[],'YTick',[])
title('(b) Bayesian Prob','FontSize',7); 
cb2 = colorbar('h');
set(cb2,'Position',[0.45,0.52,0.1,0.015])
title(cb2,'Probability','Position',[75 -1.3 0]);

cnt = (ii-1)*3+3;
p(cnt)=tight_subplot(2,3,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc((G1fpm.FPMlowLK==0)); 
colormap(gca,'bone');
set(gca,'XTick',[],'YTick',[])
title({'(c) Down-Looked','Change Map'},'FontSize',7);

% plot FPMhigh results
ii=2;
G3data = load(sprintf('%s/%s_hsba_G3',qcdir,prefix));
G3fpm = load(sprintf('%s/%s_intp_hi_%s.mat',qcdir,prefix,methodstr));
cmap = jet(32);
cmap(1,:) = [1 1 1];
ylims = [0 4];
cmap2 = blueyellowred(32);

cnt = (ii-1)*3+1;
p(cnt)=tight_subplot(2,3,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(G3data.G3M,ylims);
colormap(gca,cmap);
set(gca,'XTick',[],'YTick',[])
ylabel('Intensity Increase');
cb = colorbar('h');
set(cb,'Position',[0.10,0.05,0.15,0.015])
title(cb,{'Mean of the','3st Gaussian'},'Position',[105 -12 0]);

cnt = (ii-1)*3+2;
p(cnt)=tight_subplot(2,3,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc(G3fpm.pFhighLK,[0 1])
colormap(gca,cmap2);
set(gca,'XTick',[],'YTick',[])
cb2 = colorbar('h');
set(cb2,'Position',[0.45,0.05,0.1,0.015])
title(cb2,'Probability','Position',[75 -1.6 0]);

cnt = (ii-1)*3+3;
p(cnt)=tight_subplot(2,3,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
imagesc((G3fpm.FPMhighLK==0)); 
colormap(gca,'bone');
set(gca,'XTick',[],'YTick',[])

%align_Ylabels(gcf,-8)

if savefile; print(gcf, sprintf('%s/06_qcplothsba.png',qcdir), '-dpng', '-r300'); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% write the current final file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
info  = geotiffinfo(eventImg);
[X,Y] = geotiffinfo2xy(info);
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end
bwp1low  = initBWarea(eventImg,config,'minpatchlow');
bwp1high = initBWarea(eventImg,config,'minpatchhigh');
pcutlow  = eval(config('pcutlow'));
pcuthigh = eval(config('pcuthigh'));
FPMlow  = geotiffread(sprintf('%s/%s_intp_lo_%s_p%02d_bw%d.tif',fpmdir,prefix,methodstr,pcutlow*100,bwp1low));
FPMhigh = geotiffread(sprintf('%s/%s_intp_hi_%s_p%02d_bw%d.tif',fpmdir,prefix,methodstr2,pcuthigh*100,bwp1high));
if ct==1
    FPMboth = FPMlow*2;
elseif ct==3
    FPMboth = FPMhigh*1; 
elseif ct==0 
    FPMboth = FPMhigh*2 + FPMlow*1; % 1=low, 2=high
end
fplow = sprintf('%s/%s_intp_lo_%s_prob.tif',fpmdir,prefix,methodstr);
fphigh = sprintf('%s/%s_intp_hi_%s_prob.tif',fpmdir,prefix,methodstr2);
outfile1 = sprintf('%s/%s_clstX_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
outfilep = sprintf('%s/%s_clstX_%s_prob.tif',fpmdir,prefix,methodstr);
plow  = geotiffread(fplow);
phigh = geotiffread(fphigh);
if ct==1
    pboth = getPboth(plow,phigh*0,FPMboth);
elseif ct==3
    pboth = getPboth(plow*0,phigh,FPMboth);
elseif ct==0
    pboth = getPboth(plow,phigh,FPMboth);
end
mat2geotiff(FPMboth,X,Y,outfile1,'geotiff',ctype,8,[],info);
mat2geotiff(pboth,X,Y,outfilep,'geotiff',ctype,8,[],info);
logging(0,sprintf('Output probability file %s\n',outfilep));
logging(0,sprintf('Output nonclustered file %s\n',outfile1));
ffinal = sprintf('%s/finalfile_%s_bw%d_%d.txt',qcdir,methodstr,bwp1low,bwp1high);
fid2 = fopen(ffinal, 'w');
fprintf(fid2,'%s\n',fplow);
fprintf(fid2,'%s\n',fphigh);
