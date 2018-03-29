function [topolat, lchan_idx, rchan_idx, ipsi, contra] = tf_topolat(l_data, r_data, chanlocs, meanSub, lchans, rchans)
% TF_TOPOLAT calculates contra-ipsi for Time-Frequency EEG data over
% channels
% l_data & r_data should be freqbands*time*channel (use permute() to adjust if necessary)
% l_* & r_* refer to data where the left or right hemifield was stimulated
% chanlocs is a typical EEGlab EEG.chanlocs struct
% meanSub: if dimension 4 is+ subjects: calculate average?
% Wanja Moessing, moessing@wwu.de, Nov 2017

%set default for meanSub
if nargin < 4
    meanSub = 1;
end

%if meanSub, average over dim 4
if meanSub
    l_data = squeeze(mean(l_data, 4));
    r_data = squeeze(mean(r_data, 4));
end

% some coordinates for chans on the midline have very small, but non-zero
% values. We round them down to zero.
for i = 1:length(chanlocs)
    chanlocs(i).Y = round(10 * chanlocs(i).Y) / 10;
end

% identify left and right chans via coordinates
if nargin < 5
    lchan_idx = find([chanlocs.Y] > 0);
else
    lchan_idx = lchans;
end

if nargin < 6
    rchan_idx = find([chanlocs.Y] < 0);
else
    rchan_idx = rchan;
end

% ipsi
ipsi = zeros(size(l_data));
ipsi(:,:,lchan_idx,:) = l_data(:,:,lchan_idx,:);
ipsi(:,:,rchan_idx,:) = r_data(:,:,rchan_idx,:);

% contra
contra = zeros(size(l_data));
contra(:,:,lchan_idx,:) = r_data(:,:,lchan_idx,:);
contra(:,:,rchan_idx,:) = l_data(:,:,rchan_idx,:);

% We calculate contra - ipsi and set midline to zero
%topolat = zeros(size(l_data));
%topolat(:,:,lchan_idx,:) = r_data(:,:,lchan_idx,:) - l_data(:,:,lchan_idx,:);
%topolat(:,:,rchan_idx,:) = l_data(:,:,rchan_idx,:) - r_data(:,:,rchan_idx,:);
topolat = contra - ipsi;
end