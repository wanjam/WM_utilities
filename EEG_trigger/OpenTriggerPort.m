function OpenTriggerPort(portaddress)
% OPENTRIGGERPORT defines a global io64 object to be used with SendTrigger
% This function is a fork of config_io to enable compatibility with old PTB
% scripts.
%
% portaddress = portaddress on Linux. Usually you want to talk to port 1
% (default)
%
% you need to download Andreas Widmann's ppdev-mex repository and add it to
% the path!
% !git clone https://github.com/widmann/ppdev-mex.git
%
% Rewritten on 30.03.2016 by Wanja Moessing
% Implemented Linux-Compatibility on Nov 29, 2016 by Wanja Moessing (WWU Muenster)

if nargin==0
    portaddress = 1;
end

if IsWin
global IO64PARALLELPORTOBJ;

%create IO64 interface object
IO64PARALLELPORTOBJ = io64();

%install the inpoutx64.dll driver
%status = 0 if installation successful
status = io64(IO64PARALLELPORTOBJ);
if(status ~= 0)
    disp('inp/outp installation failed!')
end
end

if IsLinux
    try
    ppdev_mex('Open', portaddress);
    global TTLPORTOPEN
    TTLPORTOPEN = 1;
    catch ME
        fprintf(2,'opening the parallel port failed. Did you run Install_EEG_trigger.m and read the readme.m?\n');
        rethrow(ME);
    end
end