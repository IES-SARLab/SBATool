function varargout=plotP2TileStat(I,x,y,tsize,shift,varargin)
%function [(P,M,fh,tileID)]=plotP2TileStat(I,x,y,tsize,shift,(pltmap,debug))
% Plot histogram of the tile where a given point (x,y) is located within
% The tileID is defined the same way as used in SBATool processing
%
% Input
%      I: Image matrix (need to be preloaded using readRaster)
%      x: x location in pixel 
%      y: y location in pixel
%  tsize: tile size  (integer number)
%  shift: tile shift (floating number between 0 and 1)
% pltmap: 1 for plotting the map; default = 0
%  debug: 1 for entering debug mode (for advanced user only); default=0
%
% Output
%      P: probabiliy parameters amplitude, mean, std for 1st, 2nd, 3rd Gaussian
%      M: metrics in order of [BC,AD1,AD3,SR1,SR3,AS1,AS3,NIA1,NIA3]
%     fh: figure handel
% tileID: ID of the tile where the point (x,y) is located within
%
% NinaLin@2024

if numel(varargin)>0; pltmap = varargin{1}; else; pltmap = 0; end
if numel(varargin)>1; debug  = varargin{2}; else; debug  = 0; end

[xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(I,tsize,shift);

idx = find( (x>=xtileStart)&(x<=xtileEnd) );
idy = find( (y>=ytileStart)&(y<=ytileEnd) );
tid = sub2ind([numel(ytileStart),numel(xtileStart)],idy,idx);

if pltmap
    figure; 
    imagesc(I,[-3 3]);
    hold on;
    pgon=polyshape([xtileStart(idx) xtileStart(idx) xtileEnd(idx) xtileEnd(idx)],...
                   [ytileStart(idy) ytileEnd(idy)   ytileEnd(idy) ytileStart(idy)]);
    plot(pgon,'FaceColor','none','EdgeColor','r','LineWidth',2);
end

tmpImg = I(ytileStart(idy):ytileEnd(idy), xtileStart(idx):xtileEnd(idx));
% figure; imagesc(tmpImg); colorbar
[ P,M,fh ] = getStatG3( tmpImg, 1, debug ); 

if nargout > 0
    varargout{1} = P;
end
if nargout > 1
    varargout{2} = M;
end
if nargout > 2
    varargout{3} = fh;
end
if nargout > 3
    varargout{4} = tid;
end

fprintf(1,'x=%d, y=%d, xt=%d, yt=%d, tileID=%d\n',x,y,idx,idy,tid);
fprintf(1,'xt=[%d,%d],yt=[%d,%d]\n',xtileStart(idx),xtileEnd(idx),ytileStart(idy),ytileEnd(idy));
fprintf(1,'BC  = %02d\n',round(M.BC*100));
fprintf(1,'AD1 = %3.1f, SR1 = %02d, AS1 = %f, NIA1 = %f\n',M.AD1,round(M.SR1*100),M.AS1,M.NIA1);
fprintf(1,'AD3 = %3.1f, SR3 = %02d, AS3 = %f, NIA3 = %f\n',M.AD3,round(M.SR3*100),M.AS3,M.NIA3);
fprintf(1,'1st Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p1(1),P.G3p1(2),P.G3p1(3));
fprintf(1,'2nd Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p2(1),P.G3p2(2),P.G3p2(3));
fprintf(1,'3rd Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p3(1),P.G3p3(2),P.G3p3(3));


[G,BC,c1,c2] = getStatG1( tmpImg, 1, debug ); 
fprintf(1,'BC (single mode)  = %02d\n',round(BC*100));
fprintf(1,'Lower cutoff: %0.2f\n',c1);
fprintf(1,'Upper cutoff: %0.2f\n',c2);

end

