function [FPMhigh,varargout] = getFPMhigh(ampEventNorm,pcuthigh,G3Ahat,G3Mhat,G3Shat,G2Ahat,varargin)
%function [FPMhigh,(pFhigh)] = getFPMhigh(ampEventNorm,pcuthigh,G3Mhat,G3Shat,(bsize))

if numel(G3Ahat) == 1
    G3Ahat = ampEventNorm*0+G3Ahat;
end
if numel(G3Mhat) == 1
    G3Mhat = ampEventNorm*0+G3Mhat;
end
if numel(G3Shat) == 1
    G3Shat = ampEventNorm*0+G3Shat;
end
if numel(G2Ahat) == 1
    G2Ahat = ampEventNorm*0+G2Ahat;
end

indm3 = find(G3Mhat~=0);
bsize = 2000;

%noninformative prior
%pf  = 0.5;
%pnf = 1-pf; 
%mean and std of normalized time-series
mnf = 0;
snf = 1;

if numel(varargin)>0; G2Mhat=varargin{1}; else; G2Mhat=G2Ahat*0+mnf; end
if numel(varargin)>1; G2Shat=varargin{2}; else; G2Shat=G2Ahat*0+snf; end
bstart = 1:bsize:numel(ampEventNorm);
bend   = [bstart(2:end)-1 numel(ampEventNorm)];

%%% Double-bounce flood probability and FPM
if numel(indm3)>0
    for ii = 1:numel(bstart)
      indtmp = bstart(ii):bend(ii);
      xc{ii} = ampEventNorm(indtmp);
      pf{ii}  = G3Ahat(indtmp)./(G2Ahat(indtmp)+G3Ahat(indtmp));
      pnf{ii} = G2Ahat(indtmp)./(G2Ahat(indtmp)+G3Ahat(indtmp));
      mfc{ii} = G3Mhat(indtmp);
      sfc{ii} = G3Shat(indtmp);
      mnfc{ii} = G2Mhat(indtmp);
      snfc{ii} = G2Shat(indtmp);
    end
    parfor jj = 1:numel(bstart)
    %for jj = 1:numel(bstart)
       pxF  = pf{jj}.*exp( (-(xc{jj}-mfc{jj}).^2)./(2*sfc{jj}.^2) )./(4*sqrt(2*pi)*sfc{jj});
       pxNF = pnf{jj}.*exp( (-(xc{jj}-mnfc{jj}).^2)./(2*snfc{jj}.^2) )./(4*sqrt(2*pi)*snfc{jj});
       px   = pxF + pxNF;
       mask = (xc{jj}>=0.5);
       pFxc{jj} = (pxF./px).*mask;
       pFxc{jj}(isnan(xc{jj})) = 0;
    end
    pFhigh = reshape(cell2mat(pFxc),size(ampEventNorm,1),size(ampEventNorm,2));
    %deal with extreme values
    pFhigh(ampEventNorm > nanmin(ampEventNorm(pFhigh==nanmax(pFhigh(:)))))=1;
    pFhigh(isnan(pFhigh) & ampEventNorm<0 ) = 0;
    %deal with negative values
    %display('Done with pFhigh');
    FPMhigh = (pFhigh>=pcuthigh);
else
    pFhigh = zeros(size(G3Mhat));
    FPMhigh = zeros(size(G3Mhat));
end
    
%%% Maximun flood probability
%pFboth  = max(pFlow, pFhigh);
%FPMboth = FPMlow*-1 + FPMhigh;

varargout{1} = pFhigh;

end
