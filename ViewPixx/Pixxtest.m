
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

AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
w=Screen('OpenWindow',max(Screen('Screens')));
load('inverse_CLUT20160517T114847.mat');
[oldCLUT,~] = Screen('LoadNormalizedGammaTable',w,inverseCLUT);

for i = 0:255
    PixxPut(w,i,inverseCLUT);
    Screen('Flip',w);
    WaitSecs(.2);
    Screen('FillRect',w,[0,0,0],[0,0,1,1]);
    Screen('Flip',w);
    WaitSecs(.05);
end
Screen('LoadNormalizedGammaTable',w,oldCLUT);
sca;