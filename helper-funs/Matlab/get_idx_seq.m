function [vec, vecboundaries] = get_idx_seq(datavec, desired)
% GET_IDX_SEQ searches a vector for the closest matches and returns indeces
% 
% Quite often, I find myself looking for the indeces of time, frequency,
% trial in an n-dimensional array. For EEG(lab) data, usually we have an
% array, say 30 freqbands * 64 channels * 200 timepoints, in addition we
% have vectors telling us what, for instance, timepoint 1 is (i.e., 
% EEG.times). If I then want to extract the section that relates to
% 100-150ms, I need to look for the closest matches to 100 & 150 in
% EEG.times, find the respective indeces and create a integer sequence
% between those two indeces to access the EEG array. This function combines
% those steps: Simply pass your vector with labels and your desired
% values to the function and get the vector of indeces for your array.
%
% Input:
%       datavec: 1D Vector with labels (e.g., EEG.times, EEG.freqs, etc.)
%       desired: 1*2 vector with the boundaries of the desired interval
%                (e.g., [7, 15] for a broad alpha band).
%
% Output:
%       vec: vector of indeces that can be passed to a data array (e.g.,
%            EEG.data(vec,:,:))
%       vecboundaries: Second output. 1*2 vector with the boundary indeces.
%                      Useful for functions that only use boundary events
%                      themselves (e.g., tf_transform())
% Example:
%       % fake some eeg data
%       EEG.pow = rand(30, 600, 64);
%       EEG.times = linspace(-0.7207, 4.2207, 600);
%       EEG.freqs = logspace(log10(2), log10(40), 30);
%       
%       % extract power in the alpha band 1.5-2.0s after stimulus onset:
%       ti = get_idx_seq(EEG.times, [1.5, 2.0]);
%       hz = get_idx_seq(EEG.freqs, [7, 15]);
%       data = EEG.pow(hz, ti, :);
%
%       % pass baseline-time to tf_transform() to compute dB baseline
%       [~, tib] = get_idx_seq(EEG.times, [-0.5, 0]);
%       based_pow = tf_transform('dB', data.pow, tib);
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

[~, vecboundaries] = arrayfun(@(x) min(abs(datavec - x)), desired);
vec = vecboundaries(1):vecboundaries(2);

end