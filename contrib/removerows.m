function [y,settings] = removerows(x,varargin)
%REMOVEROWS Remove matrix rows with specified indices.
%  
% <a href="matlab:doc removerows">removerows</a> processes input and target data by removing selected rows
% from the data.
%
% [Y,settings] = <a href="matlab:doc removerows">removerows</a>(X,'ind',rowIndices) takes a matrix and returns
% it with the specified rows removed, and also returns the settings used to
% perform the transform.
%
% Here random data is transformed by removing the second row.
%
%   x1 = [rand(1,20)*5-1; rand(1,20)*20-10; rand(1,20)-1];
%   [y1,settings] = <a href="matlab:doc removerows">removerows</a>(x1,'ind',2)
%
% <a href="matlab:doc removerows">removerows</a>('apply',X,settings) transforms X consistent with settings
% returned by a previous transformation.
%
%   x2 = [rand(1,20)*5-1; rand(1,20)*20-10; rand(1,20)-1];
%   y2 = <a href="matlab:doc removerows">removerows</a>('apply',x2,settings)
%
% <a href="matlab:doc removerows">removerows</a>('reverse',Y,settings) reverse transforms Y consistent with
% settings returned by a previous transformation.  When the removed rows
% are replace they are filled in with NaN values indicating their actual
% values are not known.
%
%   x1_again = <a href="matlab:doc removerows">removerows</a>('reverse',y1,settings)
%
% See also REMOVECONSTANTROWS, FIXUNKNOWNS.

% Copyright 1992-2014 The MathWorks, Inc.

% Function Info
if nargin > 0
    x = convertStringsToChars(x);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargin == 0
  y = nn_processing_fcn.info(mfilename); return
end
  
% Backward Compatibility
if ischar(x)
  if nargout < 2
    y = nnet7.process_fcn(mfilename,x,varargin{:});
  else
    [y,settings] = nnet7.process_fcn(mfilename,x,varargin{:});
  end
  return
end

% Create
param = nn_modular_fcn.getParamStructFromArgs(mfilename,varargin);
[y,settings] = removerows.create(x,param);
