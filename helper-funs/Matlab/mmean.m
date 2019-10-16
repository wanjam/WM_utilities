function [y] = mmean(X, dims)
% MMEAN computes the mean over multiple dimensions of an n-dimensional
% array
%
% Input:
%       X:    n-dimensional array to be averaged
%       dims: 1D vector with integer indeces. The dimensions to compute the
%             average over; in the order to compute averages.
%
% Output:
%       y:    n-dimensional, squeezed, array. The result of computing the
%             mean over the dimensions specified in 'dims'.
%
% Example:
%       dat = rand(5, 5, 5, 5, 5);
%       size(dat)
%       dat = mmean(dat, [3, 5, 1]); % average over dimension 3, then 5
%                                    % then 1
%       size(dat)
%
% author: Wanja Moessing, moessing@wwu.de, August 2019

%  Copyright (C) 2019 Wanja Moessing
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.

% loop over dimensions and compute means
for idim = dims
    X = mean(X, idim);
end

% remove singleton dimensions
y = squeeze(X);

end