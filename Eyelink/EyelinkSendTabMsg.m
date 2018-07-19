function [message] = EyelinkSendTabMsg(varargin)
% EYELINKSENDTABMSG takes a cell list of elements and sends them to the
% Tracker.
%
% More specifically, you can pass any number of arguments to this function
% and it will concatenate them in a tab-delimited manner to one single
% string. The function then prepends a '>', and sends this message to the
% Eyelink. Thereby, most (if not all) behavioral data can be stored along
% with the Eyetrack and can later simply be parsed along with the
% eyetracking data in R (i.e., by checking all the messages and
% tab-splitting those that start with '>'). Note that each element must
% only contain one datum.
%
% Examples:
%   EyelinkSendTabMsg(1, 'ConditionA', 'RespCorrect', 99, 7.036748);
%   EyelinkSendTabMsg('ConditionA', 3);
%   msg = EyelinkSendTabMsg(1, 'CoA', 'ResC', 99, 'eyelinkisconnected', 1);
%   msg = EyelinkSendTabMsg(1, 'CoA', 'ResW', 99, 'eyelinkisconnected', 0);
%
% Not run:
%   EyelinkSendTabMsg(1, myTrialMatrix);
%   EyelinkSendTabMsg(1, 10:15);
%   EyelinkSendTabMsg(1, mean());
%
% Optional:
%   keyword 'eyelinkconnected' can appear at any place in the list of
%   arguments and should be followed by '0' or '1' (default). This is
%   useful when your experiment has a single parameter that controls
%   whether eyetracking should be used or not (e.g., 'P.isET'). If 1
%   (default), the function sends a message, if 0, the function simply
%   returns the message. 'eyelinkconnected' and the respective value are
%   not included in the message.
%
% Wanja Moessing, July 2018, moessing@wwu.de

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

%% check if user specified whether eyelink is connected
if any(strcmp(varargin, 'eyelinkconnected'))
    index = find(strcmp(varargin, 'eyelinkconnected'));
    eyelinkconnected = varargin{index + 1};
    varargin([index, index + 1]) = [];
else
    eyelinkconnected = 1;
end

%% concatenate message
message = strcat('>', strjoin(...
    cellfun(@num2str, varargin, 'UniformOutput', false), {'\t'}));

%% send message
if eyelinkconnected
    Eyelink('Message', message);
end

end

