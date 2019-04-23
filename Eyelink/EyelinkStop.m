function EyelinkStop(P, eyelinkconnected, outfolder)
% EYELINKSTOP performs the usual stopping routines for the Eyelink 1000+
% eyetracker. 
%
% INPUT:
%       'P': Structure with at least field P.trackr.edfFile, which should 
%            have been created with a previous call to EYELINKSTART
%       'eyelinkconnected': logical, defaults to true. If 0, the function
%                           is a dummy. Useful for testing.
%       'outfolder': String. Path where EDFs should be stored. Defaults to
%                    './Data/EyeData'. Folder is created on-the-fly.
%
%       'P.EDFdir': alternative way to specify outfolder
%       'P.isET': alternative way to specify eyelinkconnected
%
%
% Wanja Moessing 28/02/2016
% Wanja Moessing 07/02/2019: Implement Elio Balestrieri's suggestions

%  Copyright (C) 2016-2019 Wanja M�ssing
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

% check if output folder is specified
if nargin < 3 & ~isfield(P, 'EDFdir')
    outdir = ['.', filesep,'Data', filesep,'EyeData', filesep];
elseif nargin > 2
    outdir = outfolder;
elseif isfield(P, 'EDFdir')
    try
        [~, ~] = mkdir(P.trackr.out);
    catch
        warning(['EyelinkStop: Couldn''t create indicated ',...
            'folder. Will use ''./Data/EyeData/'' instead...']);
        outdir = ['.', filesep,'Data', filesep,'EyeData', filesep];
    end
end

% check if eyelink is not connected
if nargin < 2 & ~isfield(P, 'isET')
    eyelinkconnected = 1;
elseif isfield(P, 'isET')
    eyelinkconnected = P.isET;
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
        fprintf('Receiving Eyetrack data file ''%s''\n', P.trackr.edfFile);
        [~, ~] = mkdir(outdir);
        status = Eyelink('ReceiveFile', P.trackr.edfFile, outdir, 1);
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2 == exist(P.trackr.edfFile, 'file')
            foo = dir(outdir);
            foo = foo(1).folder;
            fprintf('Data file ''%s'' can be found in ''%s''\n',...
                P.trackr.edfFile, foo);
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