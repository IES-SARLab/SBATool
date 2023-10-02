function g08_qcplothigh(fconfig,varargin);
%function g08_qcplothigh(fconfig,[savefile]);
% Generate QC plots for Z+ changes
%
%  fconfig: user-specified configuration file
% savefile: save the plot to PNG file
%           1=yes(default), 0=no
%
% NinaLin@2023

loadparam;
methodstr=methodstr2;

if numel(varargin)>=1; savefile=varargin{1}; else; savefile=1; end

tlisthigh = eval(config('tsize'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Get validation tile index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('rend','painters','pos',[100 100 1000 270]); 
gap = [.02 .02];
marg_h = [.15 .12];
marg_w = [.05 .03];

cmap = jet(32);
cmap(1,:) = [1 1 1];
ylims = [0 4];
cmap2 = blueyellowred(32);

for ii = 1:numel(tlisthigh)

    tsize = tlisthigh(ii);
    G3data = load(sprintf('%s/%s_intp_hi%d_%s.mat',qcdir,prefix,tsize,methodstr));

    cnt = (ii-1)*5+1;
    p(cnt)=tight_subplot(1,5,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(G3data.G3Mt0,ylims);
    colormap(gca,cmap);
    set(gca,'XTick',[],'YTick',[])
    if ii==1; ylabel(sprintf('tsize=%d',tsize)); end
    if ii==2; ylabel(sprintf('tsize=%d',tsize)); end
    if ii==3; ylabel(sprintf('tsize=%d',tsize)); end
    if ii==1; title('(a) Initial Stats','FontSize',7); end
    if ii==1
        cb = colorbar('h');
        %set(cb,'Position',[0.22,0.035,0.4,0.015])
        %title(cb,'Mean of the 3rd Gaussian','Position',[295 -2 0]);
        set(cb,'Position',[0.25,0.08,0.15,0.015])
        title(cb,{'Mean of the','3rd Gaussian'},'Position',[140 -10 0]);
    end
    

    cnt = (ii-1)*5+2;
    p(cnt)=tight_subplot(1,5,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(G3data.G3Mt,ylims);
    colormap(gca,cmap);
    set(gca,'XTick',[],'YTick',[])
    if ii==1; title('(b) After Selection','FontSize',7); end
         
    cnt = (ii-1)*5+3;
    p(cnt)=tight_subplot(1,5,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(G3data.G3Mtr2,ylims);
    colormap(gca,cmap);
    set(gca,'XTick',[],'YTick',[])
    if ii==1; title('(c) After Tilegrowing','FontSize',7); end

    cnt = (ii-1)*5+4;
    p(cnt)=tight_subplot(1,5,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    %imagesc(G3data.G3Mtr3,ylims)
    imagesc(G3data.pFhighLK,[0 1])
    colormap(gca,cmap2);
    set(gca,'XTick',[],'YTick',[])
    if ii==1; 
        title('(d) Bayesian Prob','FontSize',7); 
        cb2 = colorbar('h');
        set(cb2,'Position',[0.62,0.08,0.1,0.015])
        title(cb2,'Probability','Position',[95 -2 0]);
    end

    cnt = (ii-1)*5+5;
    p(cnt)=tight_subplot(1,5,cnt,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc((G3data.FPMhighLK==0)); 
    colormap(gca,'bone');
    set(gca,'XTick',[],'YTick',[])
    if ii==1; title({'(e) Down-Looked','Change Map'},'FontSize',7); end

    %align_Ylabels(gcf,-8)
end

if savefile; print(gcf, sprintf('%s/09_qcplothigh.png',qcdir), '-dpng', '-r300'); end
