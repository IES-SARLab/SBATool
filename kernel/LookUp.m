function [B] = LookUp(A,r);
%
% B = LookUp(A,r)
% r  = the lookup factor, can be scalar or [rx ry]
%
% Nina @ 2021

if numel(r)==1
  r(2) = r(1);
end

B = zeros(size(A,1)*r(1),size(A,2)*r(2));

for ii=1:size(A,1)
  for jj=1:size(A,2)
      B(1+(ii-1)*r(1):ii*r(1),1+(jj-1)*r(2):jj*r(2))=A(ii,jj);
  end
end


return
