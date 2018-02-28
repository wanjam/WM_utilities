function [h, c] = tf_topoplot(pow, chanlocs, topolim, topofreqs, markChans, ConditionName, cmap, unit)
% TF_TOPOPLOT creates a topoplot
%
% Input:
%       pow = One value per channel
%       chanlocs = EEG.chanlocs
%       topolim = limits for color coding
%       markchans = highlight these channels
%       ConditionName = append this to title
%       cmap = which colormap to use (e.g., 'jet')
%       unit = unit of data (e.g., 'dB')
%       topofreqs = which frequencies are plotted (just used for title)
%
% Wanja Moessing, moessing@wwu.de, Nov 2017

h = topoplot(pow, chanlocs, 'style', 'map', 'conv', 'on',...
    'maplimits', topolim, 'numcontour', 49, 'electrodes', 'on', 'emarker2',...
    {markChans,'.','w',18,1});
title([num2str(min(topofreqs)), '-', num2str(max(topofreqs)),...
    'Hz', ConditionName]);
colormap(cmap);
c = colorbar('TickLabelInterpreter', 'none', 'location', 'eastoutside');
set(c.Label, 'String', unit, 'fontweight', 'bold', 'fontsize', 12,...
    'interpreter', 'none')