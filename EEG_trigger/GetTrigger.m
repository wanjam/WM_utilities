function [value] = GetTrigger(Port)
% GETTRIGGER(Port) reads the trigger status of a parallel port
%
% (optional) Port = hexadecimal version of port address (look it up in windows' device manager)
%
% Rewritten on 30.03.2016 by Wanja Moessing
% Included error on Linux on Nov 29, 2016 by Wanja Moessing (moessing@wwu.de)

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

% use most common port address, if not supplied

if IsWin
    global IO64PARALLELPORTOBJ;
    
    if nargin<1
        Port = hex2dec('0378');
    end
    
    if isempty(IO64PARALLELPORTOBJ)
        OpenTriggerPort; % create interface object and open connection if OpenTrigger hasn't been used before
    end
    
    value = io64(IO64PARALLELPORTOBJ, Port);
end


if IsLinux
    global TTLPORTOPEN;
    
    if nargin<1
        Port = 1;
    end
    
    if isempty(TTLPORTOPEN)
        OpenTriggerPort(Port); % open connection to parallelport
    end
    try
        ppdev_mex('Read', Port);
    catch
        error('ppdev_mex currently can''t read the port. Check Andreas Widmann''s repository for updates on this.');
    end
end

end