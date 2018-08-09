function [topolat, lchan_idx, rchan_idx] = eeg_topolat(l_data, r_data, chanlocs, dim);


if nargin == 3
    dim = 1;
end

%%

% some coordinates for chans on the midline have very small, but non-zero
% values. We round them down to zero.
for i = 1:length(chanlocs)
    chanlocs(i).Y = round(10 * chanlocs(i).Y) / 10;
end

original_dims = 1:ndims(l_data);
nshift = 1 - dim;

l_data = shiftdim(l_data, nshift);
r_data = shiftdim(r_data, nshift);

lchan_idx = find([chanlocs.Y] >  0);
rchan_idx = find([chanlocs.Y] <  0);

all_data = (l_data + r_data) .* 0.5;

nchans = size(all_data,dim);

% % normalize each subject's topo to their individual mean and sd so that a
% all_data_m   = repmat(mean(all_data,dim), [nchans ones(1,length(original_dims)-1) ]);
% all_data_sd  = repmat(std(all_data,[],dim), [nchans ones(1,length(original_dims)-1) ]);
% single subejct with giatn values cannot dominate the granda verage topo.
% l_data = (l_data - all_data_m) ./ all_data_sd;
% r_data = (r_data - all_data_m) ./ all_data_sd;


% We calculate contra - ipsi.
topolat = zeros(size(l_data));
topolat(lchan_idx,:) = r_data(lchan_idx,:) - l_data(lchan_idx,:);
topolat(rchan_idx,:) = l_data(rchan_idx,:) - r_data(rchan_idx,:);




