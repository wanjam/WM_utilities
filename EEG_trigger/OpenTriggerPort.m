function OpenTriggerPort(portaddress)
% OPENTRIGGERPORT defines a global io64 object to be used with SendTrigger
% This function is a fork of config_io to enable compatibility with old PTB
% scripts.
%
% portaddress = portaddress on Linux. Usually you want to talk to port 1
% (default)
%
% you need to download Andreas Widmann's ppdev-mex repository and add it to
% the path!
% !git clone https://github.com/widmann/ppdev-mex.git
%
% Rewritten on 30.03.2016 by Wanja Moessing
% Implemented Linux-Compatibility on Nov 29, 2016 by Wanja Moessing (WWU Muenster)


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

if nargin==0
    portaddress = 1;
end

if IsWin
    global IO64PARALLELPORTOBJ;
    
    %create IO64 interface object
    IO64PARALLELPORTOBJ = io64();
    
    %install the inpoutx64.dll driver
    %status = 0 if installation successful
    status = io64(IO64PARALLELPORTOBJ);
    if(status ~= 0)
        disp('inp/outp installation failed!')
    end
end

if IsLinux
    try
        ppdev_mex('Open', portaddress);
        global TTLPORTOPEN
        TTLPORTOPEN = 1;
    catch ME
        fprintf(2,'opening the parallel port failed. Did you run Install_EEG_trigger.m and read the readme.m?\n');
        rethrow(ME);
    end
end