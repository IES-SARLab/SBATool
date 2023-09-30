function [p1,p2,p3,BC,varargout] = gaussianFit3(m,s,mb,sb,data,x,mode,varargin)
% function [p1,p2,p3,BC,(h,modh,figh)] = gaussianFit3(m,s,mb,sb,data,x,mode,varargin)
%
% 3-Guassian parameter fitting 
% Output
%   p1: 3 parameters for curve 1 (Amplitude, mean, std)
%   p2: 3 parameters for curve 2 (Amplitude, mean, std)
%   p3: 3 parameters for curve 2 (Amplitude, mean, std)
%   BC: Bhattacharyya coefficient (how well is the fit; 1 for the best)
%    h: data histogram [optional]
% modh: modeled histogram [optional]
% figh: figure handle [optional]
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
%   debug:  1=debug mode; 0=default (no debug)

if numel(varargin)>0; pltfig = varargin{1}; else; pltfig = 0; end
if numel(varargin)>1; debug  = varargin{2}; else; debug  = 0; end

%%%%% Round 0-A: checking zeros and nans %%%%%
indactual = intersect(find(data~=0),find(isfinite(data)));
if numel(indactual) < 2*numel(x) %hard-coded threshold to be twice the x-vec size
    p1 = [0 0 0];
    p2 = [0 0 0];
    p3 = [0 0 0];
    BC = 0;
    varargout{1} = x*0;
    varargout{2} = x*0;
    varargout{3} = NaN;
    return;   
end

data = data(indactual);
data = data( find( data>min(x) & data<max(x) ) );
nbk = hist(data,x);
xbk = x(:); nbk = nbk(:);
nsmbk = medfilt1(nbk,5);
nbk = nbk./sum(nbk);
nsmbk = nsmbk./sum(nsmbk);
indfirst = min([find(nsmbk~=0, 1, 'first'), findmin(x,mb(1,1))]);
indlast  = max([find(nsmbk~=0, 1, 'last'),  findmax(x,mb(3,2))]);
x = xbk(indfirst:indlast);
n = nbk(indfirst:indlast);
nsm = nsmbk(indfirst:indlast);
n = n./sum(n);
nsm = nsm./sum(nsm);
x2 = x((x>1.5)|(x<-1.5));
n2 = n((x>1.5)|(x<-1.5));
nsm2 = nsm((x>1.5)|(x<-1.5));
curve1=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2));
curve2=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2))+...
           p(4)*exp((-0.5)*((x-p(5)).^2)./(p(6)^2));
curve3=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2))+...
           p(4)*exp((-0.5)*((x-p(5)).^2)./(p(6)^2))+...
           p(7)*exp((-0.5)*((x-p(8)).^2)./(p(9)^2));
curve1h=@(p)p(1)*exp((-0.5)*((x2-p(2)).^2)./(p(3)^2));
curve2h=@(p)p(1)*exp((-0.5)*((x2-p(2)).^2)./(p(3)^2))+...
            p(4)*exp((-0.5)*((x2-p(5)).^2)./(p(6)^2));
curve3h=@(p)p(1)*exp((-0.5)*((x2-p(2)).^2)./(p(3)^2))+...
            p(4)*exp((-0.5)*((x2-p(5)).^2)./(p(6)^2))+...
            p(7)*exp((-0.5)*((x2-p(8)).^2)./(p(9)^2));
xmedian = nanmean(x( find( abs(n-median(n))==min(abs(n-median(n))) )));
switch mode
    case 'center'
        w=(1./abs(x - mean(mb(1,:)))+1./abs(x - mean(mb(3,:)))).^1.65;
    case 'left'
        w=(1./(1:numel(x))).^2;
    case 'right'
        w=(1./(numel(x)-(1:numel(x))+1)).^2;
    case 'xmedian'
        w=(1./abs(x - xmedian)).^2;
    case 'nmedian'
        w=(1./(n-median(n))).^2;
    case 'invdata'
        w=(1./n).^2;
    case 'none'
        w=ones(size(n));
end
wrep = interp1(x(isfinite(w)),w(isfinite(w)),x(~isfinite(w)));
w(find(~isfinite(w))) = wrep;
obj1=@(p)100000*[w.*curve1(p)-w.*nsm].^2;
obj2=@(p)100000*[w.*curve2(p)-w.*nsm].^2;
obj3=@(p)100000*[w.*curve3(p)-w.*nsm].^2;
obj1n=@(p)abs([w.*curve1(p)/sum(curve1(p))-w.*nsm])*100000;
obj2n=@(p)abs([w.*curve2(p)/sum(curve2(p))-w.*nsm])*100000;
obj3n=@(p)abs([w.*curve3(p)/sum(curve3(p))-w.*nsm])*100000;
obj1n2=@(p)abs(1-sum(sqrt(curve1(p)/sum(curve1(p))).*sqrt(nsm)))*100000;
obj2n2=@(p)abs(1-sum(sqrt(curve2(p)/sum(curve2(p))).*sqrt(nsm)))*100000;
obj3n2=@(p)abs(1-sum(sqrt(curve3(p)/sum(curve3(p))).*sqrt(nsm)))*100000;
obj1n3=@(p)abs(1-sum(sqrt(curve1h(p)/sum(curve1h(p))).*sqrt(nsm2)))*100000;
obj2n3=@(p)abs(1-sum(sqrt(curve2h(p)/sum(curve2h(p))).*sqrt(nsm2)))*100000;
obj3n3=@(p)abs(1-sum(sqrt(curve3h(p)/sum(curve3h(p))).*sqrt(nsm2)))*100000;

%%%%% Round 0-B: checking zeros and nans %%%%%
if sum(n==0) > numel(n)*.8 %hard-coded threshold to be 80% of the histogram
    p1 = [0 0 0];
    p2 = [0 0 0];
    p3 = [0 0 0];
    BC = 0;
    varargout{1} = xbk*0;
    varargout{2} = xbk*0;
    varargout{3} = NaN;
    return;   
end
tt= nsm(find((x>mb(1,1))&(x<mb(1,2))));
A1 = max(tt(tt>1e-7)); if (numel(A1)==0)||isnan(A1); A1=0; end
tt = nsm(find((x>mb(2,1))&(x<mb(2,2))));
A2 = max(tt(tt>1e-7)); if (numel(A2)==0)||isnan(A2); A2=0; end
tt = nsm(find((x>mb(3,1))&(x<mb(3,2))));
A3 = quantile(tt(tt>1e-7),.9); if (numel(A3)==0)||isnan(A3); A3=0; end

if A1<1e-4; A1=0; else; m(1) = fixInitial(A1,x,nsm,mb(1,:)); end
if A2<1e-4; A2=0; else; m(2) = fixInitial(A2,x,nsm,mb(2,:)); end
if A3<1e-4; A3=0; else; m(3) = fixInitial(A3,x,nsm,mb(3,:)); end

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
p2 = [A2 m(2) s(2)];
p3 = [A3 m(3) s(3)];
keyboard; end

%%%% Round 1: check for single-mode
if std(data) < 0.5
    A1 = max(nsm);
    xCurrent = round1fit1(A1(1),mean(data),std(data),...
                          [mean(data)-std(data)*2 mean(data)+std(data)*2],...
                          [std(data)*0.1  std(data)*3],obj1n,opt);
    p1 = [0 0 0];
    p2 = xCurrent(1:3);    
    p3 = [0 0 0]; 
    modn = getmodn(xbk,p1,p2,p3);
    BC = sum(sqrt(modn/sum(modn)).*sqrt(nbk));
    varargout{1} = nbk;
    varargout{2} = modn;
    varargout{3} = NaN;
    return;
end

if debug; keyboard; end

%%%%% Round 2: initial fit
code = int8(A1~=0)*100+int8(A2~=0)*10+int8(A3~=0);
switch code
    case 100
    %if (A1~=0)&&(A2==0)&&(A3==0) %A1
        xCurrent = round1fit1(A1,m(1),s(1),mb(1,:),sb(1,:),obj1n,opt);
        p1c{1} = xCurrent(1:3);
        p2c{1} = [0 0 0];
        p3c{1} = [0 0 0];      
    case 010
    %elseif (A1==0)&&(A2~=0)&&(A3==0) %A2
        xCurrent = round1fit1(A2,m(2),s(2),mb(2,:),sb(2,:),obj1n,opt);
        p1c{1} = [0 0 0];  
        p2c{1} = xCurrent(1:3);
        p3c{1} = [0 0 0];
    case 001
    %elseif (A1==0)&&(A2==0)&&(A3~=0) %A3
        xCurrent = round1fit1(A3,m(3),s(3),mb(3,:),sb(3,:),obj1n,opt);
        p1c{1} = [0 0 0];
        p2c{1} = [0 0 0];
        p3c{1} = xCurrent(1:3);
    case 110
    %elseif (A1~=0)&&(A2~=0)&&(A3==0) %A1+A2
        xCurrent = round1fit2(A1,A2,m(1),m(2),s(1),s(2),mb(1,:),mb(2,:),sb(1,:),sb(2,:),obj2n,opt);
        p1c{1} = xCurrent(1:3);
        p2c{1} = xCurrent(4:6);
        p3c{1} = [0 0 0];
    case 011
    %elseif (A1==0)&&(A2~=0)&&(A3~=0) %A2+A3
        xCurrent = round1fit2(A2,A3,m(2),m(3),s(2),s(3),mb(2,:),mb(3,:),sb(2,:),sb(3,:),obj2n,opt);
        p1c{1} = [0 0 0];
        p2c{1} = xCurrent(1:3);
        p3c{1} = xCurrent(4:6);
    case 101
    %elseif (A1~=0)&&(A2==0)&&(A3~=0) %A1+A3
        xCurrent = round1fit2(A1,A3,m(1),m(3),s(1),s(3),mb(1,:),mb(3,:),sb(1,:),sb(3,:),obj2n,opt);
        p1c{1} = xCurrent(1:3);
        p2c{1} = [0 0 0];
        p3c{1} = xCurrent(4:6);
    case 111
    %else   %A1+A2+A3
        x0 = [A1 m(1) s(1) A2 m(2) s(2) A3 m(3) s(3)];
        lb = [A1*0.1 mb(1,1) sb(1,1) A2*0.1 mb(2,1) sb(2,1) A3*0.1 mb(3,1) sb(3,1)];
        ub = [A1*2.0 mb(1,2) sb(1,2) A2*2.0 mb(2,2) sb(2,2) A3*2.0 mb(3,2) sb(3,2)];
        [lb,ub] = checkBounds(x0,lb,ub);
        try
            xCurrent = LevenbergMarquardt(obj3n2,x0,lb,ub,opt);
        catch ME
            opt.Broyden_updates='on';
            xCurrent = LevenbergMarquardt(obj3n2,x0,lb,ub,opt);
            opt.Broyden_updates='off';
        end
        p1c{1} = xCurrent(1:3);
        p2c{1} = xCurrent(4:6);
        p3c{1} = xCurrent(7:9);
        try
            xCurrent = LevenbergMarquardt(obj3,x0,lb,ub,opt);
        catch ME
            opt.Broyden_updates='on';
            xCurrent = LevenbergMarquardt(obj3,x0,lb,ub,opt);
            opt.Broyden_updates='off';
        end
        p1c{2} = xCurrent(1:3);
        p2c{2} = xCurrent(4:6);
        p3c{2} = xCurrent(7:9);
    otherwise
        error(sprintf('ERROR: code %d',code));
end
A1c = A1; A2c = A2; A3c = A3;

if debug; keyboard; end

%%%%% Loop through results from idfferent solvers
for kk = 1:numel(p1c)

    p1 = p1c{kk};
    p2 = p2c{kk};
    p3 = p3c{kk};
    A1 = A1c; A2 = A2c; A3 = A3c;

    %%%%% Round 3 (threshold for peaks)
    if ((A1+p1(1))/2<=1e-4)||(p1(1)<0.0009), A1=0; end
    if ((A2+p2(1))/2<=1e-4)||(p2(1)<0.0009), A2=0; else, A2 = nsm( find(abs(x-p2(2))==min(abs(x-p2(2)))) );      end
    if ((A3+p3(1))/2<=1e-4)||(p3(1)<0.0009), A3=0; end
    p1(1)=A1;
    p2(1)=A2;
    p3(1)=A3;
    
    code = int8(A1~=0)*100+int8(A2~=0)*10+int8(A3~=0);
    switch code
        case 100
        %if (A1~=0)&&(A2==0)&&(A3==0) %A1
            xCurrent = round2fit1(x,nsm,p1,obj1,opt);
            modn = curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);        
            p2 = [0 0 0];
            p3 = [0 0 0];
        case 010
        %elseif (A1==0)&&(A2~=0)&&(A3==0) %A2
            xCurrent = round2fit1(x,nsm,p2,obj1,opt);
            modn = curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));  
            p1 = [0 0 0];
            p2 = xCurrent(1:3);
            p3 = [0 0 0];
        case 001
        %elseif (A1==0)&&(A2==0)&&(A3~=0) %A3
            xCurrent = round2fit1(x,nsm,p3,obj1,opt);
            modn = curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = [0 0 0];
            p2 = [0 0 0];
            p3 = xCurrent(1:3);
        case 110
        %elseif (A1~=0)&&(A2~=0)&&(A3==0) %A1+A2
            xCurrent = round2fit2(x,nsm,p1,p2,obj2,opt);
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);        
            p2 = xCurrent(4:6);
            p3 = [0 0 0];
        case 101
        %elseif (A1~=0)&&(A2==0)&&(A3~=0) %A1+A3
            xCurrent = round2fit2(x,nsm,p1,p3,obj2,opt);
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);        
            p2 = [0 0 0];
            p3 = xCurrent(4:6);
        case 011
        %elseif (A1==0)&&(A2~=0)&&(A3~=0) %A2+A3
            xCurrent = round2fit2(x,nsm,p2,p3,obj2,opt);
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = [0 0 0];
            p2 = xCurrent(1:3);
            p3 = xCurrent(4:6);
        case 111
        %else  %A1+A2+A3 
            x0 = [A1 p1(2) min([p1(3) 4.5 abs(p1(2))*0.45]) ...
                  A2 p2(2) p2(3) ...
                  A3 p3(2) min([p3(3) 3 p3(2)*0.4])];
            lb = [1e-4 p1(2)-p1(3)*3 min([p1(3)*0.8 0.5 p2(3) abs(p1(2))*0.3]) ...
                  A2*0.2 p2(2)-p2(3) p2(3)*0.8 ...
                  A3*0.1 max([p3(2)-p3(3)*3 1.5]) min([p3(3)*0.2 0.5 p2(3) p3(2)*0.3])];
            ub = [A1*2.0 min([p1(2)+p1(3)*3 -1.5]) min([p1(3)*3.0 5 abs(p1(2))*0.5]) ...
                  A2*2.0 p2(2)+p2(3) p2(3)*1.2 ...
                  A3*1.5 p3(2)+p3(3)*3 min([p3(3)*2.0 3.5 p3(2)*0.5])];
            [lb,ub] = checkBounds(x0,lb,ub);
            try
                xCurrent = LevenbergMarquardt(obj3n3,x0,lb,ub,opt);
            catch ME
                opt.Broyden_updates='on';
                xCurrent = LevenbergMarquardt(obj3n3,x0,lb,ub,opt);
                opt.Broyden_updates='off';
            end
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3))+curve1(xCurrent(7:9));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);
            p2 = xCurrent(4:6);
            p3 = xCurrent(7:9);
        otherwise
            error(sprintf('ERROR: code %d',code));
    end
    if debug; keyboard; end
    [p1,p2,p3]=adjustOrder(p1,p2,p3);
    

    %%%%% Round 4 (threshold for mean values)
    if (p1(2)>=-0.7), A1=0; else, A1 = nsm( find(abs(x-p1(2))==min(abs(x-p1(2)))) ); end
    if (p2(1)<mean([p1(1) p2(1) p3(1)])/2),  A2=0; else, A2 = nsm( find(abs(x-p2(2))==min(abs(x-p2(2)))) ); end 
    if (p3(2)<=0.5),  A3=0; else, A3 = nsm( find(abs(x-p3(2))==min(abs(x-p3(2)))) ); end

    p1(1) = A1;
    p2(1) = A2;
    p3(1) = A3;
    code = int8(A1~=0)*100+int8(A2~=0)*10+int8(A3~=0);
    switch code
        case 100
        %if (A1~=0)&&(A2==0)&&(A3==0)  %A1 only
            xCurrent = round2fit1(x,nsm,p1,obj1,opt);
            modn = curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);        
            p2 = [0 0 0];
            p3 = [0 0 0];
        case 010
        %elseif (A1==0)&&(A2~=0)&&(A3==0)  %A2 only
            xCurrent = round2fit1(x,nsm,p2,obj1,opt);
            modn = curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));  
            p1 = [0 0 0];
            p2 = xCurrent(1:3);
            p3 = [0 0 0];
        case 001
        %elseif (A1==0)&&(A2==0)&&(A3~=0)  %A3 only
            xCurrent = round2fit1(x,nsm,p3,obj1,opt);
            modn = curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = [0 0 0];
            p2 = [0 0 0];
            p3 = xCurrent(1:3);
        case 110
        %elseif (A1~=0)&&(A2~=0)&&(A3==0) %A1+A2
            xCurrent = round2fit2(x,nsm,p1,p2,obj2,opt);
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);        
            p2 = xCurrent(4:6);
            p3 = [0 0 0];
        case 011
        %elseif (A1==0)&&(A2~=0)&&(A3~=0) %A2+A3
            xCurrent = round2fit2(x,nsm,p2,p3,obj2,opt);
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = [0 0 0];
            p2 = xCurrent(1:3);
            p3 = xCurrent(4:6);
        case 101
        %elseif (A1~=0)&&(A2==0)&&(A3~=0) %A1+%A3
            xCurrent = round2fit2(x,nsm,p1,p3,obj2,opt);
            modn = curve1(xCurrent(4:6))+curve1(xCurrent(1:3));
            BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
            p1 = xCurrent(1:3);        
            p2 = [0 0 0];
            p3 = xCurrent(4:6);
        case 111

        otherwise
            error(sprintf('ERROR: code %d',code));
    end
    [p1,p2,p3]=adjustOrder(p1,p2,p3);
    
    if debug; keyboard; end

    xCurrentFinal{kk} = [p1 p2 p3];
    if p1(1) == 0; G1curve = 0; G1curveh = 0; else; G1curve = curve1(p1); G1curveh = curve1h(p1); end
    if p2(1) == 0; G2curve = 0; G2curveh = 0; else; G2curve = curve1(p2); G2curveh = curve1h(p2); end
    if p3(1) == 0; G3curve = 0; G3curveh = 0; else; G3curve = curve1(p3); G3curveh = curve1h(p3); end
    modnCheck{kk} = G1curve + G2curve + G3curve;
    modnCheckHigh{kk} = G1curveh + G2curveh + G3curveh;
    BCcheck(kk) = sum(sqrt(modnCheck{kk}/sum(modnCheck{kk}(:))).*sqrt(n));
    BCcheckHigh(kk) = sum(sqrt(modnCheckHigh{kk}/sum(modnCheckHigh{kk}(:))).*sqrt(n2));
end

if numel(xCurrentFinal) > 1
    [BCsort1,indsort1] = sort(BCcheck,'descend');
    if (BCsort1(1)-BCsort1(2))<0.01
        [BCsort2,indsort2] = sort(BCcheckHigh,'descend');
        indFinal=indsort2(1);
    else
        indFinal=indsort1(1);
    end 
else
    indFinal = 1;
end

p1 = xCurrentFinal{indFinal}(1:3);
p2 = xCurrentFinal{indFinal}(4:6);
p3 = xCurrentFinal{indFinal}(7:9);
modnfinal = getmodn(xbk,p1,p2,p3);

varargout{1} = nbk;
varargout{2} = modnfinal; 
if pltfig
    fh=plotcurve(xbk,nbk,nsmbk,p1,p2,p3);
    varargout{3} = fh;
else
    varargout{3} = NaN;
end
end

function fh=plotcurve(x,n,nsm,p1,p2,p3)
    curve1=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2));
    curve2=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2))+...
           p(4)*exp((-0.5)*((x-p(5)).^2)./(p(6)^2));
    curve3=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2))+...
               p(4)*exp((-0.5)*((x-p(5)).^2)./(p(6)^2))+...
               p(7)*exp((-0.5)*((x-p(8)).^2)./(p(9)^2));
    fh=figure('rend','painters','pos',[1 1 1100 450]); 
    subplot(1,2,1)
    hold on; box on;
    fill([x(1)-.0001; x; x(end)+.0001],[0; n; 0],[.5 .5 .5],'EdgeColor',[.5 .5 .5])
    [modn,ng] = getmodn(x,p1,p2,p3);
    ii=1;
    ph=[]; lh={};
    if p2(1)>0; pht=plot(x,curve1(p2),'k-','LineWidth',2); ph(ii)=pht; lh{ii}='G2'; ii=ii+1; else; p2=p2*0; end
    if p1(1)>0; pht=plot(x,curve1(p1),'b-','LineWidth',2); ph(ii)=pht; lh{ii}='G1'; ii=ii+1; else; p1=p1*0; end
    if p3(1)>0; pht=plot(x,curve1(p3),'r-','LineWidth',2); ph(ii)=pht; lh{ii}='G3'; ii=ii+1; else; p3=p3*0; end
    if ng==1        
        pht=plot(x,modn,'c-','LineWidth',1);
        BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
        title(sprintf('1 Gaussian, BC=%5.3f',BC))
    elseif ng==2
        pht=plot(x,modn,'c-','LineWidth',1); 
        BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
        title(sprintf('2 Gaussians, BC=%5.3f',BC))
    else        
        pht=plot(x,modn,'c-','LineWidth',1);
        BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
        title(sprintf('3 Gaussians, BC=%5.3f',BC))
    end
    ph(ii)=pht; lh{ii}='All';
    legend(ph,lh);
    xlabel('\textbf{Normalized backscattering {\boldmath($$\hat{\sigma^0}$$)}}','Interpreter','Latex','FontWeight','bold','FontName','arial')
    ylabel('Number of pixels','FontWeight','bold')

    subplot(1,2,2)
    hold on; box on;
    fill([x(1)-.0001; x; x(end)+.0001],[0; nsm; 0],[.5 .5 .5],'EdgeColor',[.5 .5 .5])
    [modn,ng] = getmodn(x,p1,p2,p3);
    pht=plot(x,modn./sum(modn),'r-','LineWidth',2);
    ii=1;
    ph=[]; lh={};
    if p2(1)>0; pht=plot(x,curve1(p2)./sum(modn),'k-','LineWidth',2); ph(ii)=pht; lh{ii}='G2'; ii=ii+1; else; p2=p2*0; end
    if p1(1)>0; pht=plot(x,curve1(p1)./sum(modn),'b-','LineWidth',2); ph(ii)=pht; lh{ii}='G1'; ii=ii+1; else; p1=p1*0; end
    if p3(1)>0; pht=plot(x,curve1(p3)./sum(modn),'r-','LineWidth',2); ph(ii)=pht; lh{ii}='G3'; ii=ii+1; else; p3=p3*0; end
    if ng==1        
        pht=plot(x,modn./sum(modn),'c-','LineWidth',1);
        BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
        title(sprintf('1 Gaussian, BC=%5.3f',BC))
    elseif ng==2
        pht=plot(x,modn./sum(modn),'c-','LineWidth',1);
        BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
        title(sprintf('2 Gaussians, BC=%5.3f',BC))
    else
        pht=plot(x,modn./sum(modn),'c-','LineWidth',1);
        BC = sum(sqrt(modn/sum(modn)).*sqrt(n));
        title(sprintf('3 Gaussians, BC=%5.3f',BC))
    end
    ph(ii)=pht; lh{ii}='All'; ii=ii+1;
    legend(ph,lh);
    xlabel('\textbf{Normalized backscattering {\boldmath($$\hat{\sigma^0}$$)}}','Interpreter','Latex','FontWeight','bold','FontName','arial')
    ylabel('Probability','FontWeight','bold')
    xlim([-15 15])
end

function [modn,ng] = getmodn(x,p1,p2,p3)
    curve1=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2));
    curve2=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2))+...
           p(4)*exp((-0.5)*((x-p(5)).^2)./(p(6)^2));
    curve3=@(p)p(1)*exp((-0.5)*((x-p(2)).^2)./(p(3)^2))+...
               p(4)*exp((-0.5)*((x-p(5)).^2)./(p(6)^2))+...
               p(7)*exp((-0.5)*((x-p(8)).^2)./(p(9)^2));
    if p1(1)==0; p1=p1*0; end
    if p2(1)==0; p2=p2*0; end
    if p3(1)==0; p3=p3*0; end
    p = [p1 p2 p3];
    if (p1(1)>0)+(p2(1)>0)+(p3(1)>0)==1        
        modn = curve1(p(p~=0));
        ng=1;
    elseif (p1(1)>0)+(p2(1)>0)+(p3(1)>0)==2
        modn = curve2(p(p~=0));
        ng=2;
    else
        modn = curve3(p(p~=0));
        ng=3;
    end
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
    pall = sortrows([p1;p2;p3],2);
    p1 = pall(1,:);
    p2 = pall(2,:);
    p3 = pall(3,:);
    if sum(pall(:,1)~=0)~=1 %check for nonsingle mode
        if (abs(p1(2)-p2(2))<0.5)&&(abs(p3(2)-p2(2))<0.5)
            pall = sortrows(pall,1,'descend');
            p1 = [0 0 0];
            p2 = pall(1,:);
            p3 = [0 0 0];
        else
            if (abs(p1(2)-p2(2))<0.5)&&(p1(1)>p2(1))
                p2 = pall(1,:);
                p1 = [0 0 0];
            elseif (abs(p3(2)-p2(2))<0.5)&&(p3(1)>p2(1))
                p2 = pall(3,:);
                p3 = [0 0 0];
            end
        end
    else %single mode
        p1 = [0 0 0];
        p2 = pall(find(pall(:,1)~=0),:); 
        p3 = [0 0 0];
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
