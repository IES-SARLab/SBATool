function [B] = LookDown(A,r,varargin);
%
% B = LookDown(A,r1,[r2,method])
% r1 = the lookdown factor in first dimension of A (num of rows)
% r2 = the lookdown factor in the second dimension of A (num of columns)
%      the default is r1 
% method = either 'mean' or 'median', the default is 'mean'
%
%
% EA Hetland - Caltech 2007
% ehetland@alum.mit.edu
%
% part of package in development, please do not distribute without
% permission from EA Hetland, M Simons, or P Muse
%

r = repmat(r,1,2);  % replicate r matrix into big matrix of 1 row and 2 colume consisting of r tiles
                    % in this case a new matrix of [r r] is going to be
                    % made (r is a scalar)
method = 'mean';
if length(varargin)>=1
  r(2) = varargin{1};
end
if length(varargin)>=2
  method = varargin{2};
end

switch method
 case 'mean'
  UseMean = 1;
 otherwise
  UseMean = 0;
end

B = zeros(floor(size(A,1)/r(1)),floor(size(A,2)/r(2)));

for i=1:floor(size(A,1)/r(1))
  for j=1:floor(size(A,2)/r(2))
    if UseMean
      B(i,j) = mean(mean(A(...
	  1+(i-1)*r(1):i*r(1),...
	  1+(j-1)*r(2):j*r(2))));
    else
      B(i,j) = median(mean(A(...
	  1+(i-1)*r(1):i*r(1),...
	  1+(j-1)*r(2):j*r(2))));
    end
  end
end


return
