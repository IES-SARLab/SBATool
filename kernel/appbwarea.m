function appbwarea(fconfig,tsize,ftype,pcut,bwvals)
%function appbwarea(fconfig,tsize,ftype,pcut,bwvals)
% ftype  = 'low' or 'high'
% bwvals = [bwp1_old bwp1_new]
%

loadparam;

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
bwp2     = 8;
if bwvals(2) <= bwvals(1)
    error(sprintf('New bwarea parameter (%d) <= old parameter (%d). Exit.', bwvals(2),bwvals(1)))
end

display(sprintf('Apply new bwarea parameter bwp1=%d',bwvals(2)));
fpmfile    = sprintf('%s/%s_t%d_%s_p%02d_bw%d.tif',fpmdir,prefix,tsize,ftype,pcut*100,bwvals(1));
fpmfilemod = sprintf('%s/%s_t%d_%s_p%02d_bw%d.tif',fpmdir,prefix,tsize,ftype,pcut*100,bwvals(2));
FPMlow = geotiffread(fpmfile);
FPMlow = bwareaopen(FPMlow,bwvals(2),bwp2);
FPMlow = bwareaopen(FPMlow==0,bwvals(2),bwp2);
FPMlow = (FPMlow~=1);
mat2geotiff(FPMlow, X,Y,fpmfilemod,'geotiff',1,1,[],info)
 
return;

