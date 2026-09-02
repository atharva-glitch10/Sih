function out = imgaussfilt(A, sigma, varargin)
  if nargin < 2 || isempty(sigma), sigma = 0.5; end
  A = double(A);
  hsize = 2 * ceil(2 * sigma) + 1;
  h = fspecial('gaussian', hsize, sigma);
  try
    out = imfilter(A, h, 'symmetric');
  catch
    out = conv2(A, h, 'same');
  end
endfunction
