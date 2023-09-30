function varargout=plotTileIDStat(I,tid,tsize,shift,varargin)
%function [(P,M,fh,tileXY)]=plotTileIDStat(I,tid,tsize,shift,(pltmap,debug,Gtype))

if numel(varargin)>0; pltmap = varargin{1}; else; pltmap = 0; end
if numel(varargin)>1; debug  = varargin{2}; else; debug  = 0; end
if numel(varargin)>2; Gtype  = varargin{3}; else; Gtype  = 3; end

[xtileStart,xtileEnd,ytileStart,ytileEnd] = xy2tile(I,tsize,shift);

[tidy,tidx]=ind2sub([numel(ytileStart),numel(xtileStart)],tid);

tmpImg = [];
for ii = 1:numel(tid)
    tmp = I(ytileStart(tidy(ii)):ytileEnd(tidy(ii)), xtileStart(tidx(ii)):xtileEnd(tidx(ii)));
    tmpImg = [tmpImg; tmp(:)];
end

if pltmap
    figure; 
    imagesc(I,[-3 3]);
    hold on;
    for ii = 1:numel(tid)
        pgon=polyshape([xtileStart(tidx(ii)) xtileStart(tidx(ii)) xtileEnd(tidx(ii)) xtileEnd(tidx(ii))],...
                       [ytileStart(tidy(ii)) ytileEnd(tidy(ii))   ytileEnd(tidy(ii)) ytileStart(tidy(ii))]);
        plot(pgon,'FaceColor','none','EdgeColor','r','LineWidth',2);
    end
end

% figure; imagesc(tmpImg); colorbar
[ P,M,fh ] = getStatG3( tmpImg, 1, debug, Gtype ); 

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
    varargout{4} = [tidx,tidy];
end

for ii = 1:numel(tid)
    fprintf('xt=%d, yt=%d, tileID=%d\n',tidx(ii),tidy(ii),tid(ii));
end
fprintf('BC  = %02d\n',round(M.BC*100));
fprintf('AD1 = %3.1f, SR1 = %02d, AS1 = %f, NIA1 = %f\n',M.AD1,round(M.SR1*100),M.AS1,M.NIA1);
fprintf('AD3 = %3.1f, SR3 = %02d, AS3 = %f, NIA3 = %f\n',M.AD3,round(M.SR3*100),M.AS3,M.NIA3);
fprintf('1st Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p1(1),P.G3p1(2),P.G3p1(3));
fprintf('2nd Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p2(1),P.G3p2(2),P.G3p2(3));
fprintf('3rd Gaussian amp = %5f, mean = %4.2f, std = %4.2f\n',P.G3p3(1),P.G3p3(2),P.G3p3(3));

end

