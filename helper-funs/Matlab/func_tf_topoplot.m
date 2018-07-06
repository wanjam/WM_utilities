function [h, c] = func_tf_topoplot(pow, varargin)
% FUNC_TF_TOPOPLOT creates a topoplot base on Elektro-Pipe TF data
%
%
%
% Input:
%       Required:
%           pow = One value per channel |OR| EEG-struct
%
%           note: if it's a EEG-struct, dimensions are assumed to be:
%                 pow.pow(freq, time, chan, subjects). Subjects are ignored
%                 if not present.
%       Semi-optional:
%           chanlocs  = EEG.chanloc; can be ignored, if pow is struct
%           topolim   = limits for color coding; default: minmax
%           markchans = highlight channels. Indices or names.
%           ConditionName = append this to title
%           smoothness = gridscale, default is 150
%           cmap = which colormap to use (default, 'jet')
%           unit = unit of data (e.g., 'dB')
%           topofreqs = which frequencies are plotted (just used for title)
%           tlim = If pow is EEG-struct, which time interval to average
%                  over? (default = all)
%           flim = If pow is EEG-struct, which frequencies to average
%                  over? (default = all)
%           subs = If pow is EEG-struct, which subjects to average
%                  over? (default = all)
%           conv = 'conv' of topoplot.m
%           freqs = if pow is NOT an EEG-struct. What is the frequency
%                       range shown (default [-Inf, Inf])
%           pmask = mask as derived by cluster test. auto-permutes if
%                   dimensionorder differs from power
%           maskmode = if pmask os present, should non-significant chans be
%                      left out (default) or marked ('marked')?
%           aggregate = function handle. How to aggregate data? Default is
%                       @mean. Anything that works like @mean can be used
%                       
%
% Wanja Moessing, moessing@wwu.de, Nov 2017

% parse variable input
p = inputParser;
p.FunctionName = 'funct_tf_topoplot';
p.addRequired('pow',@(x) isstruct(x) || isnumeric(x));
p.addOptional('chanlocs','all', @isstruct);
p.addOptional('topolim', 'minmax', @(x) (isnumeric(x) && length(x)==2)...
    || any(strcmp(x,{'absmax','minmax'})));
p.addOptional('markchans', NaN, @isvector);
p.addOptional('smoothness', 150, @isnumeric);
p.addOptional('ConditionName','',@isstr);
p.addOptional('maskmode','default',@isstr);
p.addOptional('cmap','jet', @isstr);
p.addOptional('unit','unknown unit', @isstr);
p.addOptional('tlim',':', @(x) isnumeric(x) && length(x) == 2);
p.addOptional('freqs',':', @(x) isnumeric(x) && length(x) == 2);
p.addOptional('subs',':', @(x) isnumeric(x) || strcmp(x, ':'));
p.addOptional('conv','on', @isstr);
p.addOptional('topofreqs',[-Inf, Inf], @(x) isnumeric(x) && length(x) == 2);
p.addOptional('pmask', [], @(x) islogical(x) || isempty(x));
p.addOptional('electrodes', 'on', @isstr);
p.addOptional('aggregate', @mean, @(x) isa(x, 'function_handle'));
parse(p, pow, varargin{:})

%% act upon variable input
% chanlocs
if isstruct(pow) && strcmp(p.Results.chanlocs, 'all')
    chanlocs = pow.chanlocs;
else
    chanlocs = p.Results.chanlocs;
end

% One-liner
P = p.Results;
aggfun = @P.aggregate;

% sanity checks
if ~isstruct(pow) && ~all(strcmp(':', {P.tlim, P.freqs, P.subs}))
    warning(['Data is not a structure but ''tlim'', ''freqs'', or ''subs''',...
        ' is provided. Data input in matrix format is supposed to be one',...
        ' value per channel. Use a structure or summarize before using',...
        ' this function.'])
end


% get average in case pow is an EEG struct 
if isstruct(pow)
    %find indeces of time & freq
    if ~strcmp(':', P.tlim)
        [~, a] = min(abs(pow.times - P.tlim(1)));
        [~, b] = min(abs(pow.times - P.tlim(end)));
        P.tlim = a:b;
    end
    if ~strcmp(':', P.freqs)
        [~, a]  = min(abs(pow.freqs - P.freqs(1)));
        [~, b]  = min(abs(pow.freqs - P.freqs(end)));
        P.freqs = a:b;
        % get topofreqs for title
        topofreqs = [pow.freqs(P.freqs(1)), pow.freqs(P.freqs(end))];
    else
        topofreqs = [pow.freqs(1), pow.freqs(end)];
    end

    % calculate average
    powURsize = size(pow.pow);
    pow = squeeze(aggfun(aggfun(aggfun(...
        pow.pow(P.freqs, P.tlim, :, P.subs), 4), 2), 1));
    
    % check for pmask
    if ~isempty(P.pmask)
        % try to deal with masks produced by fieldtrip
        % check if dimord differs but size is same
        if ~all(powURsize(1:3) == size(P.pmask)) &&...
                all(ismember(powURsize(1:3), size(P.pmask)))
            a = find(powURsize(1) == size(P.pmask));
            b = find(powURsize(2) == size(P.pmask));
            c = find(powURsize(3) == size(P.pmask));
            P.pmask = permute(P.pmask, [a, b, c]);
        end
        % Whenever any time- or frequency point in to-be-plotted range is
        % significant, plot it.
        pmask = squeeze(any(any(...
            P.pmask(P.freqs, P.tlim, :, P.subs), 2), 1));
        if strcmp(P.maskmode, 'mark')
            P.markchans = unique([P.markchans, find(pmask)']);
            pmask = true(size(pmask));
        end
    else
        pmask = P.pmask;
    end
else
    topofreqs = P.topofreqs;
end


%% plot
if isempty(P.pmask)  % 'style' seems to break 'pmask' -> bug in topoplot?
    h = topoplot(pow, chanlocs, 'conv', P.conv,...
        'maplimits', P.topolim, 'gridscale', P.smoothness, 'electrodes',...
        'on', 'emarker2', {P.markchans, '.', 'w', 18, 1},...
        'style', 'map', 'electrodes', P.electrodes);
else
    h = topoplot(pow, chanlocs, 'conv', P.conv,...
        'maplimits', P.topolim, 'gridscale', P.smoothness, 'electrodes',...
        'on', 'emarker2', {P.markchans, '.', 'w', 18, 1}, 'pmask', pmask,...
        'electrodes', P.electrodes);
end
 
title([num2str(topofreqs(1)), '-', num2str(topofreqs(end)),...
    'Hz', P.ConditionName]);

colormap(P.cmap);

c = colorbar('TickLabelInterpreter', 'none', 'location', 'eastoutside');

set(c.Label, 'String', P.unit, 'fontweight', 'bold', 'fontsize', 12,...
    'interpreter', 'none')
