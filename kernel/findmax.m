function ind=findmax(X,xt)
%function ind=findmax(X,xt)
% find the index in X whose value is closest to xt
% and is the largest value possible

    inds = find( abs(X-xt)==min(abs(X-xt)) );
    Xf   = max(X(inds));
    ind  = find( X==Xf );

end
