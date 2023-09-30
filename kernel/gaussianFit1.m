function [p1,BC,varargout] = gaussianFit1(m,s,mb,sb,data,x,mode,varargin)
% function [p1,BC,[h,modh,fh,modhsm]] = gaussianFit1(m,s,mb,sb,data,x,[pltfig,debug])
%
% 3-Guassian parameter fitting 
% Output
%   p1: 3 parameters for curve 1 (Amplitude, mean, std)
%   BC: Bhattacharyya coefficient (how well is the fit; 1 for the best)
%    h: data histogram [optional]
% modh: modeled histogram [optional]
%   fh: figure handle
%   hs: data histogram, smoothed [optional]
%
% Input
%   m0: initial mean
%   s0: initial std
%   mb: bounds for mean [lower upper]
%   sb: bounds for std [lower upper]
%   data: input data for fit 
%   x:  histogram bin centers
%   mode: weighting function.  can be: `center','left','right','xmedian','nmedian','invdata','none' 
%   pltfig: flag to plot the fitting result

if numel(varargin)>0; pltfig = varargin{1}; else; pltfig = 0; end
if numel(varargin)>1; debug  = varargin{2}; else; debug  = 0; end

%%%%% Round 0-A: checking zeros and nans %%%%%
indactual = intersect(find(data~=0),find(isfinite(data)));
if numel(indactual) < 2*numel(x) %hard-coded threshold to be twice the x-vec size
    p1 = [0 0 0];
    BC = 0;
    varargout{1} = x*0;
    varargout{2} = x*0;
    varargout{3} = NaN;
    varargout{4} = x*0;
    return;   
end

data = data(indactual);
data = data(find( data>min(x) & data<max(x) ) );
nbk = hist(data,x);
xbk = x(:); nbk = nbk(:);
nsmbk = medfilt1(nbk,7);
nbk = nbk./sum(nbk);
nsmbk = nsmbk./sum(nsmbk);
x = xbk;
n = nbk;
nsm = nsmbk;
n = n./sum(n);
nsm = nsm./sum(nsm);
thresh = 2;
x2 = x((x>-thresh)&(x<thresh));
n2 = n((x>-thresh)&(x<thresh));
nsm2 = nsm((x>-thresh)&(x<thresh));
nsm2 = nsm2/sum(nsm2);
curve1=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2));
curve1h=@(p)p(1)*exp((-0.5)*((x2-p(2)).^2)./(p(3)^2));
xmedian = nanmean(x( find( abs(n-median(n))==min(abs(n-median(n))) )));
switch mode
    case 'center'
        w=(1./(abs(x-m)+1e-7)).^2;
    case 'left'
        w=(1./(1:numel(x))).^2;
    case 'right'
        w=(1./(numel(x)-(1:numel(x))+1)).^2;
    case 'xmedian'
        w=(1./abs(x - xmedian)).^2;
    case 'nmedian'
        w=(1./(n-median(n))).^2;
    case 'invdata'
        w=(1./n).^.25;
    case 'none'
        w=ones(size(n));
        wh=ones(size(n2));
end
wrep = interp1(x(isfinite(w)),w(isfinite(w)),x(~isfinite(w)));
w(find(~isfinite(w))) = wrep;
obj1=@(p)100000*[w.*curve1(p)-w.*nsm].^2;
obj1n=@(p)abs([w.*curve1(p)/sum(curve1(p))-w.*nsm])*100000;
obj1nh=@(p)abs([wh.*curve1h(p)/sum(curve1h(p))-wh.*nsm2])*100000;
obj1n2=@(p)abs(1-sum(sqrt(curve1(p)/sum(curve1(p))).*sqrt(nsm)))*100000;
obj1n3=@(p)abs(1-sum(sqrt(curve1h(p)/sum(curve1h(p))).*sqrt(nsm2)))*100000;
obj1n3h=@(p)sum( abs( curve1h(p)/sum(curve1h(p))-nsm2 ))*100000;

%%%%% Round 0-B: checking zeros and nans %%%%%
if sum(n==0) > numel(n)*.8 %hard-coded threshold to be 80% of the histogram
    p1 = [0 0 0];
    BC = 0;
    varargout{1} = xbk*0;
    varargout{2} = xbk*0;
    varargout{3} = NaN;
    varargout{4} = xbk*0;
    return;   
end
tt= nsm(find((x>mb(1,1))&(x<mb(1,2))));
A1 = max(tt(tt>1e-7)); if numel(A1)==0; A1=0; end

% opt.FinDiffRelStep=eps^(1/2);
% opt.RelFooTol=1e-21;
% opt.InitDamping=1e-5;
opt.FinDiffRelStep=eps^(1/4);
opt.RelFooTol=1e-31;
opt.IncrTol = 1e-31;
opt.FactDamping=3.5;
opt.Broyden_updates='off';

if debug; 
p1 = [A1 m(1) s(1)];
keyboard; end

%%%% Round 1: check for single-mode
A1 = max(nsm2);
%xCurrent = round1fit1(A1(1),mean(data),std(data),...
%                      [mean(data)-std(data)*2 mean(data)+std(data)*2],...
%                      [std(data)*0.1  std(data)*3],obj1nh,opt);
xCurrent = round1fit1(A1(1),m(1),s(1),mb,sb,obj1n3h,opt);
p1 = xCurrent(1:3);    
modn = getmodn(xbk,p1);
modn = modn*max(nsm2)/max(modn);
BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
varargout{1} = nbk;
varargout{2} = modn;
varargout{3} = NaN;
varargout{4} = nsmbk;

if pltfig
    fh=plotcurve(xbk,nbk,nsmbk,p1);
    varargout{3} = fh;
end
end

function fh=plotcurve(x,n,nsm,p1)
    curve1=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2));
    fh=figure('rend','painters','pos',[1 1 1100 450]); 

    subplot(1,2,1)
    hold on; box on;
    fill([x(1)-.0001; x; x(end)+.0001],[0; n; 0],[.5 .5 .5],'EdgeColor',[.5 .5 .5])
    [modn,ng] = getmodn(x,p1);
    modn = modn*max(n)/max(modn);
    pht= plot(x,modn,'k-','LineWidth',2);
    BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
    title(sprintf('1 Gaussian, BC=%5.3f',BC))
    legend(pht,'Model');
    xlabel('\textbf{Normalized backscattering {\boldmath($$\hat{\sigma^0}$$)}}','Interpreter','Latex','FontWeight','bold','FontName','arial')
    ylabel('Number of pixels','FontWeight','bold')

    subplot(1,2,2)
    hold on; box on;
    fill([x(1)-.0001; x; x(end)+.0001],[0; nsm; 0],[.5 .5 .5],'EdgeColor',[.5 .5 .5])
    [modn,ng] = getmodn(x,p1);
    modn = modn./sum(modn);
    modn = modn*max(nsm)/max(modn); 
    pht=plot(x,modn,'k-','LineWidth',2);
    BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
    title(sprintf('1 Gaussian, BC=%5.3f',BC))
    legend(pht,'Model');
    xlabel('\textbf{Normalized backscattering {\boldmath($$\hat{\sigma^0}$$)}}','Interpreter','Latex','FontWeight','bold','FontName','arial')
    ylabel('Probability','FontWeight','bold')
    xlim([-15 15])
end

function [modn,ng] = getmodn(x,p1)
    curve1=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2));
    modn = curve1(p1);
    ng=1;
end

function mfix = fixInitial( A, x, nsm, mb)
   ind  = find( (x>=mb(1))&(x<=mb(2)) );
   nsm  = nsm(ind);
   x    = x(ind);
   mtmp = x( find(abs(nsm-A) == min(abs(nsm-A))) ); 
   mtmp = mtmp(find( (mtmp>=mb(1))&(mtmp<=mb(2)) ));
   mfix = mtmp(round(numel(mtmp)/2));
   if mfix < mb(1); mfix = mb(1); end
   if mfix > mb(2); mfix = mb(2); end
end

function [lbc,ubc] = checkBounds(x0,lb,ub)
    mset = numel(x0);
    lbc  = lb;
    ubc  = ub;
    eps  = 0.1;
    for ii=1:mset
        if lb(ii)>=x0(ii); lbc(ii) = x0(ii)-eps; end
        if ub(ii)<=x0(ii); ubc(ii) = x0(ii)+eps; end
    end
end

function [p1,p2,p3] = adjustOrder(p1,p2,p3)
    if ~isreal(p1)
      p1(1)=0; p1(2)=0; p1(3)=0;
    end
    if ~isreal(p2)
      p2(1)=0; p2(2)=0; p2(3)=0;
    end
    if ~isreal(p3)
      p3(1)=0; p3(2)=0; p3(3)=0;
    end
    if (p3(1)==0)&(p2(2)>2)
        p3 = p2;
        p2 = [0 0 0];
    end
    if (p1(1)==0)&(p2(2)<-2)
        p1 = p2;
        p2 = [0 0 0];
    end
end
    

function xCurrent = round1fit1(A,m,s,mb,sb,obj,opt)
    x0 = [A m s];
    lb = [A*0.1 mb(1) sb(1)];
    ub = [A*2.0 mb(2) sb(2)];
    [lb,ub] = checkBounds(x0,lb,ub);
    try
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
    catch ME
        opt.Broyden_updates='on';
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
        opt.Broyden_updates='off';
    end
end

function xCurrent = round1fit2(A1,A2,m1,m2,s1,s2,mb1,mb2,sb1,sb2,obj,opt)
    x0 = [A1 m1 s1 A2 m2 s2];
    lb = [A1*0.1 mb1(1) sb1(1) A2*0.1 mb2(1) sb2(1)];
    ub = [A1*2.0 mb1(2) sb1(2) A2*2.0 mb2(2) sb2(2)];
    [lb,ub] = checkBounds(x0,lb,ub);
    try
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
    catch ME
        opt.Broyden_updates='on';
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
        opt.Broyden_updates='off';
    end
end

function xCurrent=round2fit1(xvec,nvec,p,obj,opt)
%     A = nvec( find(abs(xvec-p(2))==min(abs(xvec-p(2)))) );
    A  = p(1);
    x0 = [A p(2) p(3)];
    lb = [A*0.2 p(2)-p(3) p(3)*0.2];
    ub = [A*2.0 p(2)+p(3) p(3)*2];
    [lb,ub] = checkBounds(x0,lb,ub);
    try
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
    catch ME
        opt.Broyden_updates='on';
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
        opt.Broyden_updates='off';
    end
end

function xCurrent=round2fit2(xvec,nvec,p1,p2,obj,opt)
%     A1 = nvec( find(abs(xvec-p1(2))==min(abs(xvec-p1(2)))) );
%     A2 = nvec( find(abs(xvec-p2(2))==min(abs(xvec-p2(2)))) );
    A1 = p1(1);
    A2 = p2(1);
    x0 = [A1 p1(2) p1(3) A2 p2(2) p2(3)];
    lb = [A1*0.2 p1(2)-p1(3) p1(3)*0.2 A2*0.8 p2(2)-p2(3) p2(3)*0.8];
    ub = [A1*2.0 p1(2)+p1(3) p1(3)*2.0 A2*1.2 p2(2)+p2(3) p2(3)*1.2];
    [lb,ub] = checkBounds(x0,lb,ub);
    try
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
    catch ME
        opt.Broyden_updates='on';
        xCurrent = LevenbergMarquardt(obj,x0,lb,ub,opt);
        opt.Broyden_updates='off';
    end
end
