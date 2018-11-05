function EyelinkRecalibration(P, eyelinkconnected)
% EYELINKRECALIBRATION(P, eyelinkconnected)
% performs recalibration of a connected Eyetracker after breaks etc
%
% Needs P.el with all subfields introduced during the initial calibration
% called by startEyelink including P.el.capture(1:4), indicating which
% datatyes to record.
%
% 'eyelinkconnected' should be 0 or 1 (default). If 0, the function does
% nothing.
%
% Wanja Moessing 29/02/2016, 05/11/2018


%  Copyright (C) 2016-2018 Wanja Mössing
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

% check if eyelink is connected
if nargin < 2
    eyelinkconnected = 1;
end
if eyelinkconnected == 0
    disp('No Eyelink connected. No connection to close...');
    return
end

Eyelink('Message', 'STOP_REC_4_RECAL');

% add 100 msec of data to catch final events
WaitSecs(0.1);
Eyelink('StopRecording');

% make sure to use the same settings as during EyelinkStart
EyelinkUpdateDefaults(P.el);

% Hide the mouse cursor;
HideCursor;

% Do the actual calibration
EyelinkDoTrackerSetup(P.el);

% clear tracker display and draw box at center
Eyelink('Command', 'clear_screen 0')
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.05);

% this can optionally take four boolean input values, specifiying
% the datatypes recorded (file_samples, file_events, link_samples, link_events)
%Eyelink('StartRecording',P.trackr.capture(1),P.trackr.capture(2),P.trackr.capture(3),P.trackr.capture(4));

% restart recording
Eyelink('StartRecording');
end
