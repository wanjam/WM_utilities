function [nits, sRGB] = RGB_to_nits(RGB, CLUT, i1correctedLumi, i1correctedInt)
% RGB_TO_NITS() converts PTB RGB to candela per m²
%
% ONLY WORKS FOR GRAYSCALE (i.e., all 3 RGB values are the same!)
%
% Input:
%   RGB = 1x3 double RGB vector; can be sRGB (values should be 0-255 or 0-1)
%   CLUT = 256x3 double matrix; the CLUT used in experiment (only if sRGB
%          desired, else leave empty []);
%   i1correctedLumi = Nx1 double matrix; the Luminance measurements taken
%                     during calibration with the X-Rite i1 pro.
%                     Specifically the validation measurements after
%                     applying the CLUT used in the experiment. If you're
%                     using my CalibrateMonitorWithI1Pro.m function, this 
%                     will be in the 'i1proMeasurements...' file
%                     (CAL.inv.Luminance).
%   i1correctedInt = Nx1 double matrix; The indexes of the RGB intensities
%                    corresponding to the measurements specified in
%                    i1correctedLumi. If you used the function 
%                    'CalibrateMonitorWithI1Pro.m', this is
%                    CAL.Intensities
%
%  Copyright (C) 2019 Wanja Mössing
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

% check if RGB is sRGB
if all(RGB < 1)
    disp('assuming RGB values are sRGB...')
    RGB = round(RGB .* 255);
end

% get sRGB 
sRGB = [];
if ~isempty(CLUT)
    sRGB = [CLUT(RGB(1), 1), CLUT(RGB(2), 2), CLUT(RGB(3), 3)];
end

% use taken luminance measurements and interpolate the values, so we end up
% with an informed estimate per RGB intensity.
interpNits = interp1(i1correctedInt, i1correctedLumi, 0:255);

% get the luminance corresponding to the RGB value
if ~all(RGB == RGB(1))
    error('can''t handle color as CLUT correction was designed for grayscale');
end

% indexing does not start at 0 but at 1
nits = interpNits(RGB(1) + 1);

end