function SendTrigger(triggervalue, triggerduration, Port)
% SENDTRIGGER(triggervalue,triggerduration,Port) sends a trigger to a parallel port
%
% triggervalue: numerical value of trigger code to be sent (1-255).
% triggerduration: duration of the trigger signal in seconds (eg. 0.020).
% (optional) Port = hexadecimal version of port address (look it up in
% windows' device manager) | on Linux it's usually a single number (1 for
% the first port, 2 for the 2nd etc)
%
% Rewritten on 30.03.2016 by Wanja Moessing
% adapted for Linux on Nov 29, 2016 by Wanja Moessing
%
% uses most common port address, if not supplied


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

if IsWin
global IO64PARALLELPORTOBJ;

if nargin<3
    Port = hex2dec('0378');
end

if isempty(IO64PARALLELPORTOBJ)
    OpenTriggerPort; % create interface object and open connection
end
    
    
io64(IO64PARALLELPORTOBJ,Port,triggervalue) %output command
WaitSecs(triggerduration);
io64(IO64PARALLELPORTOBJ,Port,0) %null command
end

if IsLinux
    if nargin<3
        Port = 1;
    end
    
    global TTLPORTOPEN
    if isempty(TTLPORTOPEN)
        OpenTriggerPort(Port); % open connection to parallelport
    end

    ppdev_mex('Write', Port, triggervalue);
    WaitSecs(triggerduration);
    ppdev_mex('Write', Port, 0);
end