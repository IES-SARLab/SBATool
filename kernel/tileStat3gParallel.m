function [xtilevec,ytilevec,BCt,AD1t,AD3t,SR1t,SR3t,AS1t,AS3t,NIA1t,NIA3t,C1t,C2t,BCSt,varargout]=tileStat3gParallel(I,tsize,shift,Iguide,varargin)
% This function performs "region growing" in an image from a specified
% [xtilevec,ytilevec,BCt,AD1t,AD3t,SR1t,SR3t,NIA1,NIA3,C1t,C2t,BCSt,(G1At,G1Mt,G1St,G2At,G2Mt,G2St,G3At,G3Mt,G3St)] = ...
%                                   tileStat3g(I,tsize,shift,Iguide,(Gtype)) 
% xtilevec: tile-to-image mapping, row1=x-start; row2=x-end
% ytilevec: tile-to-image mapping, row1=y-start; row2=y-end
% BCt:  tile with Bhattacharyya coefficient
% AD1t:  tile with Ashman D coefficient (between 1st & 2nd Gaussian)
% AD3t:  tile with Ashman D coefficient (between 2nd & 3rd Gaussian)
% SR1t:  tile with Surface Ratio (between 1st & 2nd Gaussian)
% SR3t:  tile with Surface Ratio (between 2nd & 3rd Gaussian)
% AS1t,AS3t:  tile with Aspect Ratio (height/std) for 1st and 3rd Gaussian
% NIA1t,NIA3t: Non-Intercepting Area ratio
% G1At: tile with growth region ID for 1st Gaussian
% G1Mt: tile with growth region mean for 1st Gaussian
% G1St: tile with growth region std for 1st Gaussian
% G2At: tile with growth region ID for 2rd Gaussian
% G2Mt: tile with growth region mean for 2rd Gaussian
% G2St: tile with growth region std for 2rd Gaussian
% G3At: tile with growth region ID for 3rd Gaussian
% G3Mt: tile with growth region mean for 3rd Gaussian
% G3St: tile with growth region std for 3rd Gaussian
% I : input image 
% tsize: tile size
% shift: 0 < shift < 1, shift the tile window by shift*tsize
% Iguide : guide image, same size as I; 0 = skip pixel; 1 = work on pixel
% Gtype: 1 or 3 for different Gaussian Fit flows (default = 3)
%
% Nina Lin @ April 2020

if numel(varargin)>0; Gtype = varargin{1}; else; Gtype = 3; end

[xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(I,tsize,shift);
nxtile = numel(xtileStart);
nytile = numel(ytileStart);

for xxyy = 1:nxtile*nytile
    [indytile,indxtile]=ind2sub([nytile,nxtile],xxyy);
    tmpImg{xxyy} = I(ytileStart(indytile):ytileEnd(indytile), xtileStart(indxtile):xtileEnd(indxtile));
    gdeImg{xxyy} = Iguide(ytileStart(indytile):ytileEnd(indytile), xtileStart(indxtile):xtileEnd(indxtile));
end

%for xxyy = 1:nxtile*nytile
parfor xxyy = 1:nxtile*nytile
%for xxyy = 1:nxtile*nytile
%for xxyy = 206:206
%%%=== For debug purpose
%%%for xxyy = 39:39
%%%    seedImg  = tmpImg(xxyy)(:);
%%%    guideImg = gdeImg(xxyy)(:);
%%%=== end debug session
  try
      seedImg  = tmpImg{xxyy}(:);
      guideImg = gdeImg{xxyy}(:);
      if ( sum(sum(( isnan(seedImg)==1 )&( seedImg==0 ))) > 0.7*numel(seedImg) ) || ...
         ( sum(sum( guideImg==0 )) > 0.95*sum(sum(( isfinite(seedImg)==1 )&( seedImg~=0 ))) )
          G1Atc(xxyy)=0;
          G1Mtc(xxyy)=0;
          G1Stc(xxyy)=0;
          G2Atc(xxyy)=0;
          G2Mtc(xxyy)=0;
          G2Stc(xxyy)=0;
          G3Atc(xxyy)=0;
          G3Mtc(xxyy)=0;
          G3Stc(xxyy)=0;
          BCtc(xxyy)=0;
          AD1tc(xxyy)=0;
          AD3tc(xxyy)=0;
          SR1tc(xxyy)=0;
          SR3tc(xxyy)=0;
          AS1tc(xxyy)=0;
          AS3tc(xxyy)=0;
          NIA1tc(xxyy)=0;
          NIA3tc(xxyy)=0;
          C1tc(xxyy)=0;
          C2tc(xxyy)=0;
          BCStc(xxyy)=0;
          continue;
      end
      %disp(sprintf('Now processing %d',xxyy));
      [ P,M ] = getStatG3( seedImg, 0, 0, Gtype ); 
      G1Atc(xxyy)=P.G3p1(1);
      G1Mtc(xxyy)=P.G3p1(2);
      G1Stc(xxyy)=P.G3p1(3);
      G2Atc(xxyy)=P.G3p2(1);
      G2Mtc(xxyy)=P.G3p2(2);
      G2Stc(xxyy)=P.G3p2(3);
      G3Atc(xxyy)=P.G3p3(1);
      G3Mtc(xxyy)=P.G3p3(2);
      G3Stc(xxyy)=P.G3p3(3);
      BCtc(xxyy) =M.BC;
      AD1tc(xxyy)=M.AD1;
      AD3tc(xxyy)=M.AD3;
      SR1tc(xxyy)=M.SR1;
      SR3tc(xxyy)=M.SR3;
      AS1tc(xxyy)=M.AS1;
      AS3tc(xxyy)=M.AS3;
      NIA1tc(xxyy)=M.NIA1;
      NIA3tc(xxyy)=M.NIA3;

      [ ~,BCS,C1,C2 ] = getStatG1( seedImg, 0, 0 );
      C1tc(xxyy)=C1;
      C2tc(xxyy)=C2;
      BCStc(xxyy)=BCS;
         
  catch ME
    disp(sprintf('Capture error at tile %d',xxyy));
%    keyboard
%    This doesn't seem to be supported in parfor mode and will incur error
%    if exist('logfile','var')
%        fid = fopen(logfile,'a'); 
%        fprintf(fid,'%s == %s\n', datestr(now),sprintf('Capture error at tile %d',xxyy));
%        fclose(fid);
%    end
  end
end

G1At = reshape(G1Atc,nytile,nxtile);
G1Mt = reshape(G1Mtc,nytile,nxtile);
G1St = reshape(G1Stc,nytile,nxtile);
G2At = reshape(G2Atc,nytile,nxtile);
G2Mt = reshape(G2Mtc,nytile,nxtile);
G2St = reshape(G2Stc,nytile,nxtile);
G3At = reshape(G3Atc,nytile,nxtile);
G3Mt = reshape(G3Mtc,nytile,nxtile);
G3St = reshape(G3Stc,nytile,nxtile);
BCt  = reshape(BCtc,nytile,nxtile);
AD1t = reshape(AD1tc,nytile,nxtile);
AD3t = reshape(AD3tc,nytile,nxtile);
SR1t = reshape(SR1tc,nytile,nxtile);
SR3t = reshape(SR3tc,nytile,nxtile);
AS1t = reshape(AS1tc,nytile,nxtile);
AS3t = reshape(AS3tc,nytile,nxtile);
NIA1t = reshape(NIA1tc,nytile,nxtile);
NIA3t = reshape(NIA3tc,nytile,nxtile);
C1t  = reshape(C1tc,nytile,nxtile);
C2t  = reshape(C2tc,nytile,nxtile);
BCSt = reshape(BCStc,nytile,nxtile);

xtilevec = [xtileStart; xtileEnd];
ytilevec = [ytileStart; ytileEnd];

varargout{1} = G1At;
varargout{2} = G1Mt;
varargout{3} = G1St;
varargout{4} = G2At;
varargout{5} = G2Mt;
varargout{6} = G2St;
varargout{7} = G3At;
varargout{8} = G3Mt;
varargout{9} = G3St;

end



