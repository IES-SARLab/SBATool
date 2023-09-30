function [BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str] = getTileRegionExpand(ampEventNorm,GMt,GSt,...
                                                                                      xtilevec,ytilevec,gaussianid,thresh,varargin)
%function [BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str] = getTileRegion(ampEventNorm,GMt,GSt,...
%                                                                                      xtilevec,ytilevec,gaussianid,thresh,[nthresh,conn])

if numel(varargin)>0; nthresh=varargin{1}; else; nthresh=2; end
if numel(varargin)>1; conn=varargin{2}; else; conn=8; end
if numel(varargin)>2; qclog=varargin{3}; else; qclog=1; end
%            AD   BC  SR   AS    M  NIA
%threshG3 = [1.9 .980 .05 0.02  2.5 0.4];
alpha = .05;

% keep only large connection components
%logging(qclog,sprintf('Recalculate stats for regions with number of connected tiles larger than %d',nthresh));
nxtile = size(xtilevec,2);
nytile = size(ytilevec,2);
xtileStart = xtilevec(1,:);
xtileEnd   = xtilevec(2,:);
ytileStart = ytilevec(1,:);
ytileEnd   = ytilevec(2,:);
for xxyy = 1:nxtile*nytile
    [indytile,indxtile]=ind2sub([nytile,nxtile],xxyy);
    tmpImg{xxyy} = reshape(ampEventNorm(ytileStart(indytile):ytileEnd(indytile), xtileStart(indxtile):xtileEnd(indxtile)),1,[]);
end

BCtr = zeros(nytile,nxtile); 
ADtr = zeros(nytile,nxtile);  
SRtr = zeros(nytile,nxtile);
AStr = zeros(nytile,nxtile);
NIAtr= zeros(nytile,nxtile);
GAtr = zeros(nytile,nxtile);
GMtr = zeros(nytile,nxtile);
GStr = zeros(nytile,nxtile);
G2Atr = zeros(nytile,nxtile);
G2Mtr = zeros(nytile,nxtile);
G2Str = zeros(nytile,nxtile);
indupdate={};

if gaussianid == 1
    cc       = bwconncomp((GMt<0),conn);
    numfun   = @(a) numel(a);
    numcomp  = cellfun(numfun,cc.PixelIdxList); 
    indlarge = find(numcomp>=nthresh);
    logging(qclog,sprintf('Tile Growing: in total %d patches',numel(indlarge)));
    if numel(indlarge)==0; return; end
    parfor ii = 1:numel(indlarge)
    %for ii = 1:numel(indlarge)
    %for ii = 118
        indg = cc.PixelIdxList{indlarge(ii)};
        tmpImgCell = tmpImg(indg);
        [tmpy,tmpx]=ind2sub([nytile,nxtile],indg);
        [ P,M ] = getStatG3( cell2mat(tmpImgCell) );
        %logging(qclog,sprintf('G1 Patch %d (Before): %5d tiles, mean=%5f, std=%5f',ii,numel(indg),G3p1(2),G3p1(3)));
        [JtileMulti,indall] = tilegrowingprobG1permsExpand(tmpImg,tmpx,tmpy,thresh,indg,[nytile,nxtile]);
        % The following was for numel(indg)>3000
        % But it still takes too long; better change the tile zie
        %JtileMulti = tilegrowingprobG1permslarge(tmpImgCell,tmpx,tmpy,thresh,indg,[nytile,nxtile]);
        nTilesLinked = sum(JtileMulti>0,1);
        nMaxGroup    = max(JtileMulti,[],1);
        [~,nMaxMode] = nanmode(JtileMulti,1,0);
        if sum(nMaxGroup)>0  %with at least one group
            [permsel,nsubpatch]=selectPerm(JtileMulti,nTilesLinked,nMaxGroup,nMaxMode);
            indsub = find(permsel==1);
            [ P,M ] = getStatG3( cell2mat(tmpImg(indall(indsub))) );
            indg0 = indg;
            indg  = indall(indsub);
            [ G3p1s,G3p2s,~,BCs,AD1s,~,SR1s,~,AS1s,~,NIA1s,~,indsubs ] = expandresult( tmpImg, indall, permsel, nsubpatch ); 
    	    BCsrc{ii} = BCs;
    	    ADsrc{ii} = AD1s;
    	    SRsrc{ii} = SR1s;
    	    ASsrc{ii} = AS1s;
    	    NIAsrc{ii}= NIA1s;
            GAsrc{ii} = G3p1s;
    	    GMsrc{ii} = G3p1s;
    	    GSsrc{ii} = G3p1s;
            G2Asrc{ii} = G3p2s;
    	    G2Msrc{ii} = G3p2s;
    	    G2Ssrc{ii} = G3p2s;
            indupdates{ii}=indsubs;
        else
    	    BCsrc{ii} = {M.BC};
    	    ADsrc{ii} = {M.AD1};
    	    SRsrc{ii} = {M.SR1};
    	    ASsrc{ii} = {M.AS1};
    	    NIAsrc{ii}= {M.NIA1};
            GAsrc{ii} = {P.G3p1};
    	    GMsrc{ii} = {P.G3p1};
    	    GSsrc{ii} = {P.G3p1};
            G2Asrc{ii} = {P.G3p2};
    	    G2Msrc{ii} = {P.G3p2};
    	    G2Ssrc{ii} = {P.G3p2};
            indupdates{ii}={indg};
        end    
    end
    [BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str] = updateParm(BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str,...
    BCsrc,ADsrc,SRsrc,ASsrc,NIAsrc,GAsrc,GMsrc,GSsrc,G2Asrc,G2Msrc,G2Ssrc,indupdates,nthresh,nxtile,nytile,'sub');
elseif gaussianid == 3
    cc       = bwconncomp((GMt>0),conn);
    numfun   = @(a) numel(a);
    numcomp  = cellfun(numfun,cc.PixelIdxList); 
    indlarge = find(numcomp>=nthresh);
    logging(qclog,sprintf('Tile Growing: in total %d patches',numel(indlarge)))
    if numel(indlarge)==0; return; end
    parfor ii = 1:numel(indlarge)
    %for ii = 1:numel(indlarge)
    %parfor ii = 1:10
    %for ii=8
        indg = cc.PixelIdxList{indlarge(ii)};
        tmpImgCell = tmpImg(indg);
        [tmpy,tmpx]=ind2sub([nytile,nxtile],indg);
        [ P,M ] = getStatG3( cell2mat(tmpImgCell) );
        %logging(qclog,sprintf('G3 Patch %d (Before): %5d tiles, mean=%5f, std=%5f',ii,numel(indg),G3p3(2),G3p3(3)));
        [JtileMulti,indall] = tilegrowingprobG3permsExpand(tmpImg,tmpx,tmpy,thresh,indg,[nytile,nxtile]);
        % The following was for numel(indg)>3000
        % But it still takes too long; better change the tile zie
        %JtileMulti = tilegrowingprobG3permslarge(tmpImgCell,tmpx,tmpy,thresh,indg,[nytile,nxtile]);
        nTilesLinked = sum(JtileMulti>0,1);
        nMaxGroup    = max(JtileMulti,[],1);
        [~,nMaxMode] = nanmode(JtileMulti,1,0);
        if sum(nMaxGroup)>0 %with at least one group
            [permsel,nsubpatch]=selectPerm(JtileMulti,nTilesLinked,nMaxGroup,nMaxMode);
            indsub = find(permsel==1);
            [ P,M ] = getStatG3( cell2mat(tmpImg(indall(indsub))) );
            indg0 = indg;
            indg  = indall(indsub);
            [ ~,G3p2s,G3p3s,BCs,~,AD3s,~,SR3s,~,AS3s,~,NIA3s,indsubs ] = expandresult( tmpImg, indall, permsel, nsubpatch ); 
    	    BCsrc{ii} = BCs;
    	    ADsrc{ii} = AD3s;
    	    SRsrc{ii} = SR3s;
    	    ASsrc{ii} = AS3s;
    	    NIAsrc{ii}= NIA3s;
    	    GAsrc{ii} = G3p3s;
    	    GMsrc{ii} = G3p3s;
    	    GSsrc{ii} = G3p3s;
    	    G2Asrc{ii} = G3p2s;
    	    G2Msrc{ii} = G3p2s;
    	    G2Ssrc{ii} = G3p2s;
            indupdates{ii}=indsubs;
        elseif sum(nMaxGroup)==0 %no consistant tiles are obtained
    	    BCsrc{ii} = {M.BC};
    	    ADsrc{ii} = {M.AD3};
    	    SRsrc{ii} = {M.SR3};
    	    ASsrc{ii} = {M.AS3};
    	    NIAsrc{ii}= {M.NIA3};
    	    GAsrc{ii} = {P.G3p3};
    	    GMsrc{ii} = {P.G3p3};
    	    GSsrc{ii} = {P.G3p3};
    	    G2Asrc{ii} = {P.G3p2};
    	    G2Msrc{ii} = {P.G3p2};
    	    G2Ssrc{ii} = {P.G3p2};
            indupdates{ii}={indg};
        end    
        %logging(qclog,sprintf('G3 Patch %d (After):  %5d tiles, mean=%5f, std=%5f',ii,numel(indg),G3p3(2),G3p3(3)));
    end % parfor
    % for sub-splits
    [BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str] = updateParm(BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str,...
                            BCsrc,ADsrc,SRsrc,ASsrc,NIAsrc,GAsrc,GMsrc,GSsrc,G2Asrc,G2Msrc,G2Ssrc,indupdates,nthresh,nxtile,nytile,'sub');
else
    error('gaussianid can only be 1 (1st Gaussain) or 3 (3rd Gaussian).')
end

end % main function

function [G3p1s,G3p2s,G3p3s,BCs,AD1s,AD3s,SR1s,SR3s,AS1s,AS3s,NIA1s,NIA3s,indsubs]=expandresult( tmpImg, indg, permsel, nsub )
% Check how many sub-patches in each patch

    for n=1:nsub
        indsub = find(permsel==n);
        %n=k-1;
        [ P,M ] = getStatG3( cell2mat(tmpImg(indg(indsub))) );
        G3p1s{n}=P.G3p1;
        G3p2s{n}=P.G3p2;
        G3p3s{n}=P.G3p3;
        BCs{n} =M.BC;
        AD1s{n}=M.AD1;
        AD3s{n}=M.AD3;
        SR1s{n}=M.SR1;
        SR3s{n}=M.SR3;
        AS1s{n}=M.AS1;
        AS3s{n}=M.AS3;
        NIA1s{n}=M.NIA1;
        NIA3s{n}=M.NIA3;
        indsubs{n}=indg(indsub);
    end

end

function [BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str] = updateParm(BCtr,ADtr,SRtr,AStr,NIAtr,GAtr,GMtr,GStr,G2Atr,G2Mtr,G2Str,...
                                        BCrc,ADrc,SRrc,ASrc,NIArc,GArc,GMrc,GSrc,G2Arc,G2Mrc,G2Src,indupdate,nthresh,nxtile,nytile,mode)
% Update the growing results
% mode=orig: Without subpatch
% mode=sub:  With subpatches

   numfun = @(a) numel(a);
   switch mode
        case 'orig' 
            numcomp  = cellfun(numfun,indupdate); 
            indlarge = find(numcomp>=nthresh);
            for ii = 1:numel(indlarge)
            %for ii = 1
                indg = indupdate{indlarge(ii)};
            	BCtr(indg) = BCrc{indlarge(ii)}; 
            	ADtr(indg) = ADrc{indlarge(ii)}; 
            	SRtr(indg) = SRrc{indlarge(ii)}; 
            	AStr(indg) = ASrc{indlarge(ii)}; 
            	NIAtr(indg)= NIArc{indlarge(ii)};
            	GAtr(indg) = GArc{indlarge(ii)}; 
            	GMtr(indg) = GMrc{indlarge(ii)}; 
            	GStr(indg) = GSrc{indlarge(ii)};
            	G2Atr(indg) = G2Arc{indlarge(ii)}; 
            	G2Mtr(indg) = G2Mrc{indlarge(ii)}; 
            	G2Str(indg) = G2Src{indlarge(ii)};
            end
        case 'sub'
            nsubsp   = cellfun(numfun,indupdate); 
            indsubsp = find( nsubsp > 0 );
            for jj = 1:numel(indsubsp)
                indj = indsubsp(jj);
                indupdatej = indupdate{indj};
                BCrcj = BCrc{indj};
                ADrcj = ADrc{indj};
                SRrcj = SRrc{indj};
                ASrcj = ASrc{indj};
                NIArcj = NIArc{indj};
                GArcj = GArc{indj};
                GMrcj = GMrc{indj};
                GSrcj = GSrc{indj};
                G2Arcj = G2Arc{indj};
                G2Mrcj = G2Mrc{indj};
                G2Srcj = G2Src{indj};
                numcomp  = cellfun(numfun,indupdatej); 
                indlarge = find(numcomp>=nthresh);
                for ii = 1:numel(indlarge)
                    indg = indupdatej{indlarge(ii)};
                	BCtr(indg) = BCrcj{indlarge(ii)}; 
                	ADtr(indg) = ADrcj{indlarge(ii)}; 
                	SRtr(indg) = SRrcj{indlarge(ii)}; 
                	AStr(indg) = ASrcj{indlarge(ii)}; 
                	NIAtr(indg)= NIArcj{indlarge(ii)};
                	GAtr(indg) = GArcj{indlarge(ii)}(1); 
                	GMtr(indg) = GMrcj{indlarge(ii)}(2); 
                	GStr(indg) = GSrcj{indlarge(ii)}(3); 
                	G2Atr(indg) = G2Arcj{indlarge(ii)}(1); 
                	G2Mtr(indg) = G2Mrcj{indlarge(ii)}(2); 
                	G2Str(indg) = G2Srcj{indlarge(ii)}(3); 
                end
            end
    end %switch

end

function [permsel,nsubpatch]=selectPerm(JtileMulti,nTilesLinked,nMaxGroup,nMaxMode)
% Select the best permuted result

     % find the perm set with max. linkage
     indMaxLinked = find( nTilesLinked==max(nTilesLinked) );
     % find the min patch groups among the mx. linkage set
     indMinGroup  = find( nMaxGroup(indMaxLinked) == min(nMaxGroup(indMaxLinked)) );
     indsel  = indMaxLinked(indMinGroup);
     if numel(indsel)>1
         % find the group with the largest number of linked tiles
         [~,indtmp]=max(nMaxMode(indsel)); 
         indsel=indsel(indtmp);
     end
     nsubpatch = nMaxGroup(indsel);
     permsel = JtileMulti(:,indsel);

end
