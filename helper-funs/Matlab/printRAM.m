function [RAM] = printRAM(unit)
%PRINTRAM prints current RAM usage
%   printRAM prints the current RAM usage to the console. Mainly useful for
%   loops to observe memory leaks and be able to estimate usage at the
%   beginning.
%
%   Input
%         unit: optional character. The unit to be used ('GB' (def.), 'MB',
%               'KB' or 'B')
%
%   Example:
%       k = ones(9, 9, 9, 9, 9, 9);
%       for i = 1:5
%           k = [k; k];
%           printRAM('MB');
%       end
% author: Wanja Moessing, moessing@wwu.de, September 2019

%  Copyright (C) 2019 Wanja Moessing
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

if nargin < 1
    unit = 'GB';
end

if isunix
    [~,totRAM] = system('free -m | awk ''/Mem:/ { print$2 }''');
    [~,usedRAM] = system('free -m | awk ''/Mem:/ { print$3 }''');
    RAM = cellfun(@str2num, {totRAM, usedRAM});
elseif ispc
    [~, freeRAM] = system('wmic os get freephysicalmemory');
    [~, totRAM] = system('wmic ComputerSystem get TotalPhysicalMemory');
    RAM(2) = round(str2num(freeRAM(regexp(freeRAM, '\d')))/1024);
    RAM(1) = round(str2num(totRAM(regexp(totRAM, '\d')))/1024^2);
end

switch unit
    case 'GB'
        RAM = RAM./1024;
    case 'KB'
        RAM = RAM.*1024;
    case 'B'
        RAM = RAM.*1024^2;
    case 'MB'
        % is already MB
end
fprintf('\n%.2f/%.0f%s RAM in use (%.2f%%)\n',...
    RAM(2), RAM(1), unit, (RAM(2)/RAM(1))*100);
end

