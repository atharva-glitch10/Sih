function [Gx, Gy] = imgradientxy(I, varargin)
  % Convert RGB to grayscale double if 3D matrix passed
  if ndims(I) == 3
    I = 0.2989 * I(:,:,1) + 0.5870 * I(:,:,2) + 0.1140 * I(:,:,3);
  end
  I = double(I);
  
  % Sobel gradient filters
  Hx = [-1 0 1; -2 0 2; -1 0 1];
  Hy = [-1 -2 -1; 0 0 0; 1 2 1];
  
  Gx = conv2(I, Hx, 'same');
  Gy = conv2(I, Hy, 'same');
endfunction
