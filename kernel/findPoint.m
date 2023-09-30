function [px,py] = findpoint(xs,ys,type,varargin)
%function [px,py] = findpoint(xs,ys,type,[yweighting])
%
% type:  topleft topcenter topright
%        midleft  center   midright
%        botleft botcenter botright
%        all: ind 1-9 stands, in the following order:
%             1 6 4
%             8 2 9
%             5 7 3
%        all90( 
% yweighting: larger value to enfource envely y-distribution     default: 1
%             default: 1
%
% Nina Lin 2020

% to enfource the even y distribution
if numel(varargin)>0; 
    yweighting = varargin{1}; 
else
    yweighting = 1;
end

xs = reshape(xs,1,numel(xs));
ys = reshape(ys,1,numel(ys));
minx = min(xs);
maxx = max(xs);
centx = (minx + maxx) / 2;
miny = min(ys);
maxy = max(ys);
centy = (miny + maxy) / 2;
rx   = (maxx-minx)/2;
ry   = (maxy-miny)/2;

switch type
    case 'topleft'
        dist2 = (xs - minx).^2  + yweighting*(ys - maxy).^2;
    case 'topcenter'
        dist2 = (xs - centx).^2 + yweighting*(ys - maxy).^2;
    case 'topright'
        dist2 = (xs - maxx).^2  + yweighting*(ys - maxy).^2;
    case 'midleft'
        dist2 = (xs - minx).^2  + yweighting*(ys - centy).^2;
    case 'center'
        dist2 = (xs - centx).^2 + yweighting*(ys - centy).^2;
    case 'midright'
        dist2 = (xs - maxx).^2  + yweighting*(ys - centy).^2;
    case 'botleft'
        dist2 = (xs - minx).^2  + yweighting*(ys - miny).^2;
    case 'botcenter'
        dist2 = (xs - centx).^2 + yweighting*(ys - miny).^2;
    case 'botright'
        dist2 = (xs - maxx).^2  + yweighting*(ys - miny).^2;
    case 'all'
        dist2 = [ (xs - minx).^2  + yweighting*(ys - maxy).^2; ... %(1,1)
                  (xs - centx).^2 + yweighting*(ys - centy).^2; ...%(2,2)
                  (xs - maxx).^2  + yweighting*(ys - miny).^2; ... %(3,3)
                  (xs - maxx).^2  + yweighting*(ys - maxy).^2; ... %(3,1)
                  (xs - minx).^2  + yweighting*(ys - miny).^2; ... %(1,3)
                  (xs - centx).^2 + yweighting*(ys - maxy).^2; ... %(2,1)
                  (xs - centx).^2 + yweighting*(ys - miny).^2; ...%(2,3) 
                  (xs - minx).^2  + yweighting*(ys - centy).^2; ...%(1,2)
                  (xs - maxx).^2  + yweighting*(ys - centy).^2]; ...%(3,2)
    case 'all90'
        minx  = minx+dx*.05;
        maxy  = maxx-dx*.05;
        miny  = miny+dy*.05;
        maxy  = maxy-dy*.05;
        dist2 = [ (xs - minx).^2  + yweighting*(ys - maxy).^2; ... %(1,1)
                  (xs - centx).^2 + yweighting*(ys - centy).^2; ...%(2,2)
                  (xs - maxx).^2  + yweighting*(ys - miny).^2; ... %(3,3)
                  (xs - maxx).^2  + yweighting*(ys - maxy).^2; ... %(3,1)
                  (xs - minx).^2  + yweighting*(ys - miny).^2; ... %(1,3)
                  (xs - centx).^2 + yweighting*(ys - maxy).^2; ... %(2,1)
                  (xs - centx).^2 + yweighting*(ys - miny).^2; ...%(2,3) 
                  (xs - minx).^2  + yweighting*(ys - centy).^2; ...%(1,2)
                  (xs - maxx).^2  + yweighting*(ys - centy).^2]; ...%(3,2)
end
    

[mindist2, idx] = min(dist2,[],2);
px = xs(idx);
py = ys(idx);
