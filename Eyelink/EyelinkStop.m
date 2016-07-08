function EyelinkStop(P)
% EYELINKSTOP performs the usual stopping routines for the Eyelink 1000 plus
% eyetracker. Needs P.trackr.edfFile, which should have been created with a
% previous call to EYELINKSTART
%
% Wanja Moessing 28/02/2016

WaitSecs(0.1); %just making sure everything is recorded
Eyelink('StopRecording');
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.5);
Eyelink('CloseFile');

% download data file
try
    fprintf('Receiving Eyetracker data file ''%s''\n', P.trackr.edfFile );
    mkdir('./Data','EyeData')
    status=Eyelink('ReceiveFile',P.trackr.edfFile,'./Data/EyeData/',1);
    if status > 0
        fprintf('ReceiveFile status %d\n', status);
    end
    if 2==exist(P.trackr.edfFile, 'file')
        fprintf('Data file ''%s'' can be found in ''%s''\n', P.trackr.edfFile, pwd );
    end
catch
    fprintf('Problem receiving data file ''%s''\n try finding it on the Eyelink Host-PC!\n', P.trackr.edfFile );
end
Eyelink('ShutDown');