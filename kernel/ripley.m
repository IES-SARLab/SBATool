function [Kr,K] = ripley(I,t)
%function [Kr,K] = ripley(I,t)
% Kr: RIpley's K normalized by the theoretical complete spatial randomness value
% K : Ripley's K
%
% Ref: Dixon, 2002
% Nina @ 2020

[xx,yy]=meshgrid(1:size(I,2),1:size(I,1));

ind = find(I==1);
xvec = xx(ind);
yvec = yy(ind);
nnc = {};

parfor ii = 1:numel(ind)
%for ii = 1:numel(ind)
    d  = (xvec-xx(ind(ii))).^2+(yvec-yy(ind(ii))).^2; 
    ind0 = find(d==0);
    nnc{ii} = numel( find(d<(t^2)) ); 
end

nn = nansum(cell2mat(nnc));
A = numel(I);
K = A*nn./(numel(ind)^2);
Kr = K./(pi*(t.^2));
