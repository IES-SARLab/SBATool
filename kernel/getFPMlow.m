function [FPMlow,varargout] = getFPMlow(ampEventNorm,pcutlow,G1Ahat,G1Mhat,G1Shat,G2Ahat,varargin)
%function [FPMlow,(pFlow)] = getFPMlow(ampEventNorm,pcutlow,G1Ahat,G1Mhat,G1Shat,G2Ahat,(bsize))

if numel(G1Ahat) == 1
    G1Ahat = ampEventNorm*0+G1Ahat;
end
if numel(G1Mhat) == 1
    G1Mhat = ampEventNorm*0+G1Mhat;
end
if numel(G1Shat) == 1
    G1Shat = ampEventNorm*0+G1Shat;
end
if numel(G2Ahat) == 1
    G2Ahat = ampEventNorm*0+G2Ahat;
end

indm1 = find(G1Mhat~=0);
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

if numel(indm1)>0
    
    for ii = 1:numel(bstart)
      indtmp = bstart(ii):bend(ii);
      xc{ii} = ampEventNorm(indtmp);
      pf{ii}  = G1Ahat(indtmp)./(G2Ahat(indtmp)+G1Ahat(indtmp));
      pnf{ii} = G2Ahat(indtmp)./(G2Ahat(indtmp)+G1Ahat(indtmp));
      mfc{ii} = G1Mhat(indtmp);
      sfc{ii} = G1Shat(indtmp);
      mnfc{ii} = G2Mhat(indtmp);
      snfc{ii} = G2Shat(indtmp);
    end
    parfor ii = 1:numel(bstart)
    %for ii = 1:numel(bstart)
      pxF  = pf{ii}.*exp( (-(xc{ii}-mfc{ii}).^2)./(2*sfc{ii}.^2) )./(4*sqrt(2*pi)*sfc{ii});
      pxNF = pnf{ii}.*exp( (-(xc{ii}-mnfc{ii}).^2)./(2*snfc{ii}.^2) )./(4*sqrt(2*pi)*snfc{ii});
      px   = pxF + pxNF;
      mask = (xc{ii}<=-0.5);
      pFxc{ii} = (pxF./px).*mask;
      pFxc{ii}(isnan(xc{ii})) = 0;
    end
    clear G1Mhat G1Shat mfc sfc
    pFlow = reshape(cell2mat(pFxc),size(ampEventNorm,1),size(ampEventNorm,2));
    %deal with extreme values
    pFlow(ampEventNorm < nanmax(ampEventNorm(pFlow==nanmax(pFlow(:)))))=1;
    pFlow(isnan(pFlow) & ampEventNorm>0 ) = 0;
    %quickly with low prob by assuming exponential
    %otherwise need to run getFPMlowfix (takes a long time)
    %pd = makedist('Exponential','mu',0.2);
    %r  = random(pd,numel(find(pFlow==0)),1);
    %r  = (r/max(r(:)))*0.5;
    %pFlow(find(pFlow==0)) = r;
    %display('Done with pFlow');
    FPMlow = (pFlow>=pcutlow);

else

    pFlow = zeros(size(G1Mhat));
    FPMlow = zeros(size(G1Mhat));

end
    
%%% Maximun flood probability
%pFboth  = max(pFlow, pFhigh);
%FPMboth = FPMlow*-1 + FPMhigh;

varargout{1} = pFlow;

end
