function [counts, edges] = histcounts(x, varargin)
  x = double(x(:));
  if nargin < 2 || isempty(varargin{1})
    nbins = 10;
    [counts, centers] = hist(x, nbins);
    bw = (max(x) - min(x)) / nbins;
    edges = [centers - bw/2, centers(end) + bw/2];
  elseif isnumeric(varargin{1}) && isscalar(varargin{1})
    nbins = varargin{1};
    [counts, centers] = hist(x, nbins);
    bw = (max(x) - min(x)) / nbins;
    edges = [centers - bw/2, centers(end) + bw/2];
  elseif isnumeric(varargin{1}) && isvector(varargin{1})
    edges = varargin{1};
    counts = histc(x, edges);
    if length(counts) > 1, counts(end-1) = counts(end-1) + counts(end); counts(end) = []; end
  else
    nbins = 10;
    [counts, centers] = hist(x, nbins);
    bw = (max(x) - min(x)) / nbins;
    edges = [centers - bw/2, centers(end) + bw/2];
  end
endfunction
