function g07_qcmetrics(fconfig);
%function g07_qcmetrics(fconfig);
% Compute QC metrics; merge Z- with Z+ results
%
%  fconfig: user-specified configuration file
%
% NinaLin@2023

loadparam;
dosmode  = eval(config('dosmode'));
pcutlow  = eval(config('pcutlow'));
pcuthigh = eval(config('pcuthigh'));
qlow  = eval(config('qlow'));
qmid  = eval(config('qmid'));
qhigh = eval(config('qhigh'));
eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
info  = geotiffinfo(eventImg);
[X,Y] = geotiffinfo2xy(info);
if mean(diff(X))>1 
    ctype = 2;  %projected
else
    ctype = 1;  %geographic 
end
tsize = eval(config('tsize'));
bwp1low = initBWarea(eventImg,config,'minpatchlow');
bwp1high = initBWarea(eventImg,config,'minpatchhigh');
ffinal = sprintf('%s/finalfile_%s_bw%d_%d.txt',qcdir,methodstr,bwp1low,bwp1high);
fid2   = fopen(ffinal, 'w');

if (ct==1)|(ct==0) %for Z-
    lee7grd.mat1 = textread(sprintf('%s/05_interplow.txt',qcdir),'','headerlines',1);
    lee7grd.RK1=lee7grd.mat1(:,6);
    lee7grd.RK1(lee7grd.RK1==0)=NaN;
    if dosmode
        lee7grd.RK1smode=lee7grd.mat1(:,7);
        lee7grd.RK1smode(lee7grd.RK1smode==0)=NaN;
    end
    lee7grd.NFP1=lee7grd.mat1(:,5);
    lee7grd.NFP1(lee7grd.NFP1==0)=NaN;
    lee7grd.NT1=lee7grd.mat1(:,4);
    lee7grd.NT1(lee7grd.NFP1==0)=NaN;
    % Print out information
    fprintf(1,'\nZ- changes\n')
    fprintf(1,'Tile size              : %d\n',tsize);
    fprintf(1,'#Tile                  : %d\n',lee7grd.NT1);
    fprintf(1,'Change area (%)        : %0.2f\n',lee7grd.NFP1);
    fprintf(1,'Spatial Clustering (Rk): %0.2f\n',lee7grd.RK1);
    logging(0,sprintf('Rk level for the final amp- change map: %s',lee7grd.RK1))

    %%% Section to merge results of amp- and amp+ changes
    bwp1low = initBWarea(eventImg,config,'minpatchlow');
    FPMlow  = geotiffread(sprintf('%s/%s_intp_lo%d_%s_p%02d_bw%d.tif',fpmdir,prefix,tsize,methodstr,pcutlow*100,bwp1low));
    fplow = sprintf('%s/%s_intp_lo%d_%s_prob.tif',fpmdir,prefix,tsize,methodstr);
    plow  = geotiffread(fplow);
    fprintf(fid2,'%s\n',fplow);
end

if (ct==3)|(ct==0) %for Z+
    lee7grd.mat2 = textread(sprintf('%s/06_interphigh.txt',qcdir),'','headerlines',1);
    lee7grd.RK2=lee7grd.mat2(:,6);
    lee7grd.RK2(lee7grd.RK2==0)=NaN;
    if dosmode
        lee7grd.RK2smode=lee7grd.mat2(:,7);
        lee7grd.RK2smode(lee7grd.RK2smode==0)=NaN;
    end
    lee7grd.NFP2=lee7grd.mat2(:,5);
    lee7grd.NFP2(lee7grd.NFP2==0)=NaN;
    lee7grd.NT2=lee7grd.mat2(:,4);
    lee7grd.NT2(lee7grd.NFP2==0)=NaN;
    % Print out information
    fprintf(1,'\nZ+ changes\n')
    fprintf(1,'Tile size              : %d\n',tsize);
    fprintf(1,'#Tile                  : %d\n',lee7grd.NT2);
    fprintf(1,'Change area (%)        : %0.2f\n',lee7grd.NFP2);
    fprintf(1,'Spatial Clustering (Rk): %0.2f\n',lee7grd.RK2);
    logging(0,sprintf('Rk level for the final amp+ change map: %s',lee7grd.RK2))

    %%% Section to merge results of amp- and amp+ changes
    bwp1high = initBWarea(eventImg,config,'minpatchhigh');
    FPMhigh = geotiffread(sprintf('%s/%s_intp_hi%d_%s_p%02d_bw%d.tif',fpmdir,prefix,tsize,methodstr2,pcuthigh*100,bwp1high));
    fphigh = sprintf('%s/%s_intp_hi%d_%s_prob.tif',fpmdir,prefix,tsize,methodstr2);
    phigh  = geotiffread(fphigh);
    fprintf(fid2,'%s\n',fphigh);
end

%%% Section to merge results of amp- and amp+ changes
if ct==1 %Z-
    FPMboth = FPMlow*2;
elseif ct==3 %Z+ 
    FPMboth = FPMhigh*1; 
elseif ct==0 %both
    FPMboth = FPMhigh*2 + FPMlow*1; % 1=low, 2=high
end

outfile1 = sprintf('%s/%s_clstX_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
outfilep = sprintf('%s/%s_clstX_%s_prob.tif',fpmdir,prefix,methodstr);
if ct==1 %Z- 
    pboth = getPboth(plow,phigh*0,FPMboth);
elseif ct==3 %Z+
    pboth = getPboth(plow*0,phigh,FPMboth);
elseif ct==0 %both
    pboth = getPboth(plow,phigh,FPMboth);
end
mat2geotiff(FPMboth,X,Y,outfile1,'geotiff',ctype,8,[],info);
mat2geotiff(pboth,X,Y,outfilep,'geotiff',ctype,8,[],info);
logging(0,sprintf('Output probability file %s',outfilep));
logging(0,sprintf('Output nonclustered file %s',outfile1));

if dosmode
    FPMlowSingle  = geotiffread(sprintf('%s/%s_intp_lo%d_smode_%s_bw%d.tif',fpmdir,prefix,tsize,methodstr,bwp1low));
    FPMhighSingle = geotiffread(sprintf('%s/%s_intp_hi%d_smode_%s_bw%d.tif',fpmdir,prefix,tsize,methodstr,bwp1high));
    FPMbothSingle = FPMhighSingle*2 + FPMlowSingle*1; % 1=low, 2=high
    outfileS = sprintf('%s/%s_clstX_smode_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
    mat2geotiff(FPMbothSingle,X,Y,outfileS,'geotiff',ctype,8,[],info);
    logging(qctxt,sprintf('Output nonclustered file %s\n',outfile1));
    fprintf(fid2,'%s\n',outfile1);
end

fclose(fid2);
