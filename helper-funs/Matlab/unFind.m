function [ lidx ] = unFind( idx, data )
%UNFIND creates a logical index from numerical indices
%   input:
%         idx  = vector with numerical indeces
%         data = the data this idx is used for
% a wanjylaus function

lidx = zeros(1,length(data));
lidx(idx) = 1;

end