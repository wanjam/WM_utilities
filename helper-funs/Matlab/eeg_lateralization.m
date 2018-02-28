function [lateralization, ipsi, contra, ll, rl, lr, rr] = eeg_lateralization(l_chan, r_chan, l_data, r_data, channeldim)
%
% Function for computing event related lateralization.
%
% Input:
% l_chan: vector of left hemisphere channels.
% r_chan: vector of right hemisphere channels.
% l_data: matrix with EEG data from trials with left events.
% r_data: matrix with EEG data from trials with right events.
% channeldim: which dimension in the data matrices represent channels?
%
% Output:
% lateralization: average lateralization for all channels and events.
% ipsi, contra:   data for ipsilateral and contralateral channels, averaged
% across left and right events.
% ll, lr, rl, rr: first letter=hemifield, sencond letter=hemisphere.
% E.g.: lr = left events, right channels.
%
% copied from (github.com/nabusch)

% If input data is a struct, assume that the data are EEGLAB set files.
if isstruct(l_data)
    l_data = l_data.data;
    r_data = r_data.data;
end

ll = extract_chans(l_data, l_chan, channeldim);
rl = extract_chans(r_data, l_chan, channeldim);
lr = extract_chans(l_data, r_chan, channeldim);
rr = extract_chans(r_data, r_chan, channeldim);

ipsi   = (ll + rr) ./ 2;
contra = (lr + rl) ./ 2;

lateralization = contra - ipsi;

%%
% The purpose of this function is to extract data of the relevant channels
% from a bigger matrix of all channels. Problem: the dimension related to
% channels is arbitrary and user-dependent. Thus, we rotate the matrix such
% that channels are in the first dimension, extract the relevant channels,
% and then rotate the matrix back to its original layout.

function outdata = extract_chans(indata, channels, channeldim)

nchans = size(indata, channeldim);
nshift = channeldim-1;

% Shift matrix so that channel dimension is always the first dimension.
indata = shiftdim(indata, nshift);
dims_after_shift  = size(indata);

% Extract only the channels of interest; concatenate all other dimensions
% in the process.
indata = indata(channels,:);

% Average across the channels of interest.
indata = mean(indata, 1);

% Replicate the resulting matrix, so that the number of elements in the
% channel dimension matches the original number of channels. This is
% important, otherwise we would loose a dimension, and the reshape process
% would fail.
indata = repmat(indata, [nchans 1]);

% Reshape this matrix so that it has the original number of dimensions.
indata = reshape(indata, dims_after_shift);

% Shift the matrix back so that dimensions are in the same place as in the
% original.
indata = shiftdim(indata, -nshift);

% Finally, average across channel dimension to get rid of the repmat
% effect.
outdata = squeeze(mean(indata, channeldim));
