function Img = tile2Img(tile,xtilevec,ytilevec)
% function Img = tile2Img(tile,xtilevec,ytilevec)

xtileStart = xtilevec(1,:);
xtileEnd   = xtilevec(2,:);
ytileStart = ytilevec(1,:);
ytileEnd   = ytilevec(2,:);
nxtile = numel(xtileStart);
nytile = numel(ytileStart);

nx  = xtileEnd(end);
ny  = ytileEnd(end);
Img = nan(ny,nx);

for xx = 1:nxtile
    for yy = 1:nytile
        Img(ytileStart(yy):ytileEnd(yy), xtileStart(xx):xtileEnd(xx)) = tile(yy,xx);
    end
end

end
