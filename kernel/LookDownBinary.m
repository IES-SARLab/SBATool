function [B] = LookDownBinary(A,r,varargin);
%
% B = LookDownBinary(A,r1,[r2,thresh])
% r1 = the lookdown factor in first dimension of A (num of rows)
% r2 = the lookdown factor in the second dimension of A (num of columns)
%      the default is r1 
% thresh = return 1 for the downlooked pixel if the number of True (1)
%          pixels is above this thresh percentage (default 0.5)
%
% Nina Lin @ 2020

r = repmat(r,1,2);  % replicate r matrix into big matrix of 1 row and 2 colume consisting of r tiles
                    % in this case a new matrix of [r r] is going to be
                    % made (r is a scalar)
method = 'max';
thresh = 0.5;
if numel(varargin)>=1
  r(2) = varargin{1};
end
if numel(varargin)>=2
  thresh = varargin{2};
end 

B = zeros(floor(size(A,1)/r(1)),floor(size(A,2)/r(2)));

for i=1:floor(size(A,1)/r(1))
  for j=1:floor(size(A,2)/r(2))
      B(i,j) = numel(find(A(...
	  1+(i-1)*r(1):i*r(1),...
	  1+(j-1)*r(2):j*r(2))==1)) >= ...
      numel(A(1+(i-1)*r(1):i*r(1),1+(j-1)*r(2):j*r(2)))*thresh;
  end
end


return
