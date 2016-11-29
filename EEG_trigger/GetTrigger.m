function [value] = GetTrigger(Port)
% GETTRIGGER(Port) reads the trigger status of a parallel port
%
% (optional) Port = hexadecimal version of port address (look it up in windows' device manager)
%
% Rewritten on 30.03.2016 by Wanja Moessing
% Included error on Linux on Nov 29, 2016 by Wanja Moessing (moessing@wwu.de)

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