function g03_growlow(fconfig,varargin)
%function g03_growlow(fconfig,[splitid])
% Tile growing for Z- changes
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
threshG1 = eval(config('threshG1'));
threshG  = eval(config('threshG'));
conn = eval(config('connlow'));
expandgrowth = eval(config('expand'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
ampEventNorm = readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/03_growlow.log',qcdir);
tsize = eval(config('tsize'));

tt=toc;
logging(qclog,sprintf('Done loading file %s. %f seconds used.',eventImg,tt));
fpm0 = zeros(size(ampEventNorm));
fpm0( find(ampEventNorm<-1) ) = -1;
fpm0( find(ampEventNorm> 2) ) =  1;
fpm0( isnan(ampEventNorm) ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Tile growing 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nthresh = nthresh0;
runIter = 1;
tic;
while runIter 

    load(sprintf('%s/%s_init_t%d',qcdir,qcprefix,tsize));
    [G1At,G1Mt,G1St,G2At,G2Mt,G2St] = selectTile(BCt,AD1t,SR1t,AS1t,NIA1t,G1At0,G1Mt0,G1St0,threshG1,1,G2At0,G2Mt0,G2St0);
    [C1t,C2t] = selectTileSingle(BCSt,C1t,C2t,threshG); 

    % calculating statistics
    logging(qclog,sprintf('===== Start growing at tsize = %d, nthresh = %d',tsize,nthresh));
    logging(qclog,sprintf('Expand growing is %s',config('expand')));
    if nthresh > 1
        if expandgrowth
            [BCtr,AD1tr,SR1tr,AS1tr,NIA1tr,G1Atr,G1Mtr,G1Str,G2Atr,G2Mtr,G2Str] = getTileRegionExpand(ampEventNorm,G1Mt,G1St,xtilevec,ytilevec,1,threshG1,nthresh,conn,qclog);
        else
            [BCtr,AD1tr,SR1tr,AS1tr,NIA1tr,G1Atr,G1Mtr,G1Str,G2Atr,G2Mtr,G2Str] = getTileRegion(ampEventNorm,G1Mt,G1St,xtilevec,ytilevec,1,threshG1,nthresh,conn,qclog);
        end
    else
        if expandgrowth
            [BCtr,AD1tr,SR1tr,AS1tr,NIA1tr,G1Atr,G1Mtr,G1Str,G2Atr,G2Mtr,G2Str] = getTileRegionExpand(ampEventNorm,G1Mt,G1St,xtilevec,ytilevec,1,threshG1,nthresh,conn,qclog);
        else
            [BCtr,AD1tr,SR1tr,AS1tr,NIA1tr,G1Atr,G1Mtr,G1Str,G2Atr,G2Mtr,G2Str] = getTileRegion(ampEventNorm,G1Mt,G1St,xtilevec,ytilevec,1,threshG1,nthresh,conn,qclog);
        end
        msk1 = ((G1Mtr~=0)&isfinite(G1Mtr));
        msk2 = ((G1Mtr==0)&isfinite(G1Mtr)&(G1Mt~=0));
        G1Atr = G1Atr.*msk1+G1At.*msk2;
        G1Mtr = G1Mtr.*msk1+G1Mt.*msk2;
        G1Str = G1Str.*msk1+G1St.*msk2;
        G2Atr = G2Atr.*msk1+G2At.*msk2;
        G2Mtr = G2Mtr.*msk1+G2Mt.*msk2;
        G2Str = G2Str.*msk1+G2St.*msk2;
        BCtr  = BCtr.*msk1+BCt.*msk2;
        AD1tr = AD1tr.*msk1+AD1t.*msk2;
        SR1tr = SR1tr.*msk1+SR1t.*msk2;
        AS1tr = AS1tr.*msk1+AS1t.*msk2;
        NIA1tr = NIA1tr.*msk1+NIA1t.*msk2;
    end
    [G1Atr2,G1Mtr2,G1Str2,G2Atr2,G2Mtr2,G2Str2] = selectTile(BCtr,AD1tr,SR1tr,AS1tr,NIA1tr,G1Atr,G1Mtr,G1Str,threshG1,1,G2Atr,G2Mtr,G2Str); 

    % next round
    if (sum(G1Mtr2~=0,'all')<10 & (nthresh~=1))
        nthresh = nthresh-1;
    else
        save(sprintf('%s/%s_grow_lo%d',qcdir,qcprefix,tsize),'G1At0','G1At','G1Atr','G1Atr2',...
                                                           'G1Mt0','G1Mt','G1Mtr','G1Mtr2',...
                                                           'G1St0','G1St','G1Str','G1Str2',...
                                                           'G2At0','G2At','G2Atr','G2Atr2',...
                                                           'G2Mt0','G2Mt','G2Mtr','G2Mtr2',...
                                                           'G2St0','G2St','G2Str','G2Str2','C1t');
        nthresh = nthresh0;
        runIter = 0;
    end
end

ttt = toc;
logging(qclog,sprintf('Total runtime is %f seconds',ttt));
 
tlog = sprintf('%s/time_g03',qcdir);
logging(tlog,sprintf('%f',ttt));

return;

