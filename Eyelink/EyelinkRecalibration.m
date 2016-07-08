function EyelinkRecalibration(P)
% performs recalibration of a connected Eyetracker after breaks etc
%
% needs P.el with all subfields introduced during the initial calibration
% called by startEyelink and P.el.capture(1:4), indicating which datatyes
% to record.
%
% Wanja Moessing 29/02/2016

Eyelink('Message', 'STOP_REC_4_RECAL');
% adds 100 msec of data to catch final events
WaitSecs(0.1);
Eyelink('StopRecording');

% you must call this function to apply the changes from above
EyelinkUpdateDefaults(P.el);

% Hide the mouse cursor;
Screen('HideCursorHelper', window);
EyelinkDoTrackerSetup(P.el);
% clear tracker display and draw box at center
Eyelink('Command', 'clear_screen 0')
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.05);
Eyelink('StartRecording',P.trackr.capture(1),P.trackr.capture(2),P.trackr.capture(3),P.trackr.capture(4));    
