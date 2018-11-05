function EyelinkStop(P, eyelinkconnected)
% EYELINKSTOP performs the usual stopping routines for the Eyelink 1000 plus
% eyetracker. Needs P.trackr.edfFile, which should have been created with a
% previous call to EYELINKSTART
%
% eyelinkconnected should be 0 or 1 (default). If 0, the function does
% nothing.
%
% Wanja Moessing 28/02/2016

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

% check if eyelink is not connected
if nargin < 2
    eyelinkconnected = 1;
end
if eyelinkconnected == 0
    disp('No Eyelink connected. No connection to close...');
    return
end

% check for dummy
if isfield(P, 'trackr')
    if ~isfield(P.trackr, 'dummymode')
        P.trackr.dummymode = 0;
    end
else
    P.trackr.dummymode = 0;
end

if P.trackr.dummymode == 0
    WaitSecs(0.1); %just making sure everything is recorded
    Eyelink('StopRecording');
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    
    % download data file
    try
        fprintf('Receiving Eyetracker data file ''%s''\n',...
            P.trackr.edfFile);
        [~,~,~] = mkdir('./Data', 'EyeData');
        status=Eyelink('ReceiveFile', P.trackr.edfFile,...
            './Data/EyeData/', 1);
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(P.trackr.edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n',...
                P.trackr.edfFile, pwd );
        end
    catch
        try
            fprintf(['Problem receiving data file ''%s''\ntry finding ',...
                'it on the Eyelink Host-PC!\n'], P.trackr.edfFile);
        catch
            fprintf(['Problem receiving data file.\nTry finding it on',...
                ' the Eyelink Host-PC!\n']);
        end
    end
end
Eyelink('ShutDown');