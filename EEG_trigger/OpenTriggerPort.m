function OpenTriggerPort()
% OPENTRIGGERPORT defines a global io64 object to be used with SendTrigger
% This function is a fork of config_io to enable compatibility with old PTB
% scripts.
%
% Rewritten on 30.03.2016 by Wanja Moessing

global IO64PARALLELPORTOBJ;

%create IO64 interface object
IO64PARALLELPORTOBJ = io64();

%install the inpoutx64.dll driver
%status = 0 if installation successful
status = io64(IO64PARALLELPORTOBJ);
if(status ~= 0)
    disp('inp/outp installation failed!')
end
