function [mAD,mBC,mSR,mAS,mNIA,mGA1,mGM1,mGS1,varargout] = block2map(seg_map, set_stat, dimlist, imsize, thresh)
%function [mAD,mBC,mSR,mAS,mNIA,mGA1,mGM1,mGS1,(mGA2,mGM2,mGS2)] = block2map(seg_map, set_stat, dimlist, imsize, thresh)

% restore stats from blocks back to image
blockAD = repmat(0,size(seg_map));
blockBC = repmat(0,size(seg_map));
blockSR = repmat(0,size(seg_map));
blockAS = repmat(0,size(seg_map));
blockNIA = repmat(0,size(seg_map));
blockGA1 = repmat(0,size(seg_map));
blockGM1 = repmat(0,size(seg_map));
blockGS1 = repmat(0,size(seg_map));
blockGA2 = repmat(0,size(seg_map));
blockGM2 = repmat(0,size(seg_map));
blockGS2 = repmat(0,size(seg_map));

cnt = 1;
for idim = 1:numel(dimlist)
    dim = dimlist(idim);
    numblocks = length(find(seg_map==dim));
    if (numblocks > 0)
      AD = repmat(0,[dim dim numblocks]);
      BC = repmat(0,[dim dim numblocks]);
      SR = repmat(0,[dim dim numblocks]);
      AS = repmat(0,[dim dim numblocks]);
      NIA = repmat(0,[dim dim numblocks]);
      GA1 = repmat(0,[dim dim numblocks]);
      GM1 = repmat(0,[dim dim numblocks]);
      GS1 = repmat(0,[dim dim numblocks]);
      GA2 = repmat(0,[dim dim numblocks]);
      GM2 = repmat(0,[dim dim numblocks]);
      GS2 = repmat(0,[dim dim numblocks]);
      for jj=1:numblocks
        AD(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.AD;
        BC(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.BC;
        SR(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.SR;
        AS(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.AS;
        NIA(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.NIA;
        GA1(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.p1(1);
        GM1(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.p1(2);
        GS1(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.p1(3);
        GA2(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.p2(1);
        GM2(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.p2(2);
        GS2(:,:,jj) = zeros([dim dim])+set_stat{idim}{jj}.p2(3);
      end
      blockAD = qtsetblk(blockAD,seg_map,dim,AD);
      blockBC = qtsetblk(blockBC,seg_map,dim,BC);
      blockSR = qtsetblk(blockSR,seg_map,dim,SR);
      blockAS = qtsetblk(blockAS,seg_map,dim,AS);
      blockNIA = qtsetblk(blockNIA,seg_map,dim,NIA);
      blockGA1 = qtsetblk(blockGA1,seg_map,dim,GA1);
      blockGM1 = qtsetblk(blockGM1,seg_map,dim,GM1);
      blockGS1 = qtsetblk(blockGS1,seg_map,dim,GS1);
      blockGA2 = qtsetblk(blockGA2,seg_map,dim,GA2);
      blockGM2 = qtsetblk(blockGM2,seg_map,dim,GM2);
      blockGS2 = qtsetblk(blockGS2,seg_map,dim,GS2);
    end
end
mAD = blockAD(1:imsize(1),1:imsize(2));
mBC = blockBC(1:imsize(1),1:imsize(2));
mSR = blockSR(1:imsize(1),1:imsize(2));
mAS = blockAS(1:imsize(1),1:imsize(2));
mNIA = blockNIA(1:imsize(1),1:imsize(2));
mGA1 = blockGA1(1:imsize(1),1:imsize(2));
mGM1 = blockGM1(1:imsize(1),1:imsize(2));
mGS1 = blockGS1(1:imsize(1),1:imsize(2));
if nargout>8; varargout{1} = blockGA2(1:imsize(1),1:imsize(2)); end
if nargout>9; varargout{2} = blockGM2(1:imsize(1),1:imsize(2)); end
if nargout>10; varargout{3} = blockGS2(1:imsize(1),1:imsize(2)); end
