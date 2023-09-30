function [ha, pos] = tight_subplot(Nh, Nw, loc, varargin)

% tight_subplot creates "subplot" axes with adjustable gaps and margins
%
% [ha, pos] = tight_subplot(Nh, Nw, loc, 'gap', gap, 'marg_h', marg_h, 'marg_w', marg_w)
%
%   in:  Nh      number of axes in hight (vertical direction)
%        Nw      number of axes in width (horizontaldirection)
%        loc     location of the subplot
%                   can be scalar, or vectors
%                   such as [3 6] for the tight_subplot(2,3,[3 6])
%        gap     gaps between the axes in normalized units (0...1)
%                   in [gap_h gap_w]; default [.02 .02] 
%        marg_h  margins in height in normalized units (0...1)
%                   in [lower upper]; default [.1 .1]
%        marg_w  margins in width in normalized units (0...1)
%                   in [left right]; default [.02 .02]
%
%  out:  ha     the axis object
%        pos    positions of the axes objects
%
%  Example: ha = tight_subplot(3,2,1,'gap',[.01 .03],'marg_h',[.1 .01],'marg_w',[.01 .01])
%

% Pekka Kumpulainen 21.5.2012   @tut.fi
% Tampere University of Technology / Automation Science and Engineering

defaultGap = [0.02 0.02];
defaultMargH = [0.1 0.1];
defaultMargW = [0.02 0.02];

p = inputParser;
validScalar = @(x) isnumeric(x) && isscalar(x) && (x > 0);
validVector = @(x) isnumeric(x) && isvector(x) && (numel(x) == 2);
validVectorLoc = @(x) isnumeric(x) && isvector(x) && (numel(x) > 0);
addRequired(p, 'Nh', validScalar);
addRequired(p, 'Nw', validScalar);
addRequired(p, 'loc', validVectorLoc);
addOptional(p, 'gap', defaultGap, validVector);
addOptional(p, 'marg_h', defaultMargH, validVector);
addOptional(p, 'marg_w', defaultMargW, validVector);
parse(p,Nh,Nw,loc,varargin{:});

Nh = p.Results.Nh;
Nw = p.Results.Nw;
loc = p.Results.loc;
gap = p.Results.gap;
marg_h = p.Results.marg_h;
marg_w = p.Results.marg_w;

axh = (1-sum(marg_h)-(Nh-1)*gap(1))/Nh; 
axw = (1-sum(marg_w)-(Nw-1)*gap(2))/Nw;

py = 1-marg_h(2)-axh; 

positions = zeros(Nh*Nw, 4);
ii = 0;
for ih = 1:Nh
    px = marg_w(1);
    for ix = 1:Nw
        ii = ii+1;
        positions(ii,:) = [px py axw axh];           
        px = px+axw+gap(2);
    end
    py = py-axh-gap(1);
end

if numel(loc) == 1
    pos = positions(loc,:);
else
    pos_sel = positions(loc,:); 
    if numel(unique(diff(loc))) == 1 
        if ( (unique(diff(loc)) == 1) && (Nw ~= 1) ) % same row
            pos = [min(pos_sel(:,1)) min(pos_sel(:,2)) ...
                   mean(pos_sel(:,3))*numel(loc)+(numel(loc)-1)*gap(2) ...
                   mean(pos_sel(:,4))];
        else % same column
            pos = [min(pos_sel(:,1)) min(pos_sel(:,2)) ...
                   mean(pos_sel(:,3)) ...
                   mean(pos_sel(:,4))*numel(loc)+(numel(loc)-1)*gap(1)];
        end
    else % block mode
        indSeg      = find(diff(loc) ~=1 );
        indSegStart = [1 indSeg+1]; 
        indSegEnd   = [indSeg numel(loc)];
        ncol = unique(diff(indSegStart));
        nrow = numel(indSegStart);
        if numel(unique(diff(indSegStart))) > 1
            error('Selected subplot range does not have the right cell index. Abort plot.')
        end
        pos = [min(pos_sel(:,1)) min(pos_sel(:,2)) ...
               mean(pos_sel(:,3))*ncol+(ncol-1)*gap(2) ...
               mean(pos_sel(:,4))*nrow+(nrow-1)*gap(1)];
    end
end

ha = axes('Units','normalized', ...
            'Position',pos);

