function SendTrigger(triggervalue, triggerduration, Port)
% SENDTRIGGER(triggervalue,triggerduration,Port) sends a trigger to a parallel port
%
% triggervalue: numerical value of trigger code to be sent (1-255).
% triggerduration: duration of the trigger signal in seconds (eg. 0.020).
% (optional) Port = hexadecimal version of port address (look it up in windows' device manager) 
%
% Rewritten on 30.03.2016 by Wanja Moessing

% use most common port address, if not supplied

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
