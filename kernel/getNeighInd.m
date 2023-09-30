function [xn,yn] = getNeighInd(x0,y0,ms,ncirc)
%function [xn,yn] = getNeighInd(x0,y0,ms,ncirc)
%
% x0 = x vector
% y0 = y vector
% msize = matrix size, obtained by size(A)
% ncirc = number of circles around the input points

neigb=[-1 0; 1 0; 0 -1;0 1;-1 -1; -1 1;1 1;1 -1];
x0 = reshape(x0,1,numel(x0));
y0 = reshape(y0,1,numel(y0));
xy0 = [x0' y0'];
xn = [];
yn = [];

for ii=1:ncirc
    x1 = repmat(neigb(:,1),numel(x0),1) + reshape(repmat(x0,size(neigb,1),1),[],1);
    y1 = repmat(neigb(:,2),numel(y0),1) + reshape(repmat(y0,size(neigb,1),1),[],1);
    ins = (x1>=1)&(y1>=1)&(x1<=ms(2))&(y1<=ms(1));
    x1 = x1(ins);
    y1 = y1(ins);
    xy  = unique([x1 y1],'row');
    xy1 = setdiff(xy,xy0,'row');
    xn = [xn;xy1(:,1)];
    yn = [yn;xy1(:,2)];
    xy0 = [xy0;xy1];
    x0 = xy1(:,1)'; 
    y0 = xy1(:,2)';
end
