function [JtileMultiPerms,indall] = tilegrowingprobG3permsExpand(tmpImg,tmpxtilevec,tmpytilevec,thresh,indg,fulltsizes)
%function JtileMultiPerms = tilegrowingprobG3perms(tmpImg,xtilevec,ytilevec,thresh,indg)
% This function performs "region growing" in an image from a specified
% J : logical output image of region
% G3Mt: tile with growth region mean for 3rd Gaussian
% G3St: tile with growth region std for 3rd Gaussian
% I : input image 
% thresh : [AD, BC, SR] thresholds
% tsize: tile size
%
% Nina Lin @ April 2020

% Neighbor locations (footprint)
neigb=[-1 0; 1 0; 0 -1;0 1;-1 -1; -1 1;1 1;1 -1];
%neigb=[-1 0; 1 0; 0 -1;0 1];

% Gaussian Fit Flow
Gtype = 3;  % Gtype=3 now has better accuracy
   	     
%nxtile = max(tmpxtilevec);
%nytile = max(tmpytilevec);
nxtile = fulltsizes(2);
nytile = fulltsizes(1);
seqg   = 1:numel(indg);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% indg = 75 73 5 3  (index on full Img cell)
% seqg = 1  2  3 4  (index on tmpImg cell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if numel(indg)<=10
    indgcirc = indg;
    %JtileMultiPerms=zeros(numel(indg),numel(indgcirc));  %for different starting orders
    [xnall,ynall] = getNeighInd(tmpxtilevec,tmpytilevec,fulltsizes,1); %about 100
    indall = [indg;sub2ind(fulltsizes,ynall,xnall)];
    JtileMultiPerms=zeros(numel(indall),numel(indgcirc));  %for different starting orders; set to max 100 neighbors
elseif (numel(indg)>10) && (numel(indg)<=100)
    %display(sprintf('WARNING: large patch of size %d, reduce to 9 seed points',numel(indg))); 
    [pxt,pyt] = findPoint(tmpxtilevec,tmpytilevec,'all'); 
    indgcirc = unique(sub2ind(fulltsizes,pyt,pxt));
    %JtileMultiPerms=zeros(numel(indg),numel(indgcirc));
    [xnall,ynall] = getNeighInd(tmpxtilevec,tmpytilevec,fulltsizes,1); %about 100 
    indall = [indg;sub2ind(fulltsizes,ynall,xnall)];
    JtileMultiPerms=zeros(numel(indall),numel(indgcirc)); 
elseif (numel(indg)>100) && (numel(indg)<=3000)
    %display(sprintf('WARNING: large patch of size %d, reduce to 3 seed points',numel(indg))); 
    [pxt,pyt] = findPoint(tmpxtilevec,tmpytilevec,'all'); 
    [~,iu] = unique(sub2ind(fulltsizes,pyt,pxt));
    pxt = pxt(iu); pyt=pyt(iu);
    %indrand = randperm(9,3);
    indrand = 1:3;
    pxt = pxt(indrand); pyt = pyt(indrand);
    indgcirc = sub2ind(fulltsizes,pyt,pxt);
    indall = indg;
    JtileMultiPerms=zeros(numel(indg),numel(indgcirc));
elseif numel(indg)>3000
    error(sprintf('ERROR: number of patch %d (>3000); need to revise threshG3',numel(indg))); 
end

maxt = size(JtileMultiPerms,1);

%%% Loop through the chosen seed point
for cnt = 1:numel(indgcirc)
%for cnt = 2

    %%% To start from each seed point
    seq = circshift(seqg,1-find(indg==indgcirc(cnt)));
    %Jtile=zeros(numel(seq),1); %to check if a tile is touched (1=yes; 0=no)
    %JtileMulti=zeros(numel(seq),1);  %for regions with more than 1 tile
    Jtile=zeros(maxt,1); %to check if a tile is touched (1=yes; 0=no)
    JtileMulti=zeros(maxt,1);  %for regions with more than 1 tile

    growthID = 2;
    multiID  = 1;

    %%% Loop through all the points in current permuted set
    for kk  = 1:numel(seq)
    %for xxyy = 1:50
        %if xxyy==3; keyboard; end
        if Jtile(seq(kk))>0 
            continue; %skip when Jtile value = 1 or 2
        else 
            Jtile(seq(kk))=1; 
        end
        indytile = tmpytilevec(seq(kk));
        indxtile = tmpxtilevec(seq(kk)); 
    
        seedImg = tmpImg{indg(seq(kk))};
        %try    
       	   [P,M] = getStatG3( seedImg, 0, 0, Gtype ); 
           G3M0 = P.G3p3(2);
           G3S0 = P.G3p3(3);
           BC0  = M.BC;
           AD0  = M.AD3;
           SR0  = M.SR3;
           AS0  = M.AS3;
           NIA0 = M.NIA3;
       	   
       	   % start to track the tiles being touched 
       	   reg_size = 1; % Number of tiles in region
           neg_list = [];
       	   % Start regiogrowing with the given criteria 
       	   sumImg = seedImg; 
       	   while ( ( (AD0>=thresh(1))&(G3M0>thresh(5)) ) && ...
                       ( BC0>=thresh(2)   )  && ...
                       ( SR0>=thresh(3)   )  && ...
                       ( AS0>thresh(4) )  && ...
                       ( NIA0>thresh(6)) ) && ... 
                     (reg_size<numel(Jtile))
       	      
               %for nn=1:numel(indxtile);display(sprintf('%d %d %d %d',cnt,seq(kk),indxtile(nn),indytile(nn))); end
       	       % Check if new neighbour is inside or outside the image (Queen)
       	       xn = repmat(neigb(:,1),numel(indxtile),1) + reshape(repmat(indxtile',size(neigb,1),1),[],1);
       	       yn = repmat(neigb(:,2),numel(indytile),1) + reshape(repmat(indytile',size(neigb,1),1),[],1);
       	       ins = (xn>=1)&(yn>=1)&(xn<=nxtile)&(yn<=nytile);
               xn = xn(ins);
               yn = yn(ins);
               indn = sub2ind(fulltsizes,yn,xn);
       	       [~,ia,ib] = intersect(indall,indn);
       	       ins = (Jtile(ia)==0);
               if sum(ins)>0
                   xn  = xn(ib(ins));
                   yn  = yn(ib(ins));
                   seqt = ia(ins);
                   Jtile(ia(ins))=1;
                   %display(sprintf('Pert %d, grow %d, #Neigb %d',seq(1),reg_size,numel(seqt)));
                   % Add new neighbors pixels
                   clear G3p3 BC AD SR AS NIA
                   parfor j=1:numel(seqt)
                   %for j=1:numel(seqt)
                       [P,M] = getStatG3( [sumImg tmpImg{indall(seqt(j))}], 0, 0, Gtype ); 
                       G3p3{j} = P.G3p3;
                       BC(j) = M.BC;
                       AD(j) = M.AD3;
                       SR(j) = M.SR3;
                       AS(j) = M.AS3;
                       NIA(j) = M.NIA3; 
                   end
                   G3p3 = cell2mat(G3p3');
                   % Add neighbor if inside and not already part of the segmented area
                   neg_list = [neg_list; ...
                               xn(:) yn(:) seqt(:) AD(:) BC(:) SR(:) AS(:) NIA(:) G3p3(:,2) G3p3(:,3) indall(seqt(:))];
               end
       	       if numel(neg_list)==0; break; end
 
       	       % Add pixel that matches all 3 thresholds and has the largest AD
       	       indQualify = find( ( (neg_list(:,4)>thresh(1))&(neg_list(:,9)>thresh(5))) & ...
       	                          (neg_list(:,5)>thresh(2)) & ...
       	                          (neg_list(:,6)>thresh(3)) & ...
                                  (neg_list(:,7)>thresh(4)) & ...
                                  (neg_list(:,8)>thresh(6)) );
                                  %(neg_list(:,9)>2.0));
       	       if numel(indQualify)==0; break; end
    
       	       % Add the qualified tile(s) into region
       	       Jtile(seq(kk))=growthID; 
       	       Jtile(neg_list(indQualify,3))=growthID;
       	       sumImg = [sumImg cell2mat(tmpImg(neg_list(indQualify,11)))];  % combined statistics of the seed tile and a neighbor tile

               [P,M] = getStatG3( sumImg, 0, 0, Gtype ); 
               G3M0 = P.G3p3(2);
               G3S0 = P.G3p3(3);
               BC0  = M.BC;
               AD0  = M.AD3;
               SR0  = M.SR3;
               AS0  = M.AS3;
               NIA0 = M.NIA3;
       	       reg_size=sum((Jtile>0));
       	       
       	       % Save the x and y tile index (for the neighbour add proccess)
       	       indxtile = neg_list(indQualify,1); 
       	       indytile = neg_list(indQualify,2);
               neg_list = removerows(neg_list,'ind',indQualify);
       	   end % end of one growth round (end of while)
       	%catch ME
       	%    disp(sprintf('Capture error at tile x=%d, y=%d, j=%d',indxtile,indytile,kk));
       	%end

        %to separate different sub-patches
        if numel( find(Jtile==growthID) )>1
            %display(sprintf('Identifying continuous region %d',multiID));
            JtileMulti(Jtile==growthID) = multiID;
            growthID = growthID + 1;
            multiID  = multiID + 1;
        end 
    end % end of growth in each permutation (per kk)

    JtileMultiPerms(:,cnt)=JtileMulti;  %for different starting orders
end % end of all permutation (per cnt)

end

