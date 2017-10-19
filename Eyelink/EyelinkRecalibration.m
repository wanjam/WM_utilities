function EyelinkRecalibration(P)
% performs recalibration of a connected Eyetracker after breaks etc
%
% needs P.el with all subfields introduced during the initial calibration
% called by startEyelink and P.el.capture(1:4), indicating which datatyes
% to record.
%
% Wanja Moessing 29/02/2016


%  Copyright (C) 2016 Wanja Mössing
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

Eyelink('Message', 'STOP_REC_4_RECAL');
% adds 100 msec of data to catch final events
WaitSecs(0.1);
Eyelink('StopRecording');

% you must call this function to apply the changes from above
EyelinkUpdateDefaults(P.el);

% Hide the mouse cursor;
HideCursor;

EyelinkDoTrackerSetup(P.el);
% clear tracker display and draw box at center
Eyelink('Command', 'clear_screen 0')
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.05);
% this can optionally take four boolean input values, specifiying
% the datatypes recorded (file_samples, file_events, link_samples, link_events)
%Eyelink('StartRecording',P.trackr.capture(1),P.trackr.capture(2),P.trackr.capture(3),P.trackr.capture(4));
Eyelink('StartRecording');