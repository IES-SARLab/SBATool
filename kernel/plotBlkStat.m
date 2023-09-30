function varargout=plotBlkStat(I,xv,yv,varargin)
%function [(P,M,fh,tileID)]=plotBlkTileStat(I,xv,yv,(pltmap,debug,Gtype))
%
% xv: [x1 x2]
% yv: [y1 y2]


if numel(varargin)>0; pltmap = varargin{1}; else; pltmap = 0; end
if numel(varargin)>1; debug  = varargin{2}; else; debug  = 0; end
if numel(varargin)>2; Gtype  = varargin{3}; else; Gtype = 3; end

if pltmap
    figure; 
    imagesc(I,[-3 3]);
    hold on;
    pgon=polyshape([xv(1) xv(2) xv(2) xv(1) xv(1)],...
                   [yv(1) yv(1) yv(2) yv(2) yv(1)]);
    plot(pgon,'FaceColor','none','EdgeColor','r','LineWidth',2);
end

tmpImg = I(yv(1):yv(2), xv(1):xv(2));
% figure; imagesc(tmpImg); colorbar
[ P,M,fh ] = getStatG3( tmpImg, 1, debug, Gtype ); 
blksize = (xv(2)-xv(1)+1)*(yv(2)-yv(1)+1);

if nargout > 0
    varargout{1} = P;
end
if nargout > 1
    varargout{2} = M;
end
if nargout > 2
    varargout{3} = fh;
end

fprintf(1,'blk size=%d\n',blksize);
fprintf(1,'xt=[%d,%d],yt=[%d,%d]\n',xv(1),xv(2),yv(1),yv(2));
fprintf(1,'BC  = %02d\n',round(M.BC*100));
fprintf(1,'AD1 = %3.1f, SR1 = %02d, AS1 = %f, NIA1 = %f\n',M.AD1,round(M.SR1*100),M.AS1,M.NIA1);
fprintf(1,'AD3 = %3.1f, SR3 = %02d, AS3 = %f, NIA3 = %f\n',M.AD3,round(M.SR3*100),M.AS3,M.NIA3);
fprintf(1,'1st Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p1(1),P.G3p1(2),P.G3p1(3));
fprintf(1,'2nd Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p2(1),P.G3p2(2),P.G3p2(3));
fprintf(1,'3rd Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p3(1),P.G3p3(2),P.G3p3(3));


[G,BC,c1,c2] = getStatG1( tmpImg, 1, debug, Gtype ); 
fprintf(1,'BC (single mode)  = %02d\n',round(BC*100));
fprintf(1,'Lower cutoff: %0.2f\n',c1);
fprintf(1,'Upper cutoff: %0.2f\n',c2);

end

