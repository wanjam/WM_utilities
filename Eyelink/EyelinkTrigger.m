function [] = EyelinkTrigger(message, eyelinkconnected)
% EYELINKTRIGGER(message, eyelinkconnected) sends a trigger to the Eyelink.
% message must be a string
%
% 'eyelinkconnected' can be useful when your experiment has a single
% parameter that controls whether eyetracking should be used or not (e.g.,
% 'P.isET'). If 1 (default), the function sends a trigger, if 0, the
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
if eyelinkconnected == 0
    disp('No Eyelink connected - no trigger sent..')
    return
end

if nargin < 1
    message = 'no message provided';
end

if ~isstr(message)
    warning('EyelinkTrigger needs a string, you provided a(n) %s!',...
        class(message));
    return
end

Eyelink('message', message);

end