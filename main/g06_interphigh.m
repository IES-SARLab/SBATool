function g06_interphigh(fconfig)
%function g06_interphigh(fconfig)
% Fill statistics for Z+ changes 
% results from subimages (if dosplit=true) will be merged
%
% fconfig: user-specified configuration file
%
% NinaLin@2023

loadparam;

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
nthresh0 = eval(config('nthresh'));
method   = config('methodhigh'); 
methodstr= methodstr2;
pcuthigh = eval(config('pcuthigh'));
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
qclog = sprintf('%s/06_interphigh.log',qcdir);
qctxt = sprintf('%s/06_interphigh.txt',qcdir);
fid = fopen(qctxt, 'w');
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end

tsizelist = eval(config('tsize'));
lookpF    = initLook(eventImg,config,'lookpF');
lookRk    = initLook(eventImg,config,'lookRk');
bwp1 = initBWarea(eventImg,config,'minpatchhigh');
bwp2 = 8; %neighbor type

logging(qclog,sprintf('Interpoation method:                            %s',method))
logging(qclog,sprintf('Image pixel resolution:                         %d',pixelres))
logging(qclog,sprintf('Image size:                                     %dx%d',numel(X),numel(Y)))
logging(qclog,sprintf('Looks taken for QC:                             %d',lookpF))
logging(qclog,sprintf('Looks taken for Rk clustering calculation:      %d',lookRk))
logging(qclog,sprintf('Min number of pixels required in a patch:       %d',bwp1)) 
logging(qclog,sprintf('Cutoff prob for amp-increase changes:           %f',pcuthigh))

tt=toc;
logging(qclog,sprintf('Done loading file %s. %f seconds used.',eventImg,tt));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Fill stats and generate change map 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nthresh = nthresh0;
parlist={'G3At0','G3At','G3Atr','G3Atr2',...
         'G3Mt0','G3Mt','G3Mtr','G3Mtr2',...
         'G3St0','G3St','G3Str','G3Str2',...
         'G2At0','G2At','G2Atr','G2Atr2',...
         'G2Mt0','G2Mt','G2Mtr','G2Mtr2',...
         'G2St0','G2St','G2Str','G2Str2','C2t'};
logging(qclog,' ');
logging(qclog,'         runtime #Total   #Detect   Area         ');
logging(qclog,'tsize      (s)    tiles    tiles    Percent   Rk      Rksmode ');
logging(qclog,'---------------------------------------------------------------');
fprintf(fid,'tsize    runtime #Total   #Detected   AreaPerc  Rk      Rksmode\n');

tic;
tsize= tsizelist;

% load statistics
if dosplit
    sp = eval(config('splitsize'));
    for kk = 1:numel(parlist)
        parname = parlist{kk};
        for ii = 1:sp(1)
            for jj = 1:sp(2)
                tmp = load(sprintf('%s/%s_%d_grow_hi%d',qcdir,prefix,sub2ind(sp,ii,jj),tsize), parname);
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
        tmp = load(sprintf('%s/%s_grow_hi%d',qcdir,prefix,tsize), parname); 
        eval([parname '=tmp.' parname ';']);
        %logging(qclog,sprintf('Finish loading %s for tsize = %d',parname,tsize));
    end
    [~,xtilevec,ytilevec] = img2Tile(ampEventNorm,tsize,shift,'geom');
end

if strcmp(method,'quantile')||strcmp(method,'const_q')
    [G3Ahat,G3Mhat,G3Shat,G3Mtr3,G3Str3] = interpTileStat(ampEventNorm,G3Atr2,G3Mtr2,G3Str2,xtilevec,ytilevec,method,methodq);
    [G2Ahat,G2Mhat,G2Shat] = interpTileStat(ampEventNorm,G2Atr2,G2Mtr2,G2Str2,xtilevec,ytilevec,method,methodq);
else
    [G3Ahat,G3Mhat,G3Shat,G3Mtr3,G3Str3] = interpTileStat(ampEventNorm,G3Atr2,G3Mtr2,G3Str2,xtilevec,ytilevec,method);
    [G2Ahat,G2Mhat,G2Shat] = interpTileStat(ampEventNorm,G2Atr2,G2Mtr2,G2Str2,xtilevec,ytilevec,method);
end
mat2geotiff(int16(G3Mhat*100), X,Y,sprintf('%s/%s_intp_hi%d_G3M.tif',qcdir,qcprefix,tsize),'geotiff',ctype,16,[],info)
mat2geotiff(int16(G3Shat*100), X,Y,sprintf('%s/%s_intp_hi%d_G3S.tif',qcdir,qcprefix,tsize),'geotiff',ctype,16,[],info)

% for results that ignores small water bodies
if useG2
    [FPMhigh,pFhigh] = getFPMhigh(ampEventNorm,pcuthigh,G3Ahat,G3Mhat,G3Shat,G2Ahat,G2Mhat,G2Shat);
else
    [FPMhigh,pFhigh] = getFPMhigh(ampEventNorm,pcuthigh,G3Ahat,G3Mhat,G3Shat,G2Ahat);
end
FPMhigh = bwareaopen(FPMhigh,bwp1,bwp2);
FPMhigh = bwareaopen(FPMhigh==0,bwp1,bwp2);
FPMhigh = (FPMhigh~=1);
mat2geotiff(round(pFhigh*100),X,Y,sprintf('%s/%s_intp_hi%d_%s_prob.tif',fpmdir,prefix,tsize,methodstr),'geotiff',ctype,8,[],info)
mat2geotiff(FPMhigh,X,Y,sprintf('%s/%s_intp_hi%d_%s_p%02d_bw%d.tif',fpmdir,prefix,tsize,methodstr,pcuthigh*100,bwp1),'geotiff',ctype,1,[],info)

% for single-mode cut-off method
if dosmode
    if strcmp(method,'quantile')||strcmp(method,'const_q')
        [~,C2hat]  = interpTileStat(ampEventNorm,C2t,C2t,C2t,xtilevec,ytilevec,method,methodq);
    else
        [~,C2hat]  = interpTileStat(ampEventNorm,C2t,C2t,C2t,xtilevec,ytilevec,method);
    end
    FPMhighSingle = (ampEventNorm>=C2hat);
    FPMhighSingle = bwareaopen(FPMhighSingle,bwp1,bwp2);
    FPMhighSingle = bwareaopen(FPMhighSingle==0,bwp1,bwp2);
    FPMhighSingle = (FPMhighSingle~=1);
    FPMhighSingleLK = LookDownBinary(FPMhighSingle,lookRk);
    RKSingle  = ripley(FPMhighSingleLK,2);
    mat2geotiff(int16(C2hat*100),  X,Y,sprintf('%s/%s_intp_hi%d_%s_C2.tif', qcdir,qcprefix,tsize,methodstr),'geotiff',ctype,16,[],info)
    mat2geotiff(FPMhighSingle,X,Y,sprintf('%s/%s_intp_hi%d_smode_%s_bw%d.tif',fpmdir,prefix,tsize,methodstr,bwp1),'geotiff',ctype,1,[],info)
end

% next round
ntilelist = numel(G3Mtr2);
nGtlist   = sum(sum(G3Mtr2~=0));
NFP       = sum(FPMhigh(:)==1)/numel(FPMhigh(:))*100;
pFhighLK  = LookDown(pFhigh,lookpF);
FPMhighLK = LookDownBinary(FPMhigh,lookRk);
RK        = ripley(FPMhighLK,2);
tt        = toc;
if dosmode
    fprintf(fid,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f %-8.2f\n',tsize,round(tt),ntilelist,nGtlist,NFP,RK,RKSingle));
    logging(qclog,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f %-8.2f',tsize,round(tt),ntilelist,nGtlist,NFP,RK,RKSingle));
    save(sprintf('%s/%s_intp_hi%d_%s',qcdir,qcprefix,tsize,methodstr),'G3Mt0','G3Mt','G3Mtr','G3Mtr2','G3Mtr3',...
                                                           'G3St0','G3St','G3Str','G3Str2','G3Str3',...
                                                           'FPMhighLK','FPMhighSingleLK','pFhighLK','shift');
else
    fprintf(fid,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f NaN\n',tsize,round(tt),ntilelist,nGtlist,NFP,RK));
    logging(qclog,sprintf('%-8d %-8d %-8d %-8d %-8.2f %-8.2f NaN',tsize,round(tt),ntilelist,nGtlist,NFP,RK));
    save(sprintf('%s/%s_intp_hi%d_%s',qcdir,qcprefix,tsize,methodstr),'G3Mt0','G3Mt','G3Mtr','G3Mtr2','G3Mtr3',...
                                                           'G3St0','G3St','G3Str','G3Str2','G3Str3',...
                                                           'FPMhighLK','pFhighLK','shift');
end

fclose(fid);
logging(qclog,sprintf('Total runtime is %f seconds',tt));
 
tlog = sprintf('%s/time_g06',qcdir);
logging(tlog,sprintf('%f',tt));

return;

