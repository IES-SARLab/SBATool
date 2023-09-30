function tsizelistClipped = clipTileSize(tsizelist,nx,ny)

% Correction on max tile size: cannot be larger tha half the width of length
maxtsize = min([floor(nx/2) floor(ny/2)]);
tsizelistiClipped=tsizelist(tsizelist<=maxtsize);

