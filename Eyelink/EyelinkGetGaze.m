function [mx,my,hsmvd] = EyelinkGetGaze(P,IgnoreBlinks, OverSamplingBehavior)
% [mx,my,hsmvd,resp] = EYELINKGETGAZE(P)
% outputs the current gaze position captured by the eyelink 1000+
% Note that this function outputs Centercoordinates and hsmvd if no new
% sample is available.
%
% OUTPUT:
%   mx & my = x- & y-coordinates of gaze
%   hsmvd   = logical, true if gaze exceeds a threshold set in P.FixLenDeg,
%             is always 0, if P.FixLenDeg does not exist
%
% INPUT:
%   IgnoreBlinks          = Optional. If 1 (default), missing gaze position
%                           is replaced by the center coordinates of the
%                           screen. If 0, blinks cause mx & my to be Inf
%                           and hsmvd to 1.
%   OverSamplingBehavior  = Optional. Integer. Defines the value of hsmvd
%                           in case PTB samples faster than Eyelink.
%                           Default is '0'.
%   P.CenterX & P.CenterY = obvious...
%   P.el                  = Should have been created with EyelinkStart.m
%   P.FixLenDeg           = Integer, how many degree is gaze allowed to
%                           differ from center
%   P.pixperdeg           = How many pixels equal one degree?
%   P.isET                = If this is false => output is center + hsmvd=0
%
% Wanja Moessing, June 2016


%  Copyright (C) 2016 Wanja Mössing
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.

%set IgnoreBlinks default
if ~exist('IgnoreBlinks','var')
    IgnoreBlinks = 1;
end

if P.isET
    available = Eyelink('NewFloatSampleAvailable');
else
    available = 0;
end
if  available>0
    % get the sample in the form of an event structure
    evt = Eyelink('NewestFloatSample');
    if P.eye_used ~= -1 % do we know which eye to use yet?
        % if we do, get current gaze position from sample
        x = evt.gx(P.eye_used+1); % +1 as we're accessing MATLAB array
        y = evt.gy(P.eye_used+1);
        % do we have valid data and is the pupil visible?
        if x~=P.el.MISSING_DATA && y~=P.el.MISSING_DATA && evt.pa(P.eye_used+1)>0
            mx=x;
            my=y;
        elseif IgnoreBlinks %otherwise we'd get an error as soon as someone blinks
            mx=P.CenterX;
            my=P.CenterY;
        elseif ~IgnoreBlinks % if blinks shouldn't be ignored, set x&y to inf if data from el are missing
            [mx,my] = deal(Inf);
        end
    end
    % if gaze position is more than P.FixLenDeg degree away from
    % center, set hsmvd to 1
    if hypot(mx-P.CenterX,my-P.CenterY)>P.FixLenDeg*P.pixperdeg
        hsmvd = 1;
    else
        hsmvd = 0;
    end
    % activate this to monitor the input online
    %fprintf('Available EL data: X: %i Y: %i hsmvd:%i P.eye_used: %i\n',round(mx),round(my),hsmvd,P.eye_used)
else %if no new sample is available
    %fprintf('No data from Eyelink available!\n')
    mx=P.CenterX;
    my=P.CenterY;
    if exist('OverSamplingBehavior','var')
        hsmvd = OverSamplingBehavior;
    else
        hsmvd = 0;
    end
    
    
end
