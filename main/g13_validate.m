function g13_validate(fconfig,varargin)
%function g13_validate(fconfig,[runROC, inputfile])
% Validate change detection results using an independent val file
%
%   fconfig: user-specified configuration file
%    runROC: compute Receiver Operating Characteristic (ROC) curve
%            0=no, 1=yes (default) 
% inputfile: user-selected input change detection file to
%            execute validation 
%
% If 'inputfile' is not specified, the script will locate the
%    files listed in ./qc/finalfile.txt to execute validation
%
% NinaLin@2023

loadparam;
if numel(varargin)>0;
    runROC = varargin{1};
else
    runROC = 1;
end
if numel(varargin)>1; 
    inlist={varargin{2}}; 
else
    inlist=readFinal(config);
end

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
bwp1low  = initBWarea(eventImg,config,'minpatchlow');
bwp1high = initBWarea(eventImg,config,'minpatchhigh');
Rklow  = config('Rkfinallow');  
Rkhigh = config('Rkfinalhigh');  
valtifout = eval(config('valtifout'));

% ROC related %
cutlist = [0:0.02:0.1 0.2:0.1:1.0];
ind50   = find(abs(cutlist-0.5)==min(abs(cutlist-0.5)));
fprv    = [0:0.05:1];
% ROC related %


logfile  = sprintf('%s/13_val.log',valdir);
valfile  = dir(sprintf('%s_val.*',prefix));
if numel(valfile) == 0
    error('Validation file %s does not exist!');
end
if numel(valfile) > 1
    error('Multiple validation files detected! Please leave only one in the working folder.')
end

mskfile = dir(sprintf('%s_mask.*',prefix));
if numel(mskfile) == 0
    logging(logfile, sprintf('Mask file %s does not exist!',mskfile));
    logging(logfile, 'Continue without masking');
end
if numel(mskfile) > 1
    error('Multiple mask files detected! Please leave only one in the working folder.')
end

liafile  = dir(sprintf('%s_lia.*',prefix));
if numel(liafile) == 0
    logging(logfile, sprintf('LIA file %s does not exist',liafile));
    logging(logfile, 'Continue without LIA mask');
end
if numel(liafile) > 1
    error(1,'Multiple LIA files detected! Please leave only one in the working folder.')
end

for kk=1:numel(inlist)  %loop through all files in ./qc/finalfile_*.txt

    infile = inlist{kk}; 
    [fpath,fname,fext]=fileparts(infile);
    txtfile = sprintf('%s/val_%s.txt',valdir,fname); 
    pltfile = sprintf('%s/val_%s.png',valdir,fname); 
    
    logging(logfile,sprintf('Input file:      %s',infile));
    logging(logfile,sprintf('Mask  file:      %s',mskfile.name));
    logging(logfile,sprintf('Validation file: %s',valfile.name));
    fpm = double(readRaster(infile));
    [val,X,Y] = readRaster(valfile.name,'isce');
    val = double(val);
    msk = readRaster(mskfile.name);
    val(msk~=0) = nan;
    fpm(msk~=0) = nan;
 
    if numel(liafile) == 1
        liathresh = eval(config('liathresh'));
        logging(logfile, sprintf('LIA file:       %s',liafile.name));
        logging(logfile, sprintf('LIA threshold:  %d',liathresh));
        lia = readRaster(liafile.name);
    else
        lia = zeros(size(fpm));
        liathresh = 999;
    end
    
    logging(logfile,sprintf('Statistics interpolation method for amp- changes: %s',config('methodlow')));
    logging(logfile,sprintf('Statistics interpolation method for amp+ changes: %s',config('methodhigh')));
    logging(logfile,sprintf('Quantile for amp- changes (for quantile or const_q method): %0.2f',eval(config('methodlowq'))));
    logging(logfile,sprintf('Quantile for amp+ changes (for quantile or const_q method): %0.2f',eval(config('methodhighq'))));
    logging(logfile,sprintf('Cut-off prob for amp- changes: %0.2f',eval(config('pcutlow'))));
    logging(logfile,sprintf('Cut-off prob for amp+ changes: %0.2f',eval(config('pcuthigh'))));
    logging(logfile,sprintf('Min area for amp- changes: %d pixels',bwp1low));
    logging(logfile,sprintf('Min area for amp+ changes: %d pixels',bwp1high));
    logging(logfile,sprintf('Rk level for amp- changes: %s',Rklow));
    logging(logfile,sprintf('Rk level for amp+ changes: %s\n',Rkhigh));
    logging(logfile,sprintf('AREA  CSI    ACC    Kappa  F-score TPR   FPR'));
    logging(logfile,'---------------------------------------------');
    
    fid=fopen(txtfile,'w');
    fprintf(fid,'Interpolation for amp- changes: %s\n',config('methodlow'));
    fprintf(fid,'Interpolation for amp+ changes: %s\n',config('methodhigh'));
    fprintf(fid,'Quantile for amp- changes (for quantile or const_q method): %0.2f\n',eval(config('methodlowq')));
    fprintf(fid,'Quantile for amp+ changes (for quantile or const_q method): %0.2f\n',eval(config('methodhighq')));
    fprintf(fid,'Cut-off prob for amp+ changes: %0.2f\n',eval(config('pcutlow')));
    fprintf(fid,'Cut-off prob for amp+ changes: %0.2f\n',eval(config('pcuthigh')));
    fprintf(fid,'Min area for amp- changes: %d pixels\n',bwp1low);
    fprintf(fid,'Min area for amp+ changes: %d pixels\n',bwp1high);
    fprintf(fid,'Rk level for amp- changes: %s \n',Rklow);
    fprintf(fid,'Rk level for amp+ changes: %s \n\n',Rkhigh);
    fprintf(fid,'AREA  CSI    ACC    Kappa  F-score TPR   FPR\n');
    
    % for full area
    [valout,valInUse] = runValidate(fpm, val, txtfile, logfile, lia, liathresh, 'full');
    plotVal(fpm,valInUse,valout,pltfile,'full')
   
    if valtifout
        valtifname = sprintf('%s/%s_val_full.tif',valdir,prefix);
        valout(isnan(valout)) = 0;
        mat2geotiff(valout,X,Y,valtifname,'isce')
    end

    if runROC
        [CSI,ACC,Fscore,Kappa,TPR,FPR,AUC,UMR]=calcROC(fconfig,logfile,cutlist,bwp1low,bwp1high,val,msk,lia,liathresh);
    end
 
    % for each aoi
    if isKey(config, 'valaoi')
        aoill   = eval(config('valaoi'));
        if isKey(config,'valaoiID');
            aoiID = eval(config('valaoiID'));
        else
            aoiID = 1:size(aoill,1);
        end
        aoiUID = unique(aoiID);
        for ia =1:numel(aoiUID)
            aoilabel = sprintf('AOI%d',aoiUID(ia));
            id = find(aoiID==aoiUID(ia));
            aoiUL = ll2pxl(X,Y,aoill(id,1),aoill(id,2));
            aoiLR = ll2pxl(X,Y,aoill(id,3),aoill(id,4));
            Xsub = X(aoiUL(1):aoiLR(1));
            Ysub = fliplr(Y);
            Ysub = Ysub(aoiUL(2):aoiLR(2));
            if numel(id)==1
                fpmtmp = fpm(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
                valtmp = val(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
                liatmp = lia(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
            else
                fpmtmp = fpm*0+nan;
                valtmp = val*0+nan;
                liatmp = lia*0+nan;
                for ii=1:numel(id)
                    fpmtmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                                fpm(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
                    valtmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                                val(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
                    liatmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                                lia(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
                end
                fpmtmp = fpmtmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
                valtmp = valtmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
                liatmp = liatmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
            end
            [valouttmp,valInUsetmp] = runValidate(fpmtmp, valtmp, txtfile, logfile, liatmp, liathresh, aoilabel);
            plotVal(fpmtmp,valInUsetmp,valouttmp,pltfile,aoilabel)
            if valtifout
                valtifname = sprintf('%s/%s_val_aoi%d.tif',valdir,prefix,ia);
                valouttmp(isnan(valouttmp)) = 0;
                mat2geotiff(valouttmp,Xsub,Ysub,valtifname,'isce')
            end
            if runROC
                [CSItmp,ACCtmp,Fscoretmp,Kappatmp,TPRtmp,FPRtmp,AUCtmp,UMRtmp]=calcROC(fconfig,logfile,cutlist,bwp1low,bwp1high,val,msk,lia,liathresh,aoiUL,aoiLR,id);
                CSI = [CSI; CSItmp];
                ACC = [ACC; ACCtmp];
                Fscore = [Fscore; Fscoretmp];
                Kappa  = [Kappa;  Kappatmp];
                TPR = [TPR; TPRtmp];
                FPR = [FPR; FPRtmp];
                AUC = [AUC; AUCtmp];
                UMR = [UMR; UMRtmp];
            end
        end
    end

    if runROC
        outmat = sprintf('%s/roc_%s.mat',valdir,fname);
        outpng = sprintf('%s/roc_%s.png',valdir,fname);
        save(outmat, 'CSI', 'ACC', 'Fscore', 'Kappa', 'TPR', 'FPR', 'AUC', 'UMR','cutlist'); 
        plotROC(FPR,TPR,AUC,aoiUID,ind50,outpng)
    end

    logging(logfile,'\n');

end

end

function plotVal(fpmLK,valLK,valoutLK,pltfile,aoilabel)

                   
    cm = [1 0  0; %TP 1   red 
          1 .5 0; %FP 2   orange
          0 1 1; %TN -1   cyan
          0 0  1]; %FN -2 blue
                    

    figure('rend','painters','pos',[100 100 1000 300]); 
    gap = [.02 .05];
    marg_h = [.08 .08];
    marg_w = [.08 .05];
    
    tight_subplot(1,3,1,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(fpmLK,'AlphaData',((fpmLK~=0)&(isfinite(fpmLK))));
    colormap(gca,[0 0 0;0 0 1;1 0 0]);
    title('GSBA Result')
    
    tight_subplot(1,3,2,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(valLK,'AlphaData',((valLK~=0)&(isfinite(valLK))));
    colormap(gca,[0 0 0;cm(1,:)]);
    title('Validation In')
    set(gca,'YTickLabel',[])
    
    tight_subplot(1,3,3,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    valoutLK(valoutLK<0) = valoutLK(valoutLK<0)*-1+2;
    valoutLK(isnan(valoutLK))=0;
    valoutLK(1,1)=0;
    imagesc(valoutLK,'AlphaData',(isfinite(fpmLK)&isfinite(valLK)));
    colormap(gca,[0 0 0;cm]);
    title('Validation Out')
    set(gca,'YTickLabel',[])
   
    [fpath,fname,fext] = fileparts(pltfile);
    pltfileAOI = sprintf('%s/%s_%s%s',fpath,fname,aoilabel,fext);
 
    print(gcf, pltfileAOI, '-dpng', '-r300');
end


function [valout,varargout] = runValidate(fpm, val, txtfile, logfile, lia, liathresh, aoilabel)

if numel(val) ~= numel(fpm)
    error('Input and validation file have different dimensions!')
end
if numel(lia) ~= numel(fpm)
    error('Input and LIA file have different dimensions!')
end

val(lia>liathresh)=0;
varargout{1} = val;
fpmboth=fpm*0;
fpmboth(fpm>0)=1;
fpmboth(fpm<0)=-1;
fpmboth(isnan(fpm))=nan;
[CSI,ACC,Fscore,Kappa,TPR,FPR,valout] = getValMetrics(fpmboth,val);

logging(logfile,sprintf('%-5s %-5.3f  %-5.3f  %-5.3f    %-5.3f %-5.3f %-5.3f',aoilabel,CSI,ACC,Kappa,Fscore,TPR,FPR));

fid=fopen(txtfile,'a');
fprintf(fid,sprintf('%-5s %-5.3f  %-5.3f  %-5.3f  %-5.3f   %-5.3f %-5.3f\n',aoilabel,CSI,ACC,Kappa,Fscore,TPR,FPR));
fclose(fid);

end

function [CSI,ACC,Fscore,Kappa,TPR,FPR,AUC,UMR]=calcROC(fconfig,logfile,cutlist,bwp1low,bwp1high,val,msk,lia,liathresh,varargin)

if numel(varargin)>0; 
    useAOI=1; 
    aoiUL=varargin{1};
    aoiLR=varargin{2};    
    id=varargin{3};
else; 
    useAOI=0; 
end
 
loadparam;
pcut    = eval(config('pcutlow'));
connlow = eval(config('connlow'));
connhigh= eval(config('connhigh'));

if isKey(config,'tsize') %GSBA
    tsize   = eval(config('tsize'));
    plow   = geotiffread(sprintf('%s/%s_intp_lo%d_%s_prob.tif',fpmdir,prefix,tsize,methodstr)); 
    phigh  = geotiffread(sprintf('%s/%s_intp_hi%d_%s_prob.tif',fpmdir,prefix,tsize,methodstr2));
else %HSBA
    plow   = geotiffread(sprintf('%s/%s_intp_lo_%s_prob.tif',fpmdir,prefix,methodstr)); 
    phigh  = geotiffread(sprintf('%s/%s_intp_hi_%s_prob.tif',fpmdir,prefix,methodstr2));
end
val(lia>liathresh)=0;
if useAOI
    if numel(id)==1
        plow  = plow(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
        phigh = phigh(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
        val   = val(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
        msk   = msk(aoiUL(2):aoiLR(2), aoiUL(1):aoiLR(1));
    else
        plowtmp  = plow*0+nan;
        phightmp = phigh*0+nan;
        valtmp = val*0+nan;
        msktmp = msk*0+nan;
        for ii=1:numel(id)
            plowtmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                        plow(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
            phightmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                        phigh(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
            valtmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                        val(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
            msktmp(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1)) = ...
                        msk(aoiUL(ii,2):aoiLR(ii,2), aoiUL(ii,1):aoiLR(ii,1));
        end
        plow  = plowtmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
        phigh = phightmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
        val = valtmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
        msk = msktmp(min(aoiUL(:,2)):max(aoiLR(:,2)), min(aoiUL(:,1)):max(aoiLR(:,1)));
    end
end

plow = plow*0.01;
phigh = phigh*0.01;       
if ct==1; phihg= phigh*0; end
if ct==3; plow = plow*0;  end

CSI = zeros(1,numel(cutlist));
ACC = zeros(1,numel(cutlist));
FSC = zeros(1,numel(cutlist));
KAP = zeros(1,numel(cutlist));
TPR = zeros(1,numel(cutlist));  
FPR = zeros(1,numel(cutlist));
for ic=1:numel(cutlist)
    logging(logfile,sprintf('Validating cut-off Prob %0.2f',cutlist(ic)));
    FPMlow  = (plow>=cutlist(ic));
    FPMhigh = (phigh>=cutlist(ic));
    FPMlow  = bwareaopen(FPMlow,bwp1low,connlow);
    FPMlow  = bwareaopen(FPMlow==0,bwp1low,connlow);
    FPMlow  = (FPMlow~=1);
    FPMhigh = bwareaopen(FPMhigh,bwp1high,connhigh);
    FPMhigh = bwareaopen(FPMhigh==0,bwp1high,connhigh);
    FPMhigh = (FPMhigh~=1);
    FPMboth = FPMhigh + FPMlow; % 1=low, 2=high
    FPMboth(msk~=0) = nan;
    [CSI(ic),ACC(ic),Fscore(ic),Kappa(ic),TPR(ic),FPR(ic)] = getValMetrics(FPMboth,val);
end
FPR(1)=1;
TPR(1)=1;
FPR = [FPR 0];
TPR = [TPR 0];
[~,ind]=unique(FPR);
fprv = [0:0.05:1];
tprv = interp1(FPR(ind),TPR(ind),fprv);
AUC  = nansum((tprv(1:end-1)+tprv(2:end))*.05/2);
UMR = sum(msk==0,'all')/numel(msk); %unmasked ratio

end


function plotROC(FPR,TPR,AUC,aoiUID,ind50,outpng)

figure('rend','painters','pos',[100 100 400 340]); 
pcolor = jet(numel(aoiUID));

ph(1)=plot([FPR(1,:) 0],[TPR(1,:) 0],'k-','LineWidth',2); 
pl{1}=sprintf('Full, %0.2f',AUC(1));

hold on; box on; grid on;
for ll=1:numel(aoiUID)
    ph(ll+1)=plot([FPR(ll+1,:) 0],[TPR(ll+1,:) 0],'-','Color',pcolor(ll,:),'LineWidth',2);
    pl{ll+1}=sprintf('AOI%d, %0.2f',ll,AUC(ll+1));
end
ph(end+1)=plot(FPR(:,ind50),TPR(:,ind50),'ks','MarkerFaceColor','w');
pl{end+1}='pcut=0.5';
set(gca,'XTick',0:.2:1,'YTick',0:.2:1)
legend(ph,pl,'Location','SouthEast')
xlabel('FPR');
ylabel('TPR');
xlim([0 1]);
ylim([0 1]);
print(gcf, outpng, '-dpng', '-r300');

end
