function [] = EyelinkNotify(message, eyelinkconnected)
% EYELINKNOTIFY(message, eyelinkconnected) displays a message on Eyelink Host PC
% Message can be any string you like to be displayed in the bottom right
% corner of the host pc. This is can be useful, when you want to run in
% single screen mode and keep track of trials. Keep in mind, that the space
% for characters is limited. Usually you'd want something like this:
%  EyelinkNotify(sprintf('Trial %i/%i', itrial, maxnumbertrials))
%
% 'eyelinkconnected' can be useful when your experiment has a single
% parameter that controls whether eyetracking should be used or not (e.g.,
% 'P.isET'). If 1 (default), the function sends a message, if 0, the
% function simply does nothing.
%
% Wanja Moessing, July 2018

%  Copyright (C) 2018 Wanja Mössing
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

if nargin < 2
    eyelinkconnected = 1;
end

if nargin < 1
    message = 'no message provided';
end

if ~isstr(message)
    warning('EyelinkNotify needs a string, you provided a(n) %s!',...
        class(message));
    eyelinkconnected = 0;
end

if eyelinkconnected
    Eyelink('command', sprintf('record_status_message "%s"', message));
end

end