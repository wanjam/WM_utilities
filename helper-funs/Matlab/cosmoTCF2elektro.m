function [ elektrodata ] = cosmoTCF2elektro( cosmodata, times, chanlocs, freqs, P  )
% COSMOTCF2ELEKTRO transforms the output of cosmo_searchlight to a
% plottable elektro-pipe like format
%
% Wanja Moessing, moessing@wwu.de, May 2018

%find info about dimensions
% try to guess how many dimension the data has
dimnames = fieldnames(cosmodata.fa);
data = cosmodata.samples;
sampleLen = length(cosmodata.samples);

if ismember('chan',dimnames)
    CH = cosmodata.fa.chan;
    CHlen = length(unique(CH));
    elektrodata.chanlocs = chanlocs(P.channels);
else
    CHlen = 1;
    CH = true(1, sampleLen);
    disp('Channel dimension is singular or not present. Won''t store chanlocs.');
end
if ismember('freq',dimnames)
    HZ = cosmodata.fa.freq;
    HZlen = length(unique(HZ));
    [~, Hz(1)] = min(abs(freqs - P.freqrange(1)));
    [~, Hz(2)] = min(abs(freqs - P.freqrange(end)));
    elektrodata.freqs = freqs(Hz(1):Hz(2));
else
    HZlen = 1;
    HZ = true(1, sampleLen);
    try
        elektrodata.freqs = mean(P.freqrange);
    catch
        warning('Could not find P.freqrange. Not storing any information about frequencies!')
    end
end
if ismember('time',dimnames)
    TI = cosmodata.fa.time;
    TIlen = length(unique(TI));
    [~, Ti(1)] = min(abs(times - P.timerange(1)));
    [~, Ti(2)] = min(abs(times - P.timerange(end)));
    elektrodata.times = times(Ti(1):Ti(2));
else
    TIlen = 1;
    TI = true(1, sampleLen);
    try
        elektrodata.times = P.timerange;
    catch
        warning('Could not find P.timerange. Not storing any information about time!');
    end
end

elektrodata.accuracy = zeros([HZlen,TIlen,CHlen]);
for ichan = unique(CH)
    for ihz = unique(HZ)
        elektrodata.accuracy(ihz, :, ichan) = data(CH==ichan & HZ==ihz);
    end
end

end

