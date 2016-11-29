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

if IsWin
    clearvars -global IO64PARALLELPORTOBJ
elseif IsLinux
    clearvars -global TTLPORTOPEN
    ppdev_mex('CloseAll');
end

    