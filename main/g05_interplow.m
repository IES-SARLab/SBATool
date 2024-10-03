function g05_interplow(fconfig)
%function g05_interplow(fconfig)
% Fill statistics for Z- changes
% results from subimages (if dosplit=true) will be merged
%
% fconfig: user-specified configuration file
%
% NinaLin@2023

loadparam;

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
nthresh0 = eval(config('nthresh'));
pcutlow  = eval(config('pcutlow'));
pixelres = getPixelRes(eventImg,config,'pixelres');
useG2    = eval(config('useG2'));
dosmode  = eval(config('dosmode'));
shift    = 0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
[ampEventNorm,X,Y,info]=readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/05_interplow.log',qcdir);
qctxt = sprintf('%s/05_interplow.txt',qcdir);
fid = fopen(qctxt, 'w');
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end

tsize  = eval(config('tsize'));
lookpF = initLook(eventImg,config,'lookpF');
lookRk = initLook(eventImg,config,'lookRk');
bwp1 = initBWarea(eventImg,config,'minpatchlow');
bwp2 = 8; %neighbor type

logging(qclog,sprintf('Interpoation method:                            %s',method))
logging(qclog,sprintf('Image pixel resolution:                         %d',pixelres))
logging(qclog,sprintf('Image size:                                     %dx%d',numel(X),numel(Y)))
logging(qclog,sprintf('Looks taken for QC:                             %d',lookpF))
logging(qclog,sprintf('Looks taken for Rk clustering calculation:      %d',lookRk))
logging(qclog,sprintf('Min number of pixels required in a patch:       %d',bwp1)) 
logging(qclog,sprintf('Cutoff prob for amp-decrease changes:           %f',pcutlow))

tt=toc;
logging(qclog,sprintf('Done loading file %s. %f seconds used.',eventImg,tt));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Fill stats and genrate change map 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nthresh = nthresh0;
parlist={'G1At0','G1At','G1Atr','G1Atr2',...
         'G1Mt0','G1Mt','G1Mtr','G1Mtr2',...
         'G1St0','G1St','G1Str','G1Str2',...
         'G2At0','G2At','G2Atr','G2Atr2',...
         'G2Mt0','G2Mt','G2Mtr','G2Mtr2',...
         'G2St0','G2St','G2Str','G2Str2','C1t'};
logging(qclog,' ');
logging(qclog,'         runtime #Total   #Detect   Area         ');
logging(qclog,'tsize      (s)    tiles    tiles    Percent   Rk      Rksmode ');
logging(qclog,'---------------------------------------------------------------');
fprintf(fid,'tsize    runtime #Total   #Detected   AreaPerc  Rk      Rksmode\n');

tic;

% load statistics
if dosplit
    sp = eval(config('splitsize'));
    for kk = 1:numel(parlist)
        parname = parlist{kk};
        for ii = 1:sp(1)
            for jj = 1:sp(2)
                tmp = load(sprintf('%s/%s_%d_grow_lo%d',qcdir,prefix,sub2ind(sp,ii,jj),tsize), parname);
                eval(['Ac{' num2str(ii) ',' num2str(jj) '}=tmp.' parname ';']);
            end
        end
        A = cell2mat(Ac);
        eval([parname '=A;'])
        clear A Ac tmp
        %logging(qclog,sprintf('Finish merging %s for tsize = %d',parname,tsize));
    end
    [xtilevec,ytilevec] = splitImgTile(ampEventNorm,sp,tsize,shift);
else
    for ii = 1:numel(parlist)
        parname = parlist{ii};
        tmp = load(sprintf('%s/%s_grow_lo%d',qcdir,prefix,tsize), parname); 
        eval([parname '=tmp.' parname ';']);
        %logging(qclog,sprintf('Finish loading %s for tsize = %d',parname,tsize));
    end
    [~,xtilevec,ytilevec] = img2Tile(ampEventNorm,tsize,shift,'geom');
end

if strcmp(method,'quantile')||strcmp(method,'const_q')
    [G1Ahat,G1Mhat,G1Shat,G1Mtr3,G1Str3] = interpTileStat(ampEventNorm,G1Atr2,G1Mtr2,G1Str2,xtilevec,ytilevec,method,methodq);
    [G2Ahat,G2Mhat,G2Shat] = interpTileStat(ampEventNorm,G2Atr2,G2Mtr2,G2Str2,xtilevec,ytilevec,method,methodq);
else
    [G1Ahat,G1Mhat,G1Shat,G1Mtr3,G1Str3] = interpTileStat(ampEventNorm,G1Atr2,G1Mtr2,G1Str2,xtilevec,ytilevec,method);
    [G2Ahat,G2Mhat,G2Shat] = interpTileStat(ampEventNorm,G2Atr2,G2Mtr2,G2Str2,xtilevec,ytilevec,method);
end
mat2geotiff(int16(G1Ahat*100), X,Y,sprintf('%s/%s_intp_lo%d_%s_G1A.tif',qcdir,qcprefix,tsize,methodstr),'geotiff',ctype,16,[],info)
mat2geotiff(int16(G1Mhat*100), X,Y,sprintf('%s/%s_intp_lo%d_%s_G1M.tif',qcdir,qcprefix,tsize,methodstr),'geotiff',ctype,16,[],info)
mat2geotiff(int16(G1Shat*100), X,Y,sprintf('%s/%s_intp_lo%d_%s_G1S.tif',qcdir,qcprefix,tsize,methodstr),'geotiff',ctype,16,[],info)

% for results that ignores small water bodies
if useG2
    [FPMlow,pFlow] = getFPMlow(ampEventNorm,pcutlow,G1Ahat,G1Mhat,G1Shat,G2Ahat,G2Mhat,G2Shat);
else
    [FPMlow,pFlow] = getFPMlow(ampEventNorm,pcutlow,G1Ahat,G1Mhat,G1Shat,G2Ahat);
end
FPMlow = bwareaopen(FPMlow,bwp1,bwp2);
FPMlow = bwareaopen(FPMlow==0,bwp1,bwp2);
FPMlow = (FPMlow~=1);
mat2geotiff(round(pFlow*100),X,Y,sprintf('%s/%s_intp_lo%d_%s_prob.tif',fpmdir,prefix,tsize,methodstr),'geotiff',ctype,8,[],info)
mat2geotiff(FPMlow,X,Y,sprintf('%s/%s_intp_lo%d_%s_p%02d_bw%d.tif',fpmdir,prefix,tsize,methodstr,pcutlow*100,bwp1),'geotiff',ctype,1,[],info)

% for single-mode cut-off method
if dosmode
    if strcmp(method,'quantile')||strcmp(method,'const_q')
        [~,C1hat]  = interpTileStat(ampEventNorm,C1t,C1t,C1t,xtilevec,ytilevec,method,methodq);
    else
        [~,C1hat]  = interpTileStat(ampEventNorm,C1t,C1t,C1t,xtilevec,ytilevec,method);
    end
    FPMlowSingle = (ampEventNorm<=C1hat);
    FPMlowSingle = bwareaopen(FPMlowSingle,bwp1,bwp2);
    FPMlowSingle = bwareaopen(FPMlowSingle==0,bwp1,bwp2);
    FPMlowSingle = (FPMlowSingle~=1);
    FPMlowSingleLK = LookDownBinary(FPMlowSingle,lookRk);
    RKSingle  = ripley(FPMlowSingleLK,2);
    mat2geotiff(int16(C1hat*100),X,Y,sprintf('%s/%s_intp_lo%d_%s_C1.tif', qcdir,qcprefix,tsize,methodstr),'geotiff',ctype,16,[],info)
    mat2geotiff(FPMlowSingle,X,Y,sprintf('%s/%s_intp_lo%d_smode_%s_bw%d.tif',fpmdir,prefix,tsize,methodstr,bwp1),'geotiff',ctype,1,[],info)
end

% next round
ntilelist = numel(G1Mtr2);
nGtlist   = sum(sum(G1Mtr2~=0));
NFP       = sum(FPMlow(:)==1)/numel(FPMlow(:))*100;
pFlowLK   = LookDown(pFlow,lookpF);
FPMlowLK  = LookDownBinary(FPMlow,lookRk);
RK        = ripley(FPMlowLK,2);
tt        = toc;

if dosmode
    fprintf(fid,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f %-8.2f\n',tsize,round(tt),ntilelist,nGtlist,NFP,RK,RKSingle));
    logging(qclog,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f %-8.2f',tsize,round(tt),ntilelist,nGtlist,NFP,RK,RKSingle));
    save(sprintf('%s/%s_intp_lo%d_%s',qcdir,qcprefix,tsize,methodstr),'G1Mt0','G1Mt','G1Mtr','G1Mtr2','G1Mtr3',...
                                                           'G1St0','G1St','G1Str','G1Str2','G1Str3',...
                                                           'FPMlowLK','FPMlowSingleLK','pFlowLK','shift');
else
    fprintf(fid,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f NaN\n',tsize,round(tt),ntilelist,nGtlist,NFP,RK));
    logging(qclog,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f NaN',tsize,round(tt),ntilelist,nGtlist,NFP,RK));
    save(sprintf('%s/%s_intp_lo%d_%s',qcdir,qcprefix,tsize,methodstr),'G1Mt0','G1Mt','G1Mtr','G1Mtr2','G1Mtr3',...
                                                           'G1St0','G1St','G1Str','G1Str2','G1Str3',...
                                                           'FPMlowLK','pFlowLK','shift');
end

fclose(fid);

logging(qclog,sprintf('Total runtime is %f seconds',tt));

tlog = sprintf('%s/time_g05',qcdir);
logging(tlog,sprintf('%f',tt));

 
return;

