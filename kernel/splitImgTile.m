function [xtilevec, ytilevec] = splitImgTile(I,splitsize,tsize,shift)
%function [xtilevec, ytilevec] = splitImgTile(I,splitsize,tsize,shift)
%
% order of xtilevec and ytilevec for the split images (if 2-by-2):
%
% xtilevec = [xtilevec1-1 xtilevec1-2]
% ytilevec = [ytilevec1-1 ytilevec2-1]
%
% split order (if split into 2-by-2)
%
% 1-1 | 1-2
%----------- 
% 2-1 | 2-2

[splitStartX,splitEndX,splitStartY,splitEndY]=splitImg(size(I),splitsize,'gridline');

xtoff = 0;
ytoff = 0;
for jj = 1:numel(splitStartX)
    ny = splitEndY(1)-splitStartY(1)+1;
    nx = splitEndX(jj)-splitStartX(jj)+1;
    [xtileStarttmp,xtileEndtmp] = xy2tile([ny nx],tsize,shift);
    xtileStartc{jj}=xtileStarttmp+xtoff;
    xtileEndc{jj}=xtileEndtmp+xtoff;
    xtoff = xtileEndc{jj}(end);
end
for ii = 1:numel(splitStartY)
    ny = splitEndY(ii)-splitStartY(ii)+1;
    nx = splitEndX(1)-splitStartX(1)+1;
    [~,~,ytileStarttmp,ytileEndtmp] = xy2tile([ny nx],tsize,shift);
    ytileStartc{ii}=ytileStarttmp+ytoff;
    ytileEndc{ii}=ytileEndtmp+ytoff;
    ytoff = ytileEndc{ii}(end);
end

xtileStart = cell2mat(xtileStartc);
ytileStart = cell2mat(ytileStartc);
xtileEnd = cell2mat(xtileEndc);
ytileEnd = cell2mat(ytileEndc);

xtilevec = [xtileStart; xtileEnd];
ytilevec = [ytileStart; ytileEnd];

