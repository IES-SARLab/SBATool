function g02_init(fconfig,varargin)
%function g02_init(fconfig,[splitid])
% Initial tile splitting and histogram fitting;
% the tile size is set by 'tsize' in config.txt
%
% fconfig: user-specified configuration file
% splitid: the split ID when the image is too large 
%          and is split into multiple subimages
%          for a (2x2) split, the splitid is
%           1 2
%           3 4
%
% NinaLin@2023

loadparam;

if numel(varargin)>0; splitid=varargin{1}; end

if  isKey(config,'dosplit') & eval(config('dosplit'))
    eventImg = sprintf('%s/%s_%d.tif',fpmdir,prefix,splitid);
    qcImg    = sprintf('%s/%s_%d.tif',qcdir,prefix,splitid);
else
    eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
    qcImg    = sprintf('%s/%s.tif',qcdir,prefix);
end

nthresh0 = eval(config('nthresh'));
shift1   = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
ampEventNorm = readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/02_init.log',qcdir);
tt=toc;

% Initialize tile size based on image dimensions    
tsizelist = eval(config('tsize'));
logging(qclog,sprintf('Image size: %d, %d',size(ampEventNorm,2),size(ampEventNorm,1)));
logging(qclog,sprintf('Tile size initialized: %d\n',tsizelist));

logging(qclog,sprintf('Done loading file %s. %f seconds used.',eventImg,tt));
fpm0 = zeros(size(ampEventNorm));
fpm0( find(ampEventNorm<-1) ) = -1;
fpm0( find(ampEventNorm> 2) ) =  1;
fpm0( isnan(ampEventNorm) ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Search for tsize 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

cnt = 1;
while ( cnt <= numel(tsizelist) )

    tsize= tsizelist(cnt);

    % calculating statistics
    logging(qclog,sprintf('===== Start searching at tsize = %d, nthresh = %d',tsize,nthresh0));
    [xtilevec,ytilevec,BCt,AD1t,AD3t,SR1t,SR3t,AS1t,AS3t,NIA1t,NIA3t,C1t,C2t,BCSt,...
     G1At0,G1Mt0,G1St0,G2At0,G2Mt0,G2St0,G3At0,G3Mt0,G3St0] = ...
                                            tileStat3gParallel(ampEventNorm,tsize,shift1,fpm0,3);
    save(sprintf('%s/%s_init_t%d',qcdir,qcprefix,tsize),...
         'xtilevec','ytilevec','BCt','AD1t','AD3t','SR1t','SR3t','AS1t','AS3t','NIA1t','NIA3t','C1t','C2t','BCSt',...
         'G1At0','G1Mt0','G1St0','G2At0','G2Mt0','G2St0','G3At0','G3Mt0','G3St0');

    cnt = cnt+1;

end

ttt = toc;
logging(qclog,sprintf('Total search time is %f seconds',ttt));

tlog = sprintf('%s/time_g02',qcdir);
logging(tlog,sprintf('%f',ttt));

 
return;

