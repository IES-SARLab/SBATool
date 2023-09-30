function [ P,M,fh ] = getStatG3( img, varargin ) 
% function [ P, M, fh ] = getStatG3( img, (pltfig, debug, Gtype) ) 
%
%  P: parameter structrue with G3p1,G3p2,G3p3
%  M: metric structure with BC,AD1,AD3,SR1,SR3,AS1,AS3,NIA1,NIA3
%  fh: figure handle

    if numel(varargin)>0; pltfig = varargin{1}; else; pltfig = 0; end
    if numel(varargin)>1; debug = varargin{2}; else; debug  = 0; end
    if numel(varargin)>2; Gtype = varargin{3}; else; Gtype  = 3; end

    % calculate the statistics for the tile
%    %m = [-3.0000  0  3.9]; %guess
%    %s = [1.3599 1.0000  0.5]; %guess
%    m = [-3.0000  0  5]; %guess
%    s = [1.3599 1.0000  1]; %guess
%    mb= [-10.0000   -2.000;
%         -2.0000    2.50000;
%          2.500     8.0000];
%    sb= [0.2000    2.50;
%         0.1000    3.00;
%         0.4500    2.50];
%    xvec=-15:0.25:15;
    % get the initial guesses from script
    setGaussianInitials;
    img = img(:);
    %try
        [G3p1,G3p2,G3p3,~,h3,modh3,fh]=gaussianFit3(m,s,mb,sb,img,xvec,'none',pltfig,debug);
    %catch ME
    %    display('Error in gaussianFit3')
    %    keyboard
    %end

    % BC = Bhattacharyya coefficient (how well is the fit; 1 for the best)
    modh3(modh3<0)=0;
    BC = sum(sqrt(h3/sum(h3)).*sqrt(modh3/sum(modh3)));

    % Non-interception area ratio (NIA)
    curve1=@(p)p(1)*exp((-0.5)*((xvec-p(2)).^2)./(p(3)^2));
    g1h = curve1(G3p1);
    g2h = curve1(G3p2);
    g3h = curve1(G3p3);    
    dcurve12 = g1h - g2h;
    dcurve23 = g3h - g2h;
    areaZ1 = trapz(g1h);
    areaZ3 = trapz(g3h);
    if (trapz(g1h)>0); NIA1 = sum(dcurve12(dcurve12>0))/trapz(g1h); else; NIA1 = 0; end
    if (trapz(g3h)>0); NIA3 = sum(dcurve23(dcurve23>0))/trapz(g3h); else; NIA3 = 0; end

    % AD = Ashman D coefficient (how two Guassians are separated; must larger than 2)
    % SR = Surface ratio
    % AS = Bimodal ratio [Zhang et al., 2003]
    code = int8(G3p1(1)~=0)*100+int8(G3p2(1)~=0)*10+int8(G3p3(1)~=0);
    switch code
        case 000 %A1 only
            AD1 = 0; SR1 = 0; AS1 = 0;
            AD3 = 0; SR3 = 0; AS3 = 0;
        case 100 %A1 only
            AD1 = 0; SR1 = 1; AS1 = 0;
            AD3 = 0; SR3 = 0; AS3 = 0;
        case 010 %A2 only
            AD1 = 0; SR1 = 0; AS1 = 0;
            AD3 = 0; SR3 = 0; AS3 = 0;
        case 001 %A3 only 
            AD1 = 0; SR1 = 0; AS1 = 0;
            AD3 = 0; SR3 = 1; AS3 = 0;
        case 110 %A1+A2 
            AD1 = sqrt(2)*abs(G3p1(2)-G3p2(2))/sqrt(G3p1(3)^2+G3p2(3)^2);
            SR1 = min([G3p1(1)*G3p1(3)*sqrt(2*pi) G3p2(1)*G3p2(3)*sqrt(2*pi)])/ ...
                  max([G3p1(1)*G3p1(3)*sqrt(2*pi) G3p2(1)*G3p2(3)*sqrt(2*pi)]);
            if (G3p1(1)>G3p2(1)); SR1 = 1/SR1; end 
            AS1 = G3p1(1)/G3p2(1); 
            AD3 = 0; SR3 = 0; AS3 = 0;
        case 011 %A2+A3
            AD1 = 0; SR1 = 0; AS1 = 0;
            AD3 = sqrt(2)*abs(G3p2(2)-G3p3(2))/sqrt(G3p2(3)^2+G3p3(3)^2);
            SR3 = min([G3p2(1)*G3p2(3)*sqrt(2*pi) G3p3(1)*G3p3(3)*sqrt(2*pi)])/ ...
                  max([G3p2(1)*G3p2(3)*sqrt(2*pi) G3p3(1)*G3p3(3)*sqrt(2*pi)]);
            if (G3p3(1)>G3p2(1)); SR3 = 1/SR3; end 
            AS3 = G3p3(1)/G3p2(1);
        case 101 %A1+A3
            AD1 = 0; SR1 = 0; AS1 = 0;
            AD3 = 0; SR3 = 0; AS3 = 0;
        case 111 %A1+A2+A3
            AD1 = sqrt(2)*abs(G3p1(2)-G3p2(2))/sqrt(G3p1(3)^2+G3p2(3)^2);
            SR1 = min([G3p1(1)*G3p1(3)*sqrt(2*pi) G3p2(1)*G3p2(3)*sqrt(2*pi)])/ ...
                  max([G3p1(1)*G3p1(3)*sqrt(2*pi) G3p2(1)*G3p2(3)*sqrt(2*pi)]);
            if (G3p1(1)>G3p2(1)); SR1 = 1/SR1; end 
            AS1 = G3p1(1)/G3p2(1); 
            AD3 = sqrt(2)*abs(G3p2(2)-G3p3(2))/sqrt(G3p2(3)^2+G3p3(3)^2);
            SR3 = min([G3p2(1)*G3p2(3)*sqrt(2*pi) G3p3(1)*G3p3(3)*sqrt(2*pi)])/ ...
                  max([G3p2(1)*G3p2(3)*sqrt(2*pi) G3p3(1)*G3p3(3)*sqrt(2*pi)]);
            if (G3p3(1)>G3p2(1)); SR3 = 1/SR3; end 
            AS3 = G3p3(1)/G3p2(1);
    end
    
    P.G3p1 = G3p1;
    P.G3p2 = G3p2;
    P.G3p3 = G3p3;
    M.BC   = BC;
    M.AD1  = AD1;
    M.AD3  = AD3;
    M.SR1  = SR1;
    M.SR3  = SR3;
    M.AS1  = AS1;
    M.AS3  = AS3;
    M.NIA1 = NIA1;
    M.NIA3 = NIA3;
end
