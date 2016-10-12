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
if Eyelink('IsConnected')
    error(['Eyelink host PC is turned on. Without running the appropriate startup routines '...
        '(e.g., `EyelinkStart.m` from Wanja`s Github repo), this will cause faulty triggervalues'...
        ' in your EEG signal, because the parallel-port of the Eyelink-PC is set to a random'...
        ' value at startup instead of reading the port. Either turn off the Eyelink-PC or configure it!'])
end
end