function g04_growhigh(fconfig,varargin)
%function g04_growhigh(fconfig,[splitid])
% Tile growing for Z+ changes
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
threshG3 = eval(config('threshG3'));
threshG  = eval(config('threshG'));
conn = eval(config('connhigh'));
expandgrowth = eval(config('expand'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
ampEventNorm = readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/04_growhigh.log',qcdir);
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
    [G3At,G3Mt,G3St,G2At,G2Mt,G2St] = selectTile(BCt,AD3t,SR3t,AS3t,NIA3t,G3At0,G3Mt0,G3St0,threshG3,3,G2At0,G2Mt0,G2St0); 
    [C1t,C2t] = selectTileSingle(BCSt,C1t,C2t,threshG); 
        
    % calculating statistics
    logging(qclog,sprintf('===== Start growing at tsize = %d, nthresh = %d',tsize,nthresh));
    logging(qclog,sprintf('Expand growing is %s',config('expand')));
    if nthresh > 1
        if expandgrowth
            [BCtr,AD3tr,SR3tr,AS3tr,NIA3tr,G3Atr,G3Mtr,G3Str,G2Atr,G2Mtr,G2Str] = getTileRegionExpand(ampEventNorm,G3Mt,G3St,xtilevec,ytilevec,3,threshG3,nthresh,conn,qclog);
        else
            [BCtr,AD3tr,SR3tr,AS3tr,NIA3tr,G3Atr,G3Mtr,G3Str,G2Atr,G2Mtr,G2Str] = getTileRegion(ampEventNorm,G3Mt,G3St,xtilevec,ytilevec,3,threshG3,nthresh,conn,qclog);
        end
    else
        if expandgrowth
            [BCtr,AD3tr,SR3tr,AS3tr,NIA3tr,G3Atr,G3Mtr,G3Str,G2Atr,G2Mtr,G2Str] = getTileRegionExpand(ampEventNorm,G3Mt,G3St,xtilevec,ytilevec,3,threshG3,nthresh,conn,qclog);
        else
            [BCtr,AD3tr,SR3tr,AS3tr,NIA3tr,G3Atr,G3Mtr,G3Str,G2Atr,G2Mtr,G2Str] = getTileRegion(ampEventNorm,G3Mt,G3St,xtilevec,ytilevec,3,threshG3,nthresh,conn,qclog);
        end
        msk1 = ((G3Mtr~=0)&isfinite(G3Mtr));
        msk2 = ((G3Mtr==0)&isfinite(G3Mtr)&(G3Mt~=0));
        G3Atr = G3Atr.*msk1+G3At.*msk2;
        G3Mtr = G3Mtr.*msk1+G3Mt.*msk2;
        G3Str = G3Str.*msk1+G3St.*msk2;
        G2Atr = G2Atr.*msk1+G2At.*msk2;
        G2Mtr = G2Mtr.*msk1+G2Mt.*msk2;
        G2Str = G2Str.*msk1+G2St.*msk2;
        BCtr  = BCtr.*msk1+BCt.*msk2;
        AD3tr = AD3tr.*msk1+AD3t.*msk2;
        SR3tr = SR3tr.*msk1+SR3t.*msk2;
        AS3tr = AS3tr.*msk1+AS3t.*msk2;
        NIA3tr = NIA3tr.*msk1+NIA3t.*msk2;
    end
    [G3Atr2,G3Mtr2,G3Str2,G2Atr2,G2Mtr2,G2Str2] = selectTile(BCtr,AD3tr,SR3tr,AS3tr,NIA3tr,G3Atr,G3Mtr,G3Str,threshG3,3,G2Atr,G2Mtr,G2Str); 

    % next round
    if (sum(G3Mtr2~=0,'all')<5 & (nthresh~=1))
        nthresh = nthresh-1;
    else
        save(sprintf('%s/%s_grow_hi%d',qcdir,qcprefix,tsize),'G3At0','G3At','G3Atr','G3Atr2',...
                                                            'G3Mt0','G3Mt','G3Mtr','G3Mtr2',...
                                                            'G3St0','G3St','G3Str','G3Str2',...
                                                            'G2At0','G2At','G2Atr','G2Atr2',...
                                                            'G2Mt0','G2Mt','G2Mtr','G2Mtr2',...
                                                            'G2St0','G2St','G2Str','G2Str2','C2t');
        nthresh = nthresh0;
        runIter = 0;
    end
end

ttt = toc;
logging(qclog,sprintf('Total runtime is %f seconds',ttt));
 
tlog = sprintf('%s/time_g04',qcdir);
logging(tlog,sprintf('%f',ttt));

return;

