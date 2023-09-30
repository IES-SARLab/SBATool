function tsizelist = initTileSize(nx,ny,varargin)
%function tsizelist = initTileSize(nx,ny,[config,keyname])
% config:  config dictionary
% keyname: name in the config dictionary to obtain the
%          tsizelist
% nx, ny:  image dimension

if numel(varargin)==2
    config  = varargin{1};
    keyname = varargin{2};
end

if exist('config','var')
    if isKey(config,keyname)
        tsizelist=eval(config(keyname));
    else
        tsizelist = initTileSize(nx,ny);
    end
else
    mindim = min([nx ny]);
    absmintsize = 10;
    absmaxtsize = 500;
    
    if mindim<30
        error('Minimal file dimension is less than 30 pixels. Increase the file dimension.')
    elseif (mindim>=30)&&(mindim<100)
        step = 4;
        maxtsize = floor(mindim/2);
        mintsize = max([absmintsize ceil(maxtsize/step)]);
        if maxtsize < mintsize
            tsizelist = maxtsize;
        else
            tsizelist = floor(linspace(mintsize,maxtsize,step));
        end
    elseif (mindim>=100)&&(mindim<500)
        step = 8;
        maxtsize = floor(mindim/2);
        mintsize = max([absmintsize ceil(maxtsize/step)]);
        tsizelist = floor(linspace(mintsize,maxtsize,step));
    elseif mindim>500
        step = 10;
        maxtsize = min([absmaxtsize floor(mindim/2)]);
        mintsize = max([absmintsize ceil(maxtsize/step)]);
        tsizelist = floor(linspace(mintsize,maxtsize,step));
    end
end
