function CloseTriggerPort()
% CLOSETRIGGERPORT deletes the io-Object
%
% My set of wrappers does not really require to unload a library (on Windows). 
% So this function just exists, in case someone uses an old script
% that uses Nikos wrapper functions.
% 
% The one functionality it has (on Windows), is deleting the global io64 object
% identifier.
% 
% ON LINUX the port is actually closed by this function, so use it!
%
% Rewritten on 30.03.2016 by Wanja Moessing
% implemented Linux functions on Nov 29, 2016 (Wanja Moessing)


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
    clearvars -global IO64PARALLELPORTOBJ
elseif IsLinux
    clearvars -global TTLPORTOPEN
    ppdev_mex('CloseAll');
end

    