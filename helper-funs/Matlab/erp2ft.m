function [FT] = erp2ft(ERP, varargin)
%ERP2FT Prepares the output of design_runerp for fieldtrip
%   This function takes an ERP-Structure as is produced by Elektro-Pipe's
%   design_runerp and converts the data to a format that fieldtrip's
%   permutation testing functions can digest.
%   Crucially, it assumes TF.pow is:
%           3D: channels x times x subject.
%   OR
%           3D: channels x times x trials
%
%   Optional input 'singletrial' can be true | false (default). If true, data of a
%   single subject are transformed at a single-trial level. This is useful
%   for, e.g., cosmomvpa.
%
%   Optional input 'data_chans' can be a vector defining which channels in
%   TF.chanlocs are data channels. Usually this can be CFG.data_chans. If
%   not provided, the function checks how many channels are present in the
%   data and assumes the first N labels are the correct ones.
%
%   Optional string 'datafieldname' can be used to indicate a field that's
%   going to be used as FT.dat in the end. Default is 'data'.
%
% Wanja Moessing, moessing@wwu.de, Dec 2019

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


%% input checks
p = inputParser;
p.FunctionName = 'erp2ft';
p.addRequired('ERP',@isstruct);
p.addOptional('singletrial', false, @islogical);
p.addOptional('data_chans', 0);
p.addOptional('datafieldname', 'data', @isstr);
parse(p, ERP, varargin{:})

datafieldname = p.Results.datafieldname;
data_chans    = p.Results.data_chans;
singletrial   = p.Results.singletrial;


%% Transform input
switch singletrial
    case false  % avergage case
        
        if data_chans == 0
            data_chans = 1:size(ERP.(datafieldname), 1);
        end
        % header
        try
            FT.hdr.Fs = ERP.old_srate;
        catch
            warning(['erp2ft: couldn''t find field ''.old_srate''.',...
                'Estimating sampling rate from data instead...']);
            FT.hdr.Fs = round(ERP.pnts / ((ERP.times(end) - ERP.times(1))/1000));
        end
        FT.hdr.nChans = length({ERP.chanlocs.labels});
        FT.hdr.nSamples = length(ERP.times);
        FT.hdr.nSamplesPre = sum(ERP.times<0);
        FT.hdr.nTrials = length(ERP.trials);
        FT.hdr.label = {ERP.chanlocs.labels}';
        
        % channel info
        FT.label = FT.hdr.label(data_chans);
        FT.elec.label = FT.label;
        CH = ERP.chanlocs(data_chans);
        FT.elec.pnt   = [[CH.X]', [CH.Y]', [CH.Z]'];
        FT.eeglabChanlocs = CH;
        clear CH
        
        % data info
        FT.time = ERP.times;
        FT.dimord = 'subj_chan_time';
        try
            FT.fsample = ERP.new_srate;
        catch
            FT.fsample = round(ERP.pnts / ((ERP.times(end) - ERP.times(1))/1000));
        end
        % data
        FT.data = permute(ERP.(datafieldname), [3, 1, 2]);
        
    case true  % singletrial case
        error('erp2ft: singletrial not implemented yet..')
%         
%         if data_chans == 0
%             data_chans = 1:size(ERP.single.(datafieldname), 4);
%         end
%         
%         % header
%         FT.hdr.Fs = ERP.old_srate;
%         FT.hdr.nChans = length({ERP.single.chanlocs.labels});
%         FT.hdr.nSamples = length(ERP.single.times);
%         FT.hdr.nSamplesPre = sum(ERP.single.times < 0);
%         FT.hdr.nTrials = size(ERP.single.(datafieldname), 3);
%         FT.hdr.label = {ERP.single.chanlocs.labels}';
%         
%         % channel info
%         FT.label = FT.hdr.label(data_chans);
%         FT.elec.label = FT.label;
%         CH = ERP.single.chanlocs(data_chans);
%         FT.elec.pnt   = [[CH.X]', [CH.Y]', [CH.Z]'];
%         FT.eeglabChanlocs = CH;
%         clear CH
%         
%         % data info
%         FT.freq = ERP.single.freqs;
%         FT.time = ERP.single.times;
%         FT.dimord = 'trial_chan_freq_time';
%         FT.fsample = ERP.new_srate;
%         
%         % is this necessary?
%         %[FT.time{1:length(ERP.trials)}] = deal(ERP.times);
%         
%         % data
%         FT.powspctrm = permute(ERP.single.(datafieldname), [3, 4, 1, 2]);
end

end
