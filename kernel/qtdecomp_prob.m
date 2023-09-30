function [S,statOut] = qtdecomp_prob(varargin)
%QTDECOMP_PROB Quadtree decomposition and probability calculation
%   QTDECOMP divides a square image into four equal-sized square blocks, and
%   then tests each block to see if meets some criterion of homogeneity. If a
%   block meets the criterion, it is not divided any further. If it does not
%   meet the criterion, it is subdivided again into four blocks, and the test
%   criterion is applied to those blocks. This process is repeated iteratively
%   until each block meets the criterion. The result may have blocks of
%   several different sizes.
%
%   [S,stats] = QTDECOMP_PROB(I,THRESHOLD,[MINDIM MAXDIM],GTYPE) will not produce blocks smaller
%   than MINDIM or larger than MAXDIM. Blocks larger than MAXDIM are split
%   even if they meet the threshold condition. MAXDIM/MINDIM must be a power
%   of 2. THRESHOLD consist of a set of statistical thresholds below which the block
%   will be further splitted. GTYPE is 1 for lower class and 3 for over class.
%
%   S: sparse matrix showing the split points of I
%   stats: probability statistics of the splits
%
%   Class Support
%   -------------
%   For the syntaxes that do not include a function, the input image can be
%   logical, uint8, uint16, int16, single, or double. For the syntaxes that
%   include a function, the input image can be any class supported by the
%   function. The output matrix is always sparse.
%
%
%   Modified after qtdecomp.m
%   Nina@2023
%

varargin = matlab.images.internal.stringToChar(varargin);
[A, func, params, minDim, maxDim] = ParseInputs(varargin{:});

[M,N] = size(A);
S = zeros(M,N);

% Initialize blocks
S(1:maxDim:M, 1:maxDim:N) = maxDim;

dim = maxDim;
cnt = 1;

while (dim >= minDim)
    % Find all the blocks at the current size.
    [blockValues, Sind] = qtgetblk(A, S, dim);
    if (isempty(Sind))
        % Done!
        break;
    end
    doSplitlist = logical([]);
    statlist = {};
    clear statlist
    for ii=1:size(blockValues,3)
        [doSplit,stat] = feval(func, squeeze(blockValues(:,:,ii)), params{:});
        doSplitlist = [doSplitlist; doSplit];
        statlist{ii}= stat;
    end
    % Record splitting results in output matrix.
    display(sprintf('Splitting dimension %d',dim))
    dim = round(dim/2);
    Sind = Sind(doSplitlist);
    Sind = [Sind ; Sind+dim ; (Sind+M*dim) ; (Sind+(M+1)*dim)]; %#ok<AGROW>
    S(Sind) = dim;
    % Record output stats
    statOut{cnt} = statlist(~doSplitlist);
    cnt = cnt+1;
end

S = sparse(S);

end

function [dosplit,stat] = QTDECOMP_Split(A, thresh, dims, Gtype)

    setGaussianInitials;
    im_sec = A(isfinite(A));
    quad_split_szs = floor(double([size(A,1) size(A,2)])/2);
    
    try  
        [P,M] = getStatG3( im_sec(:), 0, 0, 3 );
    catch ME
        display('Error in getStatG3!')
        keyboard
    end
    
    %%% Check different scenarios
    if any(quad_split_szs <= dims(1))||(numel(im_sec) <= dims(1)^2) %single modal
        dosplit = false;
        if Gtype==1
            stat.p1 = P.G3p1;
            stat.p2 = P.G3p2;
            stat.BC = M.BC;
            stat.AD = M.AD1;
            stat.SR = M.SR1;
            stat.AS = M.AS1;
            stat.NIA = M.NIA1;
        elseif Gtype==3
            stat.p1 = P.G3p3;
            stat.p2 = P.G3p2;
            stat.BC = M.BC;
            stat.AD = M.AD3;
            stat.SR = M.SR3;
            stat.AS = M.AS3;
            stat.NIA = M.NIA3;
        else
            error('Gtype needs to be 1 or 3');
        end
    else
        if Gtype==1
            if ( M.AD1<thresh(1) )||( M.BC<thresh(2) )||( M.SR1<thresh(3)||P.G3p1(2)>thresh(5) ) 
                dosplit = true;
                stat.p1 = nan;
                stat.p2 = nan;
                stat.AD = nan;
                stat.BC = nan;
                stat.AD = nan;
                stat.AS = nan;
                stat.NIA = nan;
            else
                dosplit = false;
                stat.p1 = P.G3p1;
                stat.p2 = P.G3p2;
                stat.AD = M.AD1;
                stat.BC = M.BC;
                stat.SR = M.SR1;
                stat.AS = M.AS1;
                stat.NIA = M.NIA1;
            end
        elseif Gtype==3
            if ( M.AD3<thresh(1) )||( M.BC<thresh(2) )||( M.SR3<thresh(3)||M.AS3<thresh(4)||P.G3p1(2)<thresh(5)||M.NIA3<thresh(6) ) 
                dosplit = true;
                stat.p1 = nan;
                stat.p2 = nan;
                stat.AD = nan;
                stat.BC = nan;
                stat.AD = nan;
                stat.AS = nan;
                stat.NIA = nan;
            else
                dosplit = false;
                stat.p1 = P.G3p3;
                stat.p2 = P.G3p2;
                stat.AD = M.AD3;
                stat.BC = M.BC;
                stat.SR = M.SR3;
                stat.AS = M.AS3;
                stat.NIA = M.NIA3;
            end
        end
    end
end

%%%
%%% Subfunction ParseInputs
%%%
function [A, func, params, minDim, maxDim] = ParseInputs(varargin)

    if (nargin <=3)
        error(message('images:qtdecomp:tooFewInputs'))
    end

    A = varargin{1};
    if (ndims(A) > 2)
        error(message('images:qtdecomp:expectedTwoD'))
    end
    minDim = 1;
    maxDim = min(size(A));

    params = varargin(3:end);
    [func,fcnchk_msg] = fcnchk(varargin{2}, length(params));
    if isempty(fcnchk_msg)
        % qtdecomp(A,fun,...)
        % nothing more to do
    else
        func = 'QTDECOMP_Split';
        thresh = varargin{2};
        minDim = min(varargin{3});
        maxDim = max(varargin{3});
        Gtype  = varargin{4};
        params = {thresh [minDim maxDim] Gtype};
    end
    
    if (isequal(func, 'QTDECOMP_Split'))
        % Do some error checking on the parameters

        % If the input is uint8, scale the threshold parameter.
        if (isa(A, 'uint8'))
            params{1} = round(255 * params{1});
        elseif isa(A, 'uint16')
            params{1} = round(65535 * params{1});
        elseif isa(A,'int16')
            A = builtin("_int16touint16", A);
            params{1} = round(65535 * params{1});
        end

        func = @QTDECOMP_Split;
    end
end
