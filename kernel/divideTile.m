function [Tnew,xtilevecnew,ytilevecnew] = divideTile(T,xtilevec,ytilevec,ndv)
%function [Tnew,xtilevecnew,ytilevecnew] = divideTile(T,xtilevec,ytilevec,ndv)
%
% ndv: divide each tile into ndv tiles on one side
%      can be scalar or a vector for [ndvx ndvy]
%
% Nine @ 2021

if numel(ndv)==1
    ndvx = ndv;
    ndvy = ndv;
else
    ndvx = ndv(1);
    ndvy = ndv(2);
end

%%% divide xtilevec
xxs1 = xtilevec(1,:);
for ii = 1:(ndvx-1)
    xxs2(ii,:) = round(((ndvx-ii)*xtilevec(1,:)+ii*xtilevec(2,:))/ndvx);
end
xxe1 = xxs2(1,:)-1;
if ndvx >= 3
    for jj = 1:(ndvx-2)
        xxe2(jj,:) = xxs2(jj+1,:)-1;
    end
end
xxe2(ndvx-1,:) = xtilevec(2,:);
xstartvecnew = [xxs1; xxs2];
xendvecnew   = [xxe1; xxe2];
xtilevecnew  = [xstartvecnew(:) xendvecnew(:)]';

%%% divide ytilevec
yys1 = ytilevec(1,:);
for ii = 1:(ndvy-1)
    yys2(ii,:) = round(((ndvy-ii)*ytilevec(1,:)+ii*ytilevec(2,:))/ndvy);
end
yye1 = yys2(1,:)-1;
if ndvy >= 3
    for jj = 1:(ndvy-2)
        yye2(jj,:) = yys2(jj+1,:)-1;
    end
end
yye2(ndvy-1,:) = ytilevec(2,:);
ystartvecnew = [yys1; yys2];
yendvecnew   = [yye1; yye2];
ytilevecnew  = [ystartvecnew(:) yendvecnew(:)]';

%%% divide image
Tnew = LookUp(T,ndv);

return;
