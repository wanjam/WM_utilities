function CloseTriggerPort()
% CLOSETRIGGERPORT deletes the io-Object
%
% My set of wrappers does not really require to unload a library. 
% So this function just exists, in case someone uses an old script
% that uses Nikos wrapper functions.
% 
% The one functionality it has, is deleting the global io64 object
% identifier.
% 
% Rewritten on 30.03.2016 by Wanja Moessing

clearvars -global IO64PARALLELPORTOBJ
