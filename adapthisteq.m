function out = adapthisteq(I, varargin)
  if ndims(I) == 3
    out = I;
    for c = 1:size(I, 3)
      out(:,:,c) = histeq(I(:,:,c));
    end
  else
    out = histeq(I);
  end
endfunction
