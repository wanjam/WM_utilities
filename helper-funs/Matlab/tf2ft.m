function [FT] = tf2ft(TF, data_chans, datafieldname)
%TF2FT Prepares the output of design_runtf for fieldtrip
%   This function takes a TF-Structure as is produced by Elektro-Pipe's
%   design_runtf and converts the data to a format that fieldtrip's
%   permutation testing functions can digest.
%   Crucially, it assumes TF.pow is:
%           4D: freqs x times x channels x subject.
%
%   Optional input 'data_chans' can be a vector defining which channels in
%   TF.chanlocs are data channels. Usually this can be CFG.data_chans. If
%   not provided, the function checks how many channels are present in the
%   data and assumes the first N labels are the correct ones.
%
%   Optional string 'datafieldname' can be used to indicate a field that's
%   going to be used as FT.dat in the end. Default is 'pow'.
%
% Wanja Moessing, moessing@wwu.de, Dec 2017

% permutation testing data need these fields:
% hdr:
%   .Fs = sampling frequency @recording
%   .nChans = number of channels
%   .nSamples = number of samples per trial
%   .nSamplesPre = number of samples pre-trigger
%   .nTrials = number of trials
%   .label = Nx1 cell with all channel-labels (URCHAN)
%
% label:
%   Nchan*1 cell with all DATA-channels (CFG.data_chans)
%
% time:
%   1*Ntrial cell with each cell (1*NTimepoints) vector containing human 
%   readable time in seconds.
%
% trial:
%   the actual data. 1*Ntrial cell with each Nchan*NTimepoints
%
% fsample:
%   the current sampling rate

% input checks
if nargin < 3
    datafieldname = 'pow';
end

if nargin < 2
    data_chans = 1:size(TF.(datafieldname), 3);
end

% header
FT.hdr.Fs = TF.old_srate;
FT.hdr.nChans = length({TF.chanlocs.labels});
FT.hdr.nSamples = length(TF.times);
FT.hdr.nSamplesPre = sum(TF.times<0);
FT.hdr.nTrials = length(TF.trials);
FT.hdr.label = {TF.chanlocs.labels}';

% channel info
FT.label = FT.hdr.label(data_chans);
FT.elec.label = FT.label;
CH = TF.chanlocs(data_chans);
FT.elec.pnt   = [[CH.X]', [CH.Y]', [CH.Z]'];
FT.eeglabChanlocs = CH;
clear CH

% data info
FT.freq = TF.freqs;
FT.time = TF.times;
FT.dimord = 'subj_chan_freq_time';
FT.fsample = TF.new_srate;

% here could be code for the single trial case
%[FT.time{1:length(TF.trials)}] = deal(TF.times);

% data
FT.powspctrm = permute(TF.(datafieldname), [4, 3, 1, 2]);

end

