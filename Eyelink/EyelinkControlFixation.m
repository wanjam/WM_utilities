function [didrecal, FixationOnset] = EyelinkControlFixation(P, Tmin,...
    Tmax, loc, maxDegDeviation, eyelinkconnected, pixperdeg, dorecal,...
    IgnoreBlinks)
%EYELINKCONTROLFIXATION controls that a subject looks at the desired
%location.
%
% [didrecal, FixationOnset] = EyelinkControlFixation(P, Tmin, Tmax, loc,
%                             maxDegDeviation, eyelinkconnected, pixperdeg)
%
% INPUT:
%   P                 = Struct with field P.el created during EyelinkStart
%   Tmin              = mininum time a subject should look at loc
%   Tmax              = maximum time after which, in case of no fixation at
%                       target, a recalibration is started and
%                       'didrecal' = 1 returned.
%   loc               = [x, y] target location in px coordinates
%   maxDegDeviation   = how many degree is the subject allowed to deviate
%                       from the target?
%   eyelinkconnected  = if it's not connected (0), function does nothing
%                       and simply returns current time.
%   pixperdeg         = how many pixels form one degree?
%   dorecal           = if true (default), see Tmax. If false, didrecal is 
%                       still 1, but no recalibration ist started. 
%   IgnoreBlinks      = Default is false. If true, will keep counting until
%                       Tmin, as if subject would keep fixating, even when
%                       subject blinks.
%
%
% OUTPUT:
%   didrecal          = Is 1, in case the subject did not fixate for Tmax
%                       and we recalibrated.
%   FixationOnset     = Time, when the subject started fixating at target.
%
% Wanja Moessing, moessing@wwu.de, July 2018

%  Copyright (C) 2018 Wanja Mössing
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

% set defaults

if nargin < 8
    dorecal = true;
end

if nargin < 9
    IgnoreBlinks = false;
end

% wait for fixation
didrecal = 0;
StartFixationControlTime = GetSecs;
if eyelinkconnected
    % keep checking gaze
    while true
        % we start by assuming the subject did not look at desired location
        badgaze = 1;
        while badgaze == 1
            % as long as gaze is not as desired, keep checking
            if GetSecs - StartFixationControlTime > Tmax
                % once a maximum is exceeded, we assume tracker lost
                % subject and run a recalibration. After that, we return to
                % caller and inform the caller that we had to run a recal.
                Beeper(400,20,0.1);
                if dorecal
                    EyelinkRecalibration(P);
                    Eyelink('Message', 'SYNCTIME');
                end
                didrecal = 1;
                return;
            end
            % Get current gaze position and check if in boundaries
            [~, ~, badgaze] = EyelinkGetGaze(P, 0, [], loc,...
                maxDegDeviation, eyelinkconnected, pixperdeg);
        end
        % if in boundaries, start to count time and check if it stays in
        % boundaries
        FixationOnset = GetSecs;
        hsmvd = 0;
        while ~hsmvd
            [x,y,hsmvd] = EyelinkGetGaze(P, 0, [], loc,...
                maxDegDeviation, eyelinkconnected, pixperdeg);
            if hsmvd && IgnoreBlinks && x==Inf && y==inf
                hsmvd = 0;
            end
            if GetSecs >= (FixationOnset + Tmin - 0.050)
                break;
            end
        end
    end
else
    FixationOnset = GetSecs;
end

end

