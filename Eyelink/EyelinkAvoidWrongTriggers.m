function [] = EyelinkAvoidWrongTriggers
% EYELINKAVOIDWRONGTRIGGERS throws an error if Eyelink is connected but not
% configured.
%
% Since we use a Y-cable, that is supposed to send the TTL-triggers from
% the PTB-PC to the EEG and he Eyetracker host, there is a permanent
% connection between the three parallelports (1. EEG, 2.PTB, 3.Eyelink).
% Therefore, all parallelports need to be set low, except for the one
% putting the triggers (i.e. PTB). The Eyelink host-pc sends a random
% trigger at startup if not configured properly. So if an experiment that
% doesn't use the Eyetracker sends a trigger to the EEG while the
% Eyetracker host-pc is turned on, that causes a wrong trigger in the EEG
% signal. EYELINKAVOIDWRONGTRIGGERS can be placed at the beginning of an
% experiment that doesn't use the eyelink to throw an error if the eyelink
% is still connected.
%
% Wanja Moessing Oct 12, 2016

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

fprintf(2,'Pinging Eyelink to check if connected...\n');
[notConnected, Info] = dos(['ping 100.1.1.1 -n 1']);

if Eyelink('IsConnected') || ~notConnected
    error(['Eyelink host PC is turned on. Without running the appropriate startup routines '...
        '(e.g., `EyelinkStart.m` from Wanja`s Github repo), this will cause faulty triggervalues'...
        ' in your EEG signal, because the parallel-port of the Eyelink-PC is set to a random'...
        ' value at startup instead of reading the port. Either turn off the Eyelink-PC or configure it!'])
end
end