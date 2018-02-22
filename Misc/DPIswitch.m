function DPIswitch(On, factor)
%DPIswitch turns hiDPI scaling on or off
%
% Linux specific. You need to restart Matlab after running this script
% On = logical, turn hidpi on(1; default) or off(0)?
% factor = optional, can be a scaling factor.
%
% Wanja Moessing, moessing@wwu.de, Feb 2018

if nargin<1
    On = 1;
end

s = settings;

if nargin == 2
    s.matlab.desktop.DisplayScaleFactor.PersonalValue = factor;
elseif On
    s.matlab.desktop.DisplayScaleFactor.PersonalValue = 2.5;
else
    s.matlab.desktop.DisplayScaleFactor.PersonalValue = 1;
end



end

