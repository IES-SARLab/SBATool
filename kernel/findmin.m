function ind=findmin(X,xt)
%function ind=findmin(X,xt)
% find the index in X whose value is closest to xt
% and is the smallest value possible

    inds = find( abs(X-xt)==min(abs(X-xt)) );
    Xf   = min(X(inds));
    ind  = find( X==Xf );

end
