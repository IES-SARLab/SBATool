function [xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(I,tsize,shift)
%function [xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(I or Isizes,tsize,shift)

if numel(I)>2; Isizes = size(I); else; Isizes = I; end
if numel(shift) == 1
    shiftx = shift;
    shifty = shift;
else
    shiftx = shift(1);
    shifty = shift(2);
end
shiftpxlx = round(shiftx*tsize);
shiftpxly = round(shifty*tsize);
if shiftpxlx == tsize; shiftpxlx = 0; end
if shiftpxly == tsize; shiftpxly = 0; end
xtileStart  = [(shiftpxlx+1):tsize:Isizes(2)]; %get the xtile list
xtileStart(1) = 1;
if ((Isizes(2)-xtileStart(end))+1)~=tsize, xtileStart = xtileStart(1:end-1); end
xtileEnd    = [xtileStart(2:end)-1 Isizes(2)];
ytileStart  = [(shiftpxly+1):tsize:Isizes(1)]; %get the ytile list
ytileStart(1) = 1;
if ((Isizes(1)-ytileStart(end))+1)~=tsize, ytileStart = ytileStart(1:end-1); end
ytileEnd    = [ytileStart(2:end)-1 Isizes(1)];

