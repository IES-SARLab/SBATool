function [ G,BC,c1,c2,fh ] = getStatG1( img, varargin ) 
% function [ G,BC,c1,c2,fh ] = getStatG1( img, (pltfig, debug, method) ) 
% method: 'equal_area' or 'half_rise'

    if numel(varargin)>0; pltfig = varargin{1}; else; pltfig = 0; end
    if numel(varargin)>1; debug = varargin{2}; else; debug  = 0; end
    if numel(varargin)>2; method = varargin{3}; else; method = 'rise'; end

    % get the initial guesses from script
    setGaussianInitialsSingle;
    img = img(:);
    [G,~,h,modh,fh,hs]=gaussianFit1(m,s,mb,sb,img,xvec,'none',pltfig,debug);
    modh(modh<0)=0;
%    modh = modh/sum(modh);
    hdiff = hs - modh;
    hdiff( (xvec>=-1.5)&(xvec<=1.5) )=0;
    hdiff(hdiff<0)=0;    

    % Bhattacharyya coefficient (how well is the fit; 1 for the best)
    indBC = find( xvec>-3 & xvec<3 );
    %BC = sum(sqrt(hs(indBC)/sum(hs(indBC))).*sqrt(modh(indBC)/sum(modh(indBC))));
    BC = 1-sum(abs((hs(indBC)/sum(hs(indBC))) - (modh(indBC)/sum(modh(indBC)))));

    switch method

        case 'equal_area'     
            % get the suggested cutoff for lower end
            hdiff1c =  cumsum(flipud(hdiff(xvec<0)));
            modh1c = flipud(cumsum(modh(xvec<0)));
            dist1  = abs(hdiff1c - modh1c);
            x1 = fliplr(xvec(xvec<0));
            ind1 = find( dist1 == min(dist1) );
            c1 = x1(ind1(1));
        
            % get the suggested cutoff for lower end
            hdiff2c = cumsum(hdiff(xvec>0));
            modh2c = flipud(cumsum(flipud(modh(xvec>0))));
            dist2  = abs(hdiff2c - modh2c);
            x2 = xvec(xvec>0);
            ind2 = find( dist2 == min(dist2) );
            c2 = x2(ind2(1));

        otherwise %rise

            hdiff1 = flipud(hdiff(xvec<0));
            x1 = fliplr(xvec(xvec<0));
            ind1 = find( hdiff1>=max(hdiff1)/3,1,'first' );
            c1 = x1(ind1);

            hdiff2 = hdiff(xvec>0);
            x2 = xvec(xvec>0);
            ind2 = find( hdiff2>=max(hdiff2)/3,1,'first' );
            c2 = x2(ind2);

    end

end
