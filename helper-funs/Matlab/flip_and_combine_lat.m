function [combiDat, lchan_idx, rchan_idx] = flip_and_combine_lat(...
    l_data, r_data, chanlocs)
%% FLIP_AND_COMBINE flips right-data and combines them with left data
% r_data are data where stimulus was in right hemifield
% the result is a dataset that acts as if all stimuli where in the left
% hemifield. That is, the right hemisphere is always contra..
% Wanja Moessing, November 2017, moessing@wwu.de

% ignore midline channels
% some coordinates for chans on the midline have very small, but non-zero
% values. Round them to zero
for i = 1:length(chanlocs)
    chanlocs(i).Y = round(10 * chanlocs(i).Y) / 10;
end

% look at channels and get indices
lchan_idx = find([chanlocs.Y] >  0);
rchan_idx = find([chanlocs.Y] <  0);

% flip right data
% for each channel in rchan_idx, find the closest match to a flipped Y
for ch = rchan_idx
    [foundMatch, idx] = ismember(chanlocs(ch).Y * -1, [chanlocs.Y]);
    if ~foundMatch
        error('Couldn''t find a matching channel');
    end
    tmp = r_data(ch, :, :);
    r_data(ch, :, :) = r_data(idx, :, :);
    r_data(idx, :, :) = tmp;
end

%merge r_data and l_data
combiDat = (r_data + l_data) / 2;
