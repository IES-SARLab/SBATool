function h05_hsbaphigh(fconfig)
%function h05_hsbaphigh(fconfig)
% Fill statistics and compute probability map and change map
% for Z- changes
%
% fconfig: user-specified configuration file
%
% NinaLin@2023

loadparam;

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
pcut  = eval(config('pcuthigh'));
pixelres = getPixelRes(eventImg,config,'pixelres');
useG2    = eval(config('useG2'));
dosmode  = eval(config('dosmode'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
[ampEventNorm,X,Y,info]=readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/05_hsbaphigh.log',qcdir);
qctxt = sprintf('%s/05_hsbaphigh.txt',qcdir);
fid = fopen(qctxt, 'w');
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end

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
logging(qclog,sprintf('Cutoff prob for amp-decrease changes:           %f',pcut))

tt=toc;
logging(qclog,sprintf('Done loading file %s. %f seconds used.',eventImg,tt));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Fill stats and generate map 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
logging(qclog,' ');
logging(qclog,'    runtime  #Detect   Area         ');
logging(qclog,'      (s)     tiles    Percent   Rk      Rksmode ');
logging(qclog,'---------------------------------------------------------------');
fprintf(fid,'    runtime #Detected   AreaPerc  Rk      Rksmode\n');

load(sprintf('%s/%s_hsba_G3',qcdir,prefix)); 

if strcmp(method,'quantile')||strcmp(method,'const_q')
    [G3Ahat,G3Mhat,G3Shat] = fillStat(G3A,G3M,G3S,method,methodq);
    [G2Ahat,G2Mhat,G2Shat] = fillStat(G2A,G2M,G2S,method,methodq);
else
    [G3Ahat,G3Mhat,G3Shat] = fillStat(G3A,G3M,G3S,method);
    [G2Ahat,G2Mhat,G2Shat] = fillStat(G2A,G2M,G2S,method);
end
mat2geotiff(int16(G3Ahat*100), X,Y,sprintf('%s/%s_intp_hi_%s_G3A.tif',qcdir,qcprefix,methodstr),'geotiff',ctype,16,[],info)
mat2geotiff(int16(G3Mhat*100), X,Y,sprintf('%s/%s_intp_hi_%s_G3M.tif',qcdir,qcprefix,methodstr),'geotiff',ctype,16,[],info)
mat2geotiff(int16(G3Shat*100), X,Y,sprintf('%s/%s_intp_hi_%s_G3S.tif',qcdir,qcprefix,methodstr),'geotiff',ctype,16,[],info)

% for results that ignores small water bodies
if useG2
    [FPMhigh,pFhigh] = getFPMhigh(ampEventNorm,pcut,G3Ahat,G3Mhat,G3Shat,G2Ahat,G2Mhat,G2Shat);
else
    [FPMhigh,pFhigh] = getFPMhigh(ampEventNorm,pcut,G3Ahat,G3Mhat,G3Shat,G2Ahat);
end
FPMhigh = bwareaopen(FPMhigh,bwp1,bwp2);
FPMhigh = bwareaopen(FPMhigh==0,bwp1,bwp2);
FPMhigh = (FPMhigh~=1);
mat2geotiff(round(pFhigh*100),X,Y,sprintf('%s/%s_intp_hi_%s_prob.tif',fpmdir,prefix,methodstr),'geotiff',ctype,8,[],info)
mat2geotiff(FPMhigh,X,Y,sprintf('%s/%s_intp_hi_%s_p%02d_bw%d.tif',fpmdir,prefix,methodstr,pcut*100,bwp1),'geotiff',ctype,1,[],info)

nG = sum(sum(G3M~=0));
NFP = sum(FPMhigh(:)==1)/numel(FPMhigh(:))*100;
pFhighLK = LookDown(pFhigh,lookpF);
FPMhighLK = LookDownBinary(FPMhigh,lookRk);
RK = ripley(FPMhighLK,2);
tt = toc;

fprintf(fid,sprintf('%-8d %-8d %-8.2f %-8.2f NaN\n',round(tt),nG,NFP,RK));
logging(qclog,sprintf('%-8d %-8d %-8.2f %-8.2f NaN',round(tt),nG,NFP,RK));
save(sprintf('%s/%s_intp_hi_%s',qcdir,qcprefix,methodstr),...
                                                       'FPMhighLK','pFhighLK');

fclose(fid);
logging(qclog,sprintf('Total search time is %f seconds',tt));
 
tlog = sprintf('%s/time_h05',qcdir);
logging(tlog,sprintf('%f',tt));

return;

