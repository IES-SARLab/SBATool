function h04_hsbaplow(fconfig)
%function h04_hsbaplow(fconfig)
% Fill statistics and compute probability map and change map
% for Z- changes
%
% fconfig: user-specified configuration file
%
% NinaLin@2023

loadparam;

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
pcut  = eval(config('pcutlow'));
pixelres = getPixelRes(eventImg,config,'pixelres');
useG2    = eval(config('useG2'));
dosmode  = eval(config('dosmode'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
[ampEventNorm,X,Y,info]=readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/04_hsbaplow.log',qcdir);
qctxt = sprintf('%s/04_hsbaplow.txt',qcdir);
fid = fopen(qctxt, 'w');
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end

lookpF    = initLook(eventImg,config,'lookpF');
lookRk    = initLook(eventImg,config,'lookRk');
bwp1   = initBWarea(eventImg,config,'minpatchlow');
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
%% 2. Fill stats and generate change map 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
logging(qclog,' ');
logging(qclog,'    runtime  #Detect   Area         ');
logging(qclog,'      (s)     tiles    Percent   Rk      Rksmode ');
logging(qclog,'---------------------------------------------------------------');
fprintf(fid,'    runtime #Detected   AreaPerc  Rk      Rksmode\n');

load(sprintf('%s/%s_hsba_G1',qcdir,prefix)); 

if strcmp(method,'quantile')||strcmp(method,'const_q')
    [G1Ahat,G1Mhat,G1Shat] = fillStat(G1A,G1M,G1S,method,methodq);
    [G2Ahat,G2Mhat,G2Shat] = fillStat(G2A,G2M,G2S,method,methodq);
else
    [G1Ahat,G1Mhat,G1Shat] = fillStat(G1A,G1M,G1S,method);
    [G2Ahat,G2Mhat,G2Shat] = fillStat(G2A,G2M,G2S,method);
end
mat2geotiff(int16(G1Mhat*100), X,Y,sprintf('%s/%s_intp_lo_%s_G1M.tif',qcdir,qcprefix,methodstr),'geotiff',ctype,16,[],info)
mat2geotiff(int16(G1Shat*100), X,Y,sprintf('%s/%s_intp_lo_%s_G1S.tif',qcdir,qcprefix,methodstr),'geotiff',ctype,16,[],info)

% for results that ignores small water bodies
if useG2
    [FPMlow,pFlow] = getFPMlow(ampEventNorm,pcut,G1Ahat,G1Mhat,G1Shat,G2Ahat,G2Mhat,G2Shat);
else
    [FPMlow,pFlow] = getFPMlow(ampEventNorm,pcut,G1Ahat,G1Mhat,G1Shat,G2Ahat);
end
FPMlow = bwareaopen(FPMlow,bwp1,bwp2);
FPMlow = bwareaopen(FPMlow==0,bwp1,bwp2);
FPMlow = (FPMlow~=1);
mat2geotiff(round(pFlow*100),X,Y,sprintf('%s/%s_intp_lo_%s_prob.tif',fpmdir,prefix,methodstr),'geotiff',ctype,8,[],info)
mat2geotiff(FPMlow,X,Y,sprintf('%s/%s_intp_lo_%s_p%02d_bw%d.tif',fpmdir,prefix,methodstr,pcut*100,bwp1),'geotiff',ctype,1,[],info)

nG = sum(sum(G1M~=0));
NFP = sum(FPMlow(:)==1)/numel(FPMlow(:))*100;
pFlowLK = LookDown(pFlow,lookpF);
FPMlowLK = LookDownBinary(FPMlow,lookRk);
RK = ripley(FPMlowLK,2);
tt = toc;

fprintf(fid,sprintf('%-8d %-8d %-8.2f %-8.2f NaN\n',round(tt),nG,NFP,RK));
logging(qclog,sprintf('%-8d %-8d %-8.2f %-8.2f NaN',round(tt),nG,NFP,RK));
save(sprintf('%s/%s_intp_lo_%s',qcdir,qcprefix,methodstr),...
                                                       'FPMlowLK','pFlowLK');

fclose(fid);
logging(qclog,sprintf('Total search time is %f seconds',tt));
 
tlog = sprintf('%s/time_h04',qcdir);
logging(tlog,sprintf('%f',tt));

return;

