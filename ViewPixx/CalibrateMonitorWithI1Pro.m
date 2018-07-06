function [ output_args ] = CalibrateMonitorWithI1Pro(ScreenPointer)
%CALIBRATEMONITORWITHI1PRO creates a CLUT for the current monitor
%   Requires i1d3SDK64.dll, i1.mexw64, and Psychtoolbox
%   1. To install Psychtoolbox, ask google.
%   2. To get the low-level interfacing with the i1 to work, download 
%      http://www.vpixx.com/developer/setup_xrite.exe. 
%      On Windows (did not test other systems), this places the mex and dll
%      files in the following folders:
%      I1.mexw64: C:\Program Files\VPixx Technologies\Software Tools\
%                 i1ProToolbox_trunk\mexdev\build\matlab\win64
%      i1d3SDK64.dll and lib in: C:\Windows\SysWOW64
%      Copy both files to your folder.
%
%
%
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

% -------------------------------------------------------------------------
% 1. Check if X-Rite i1 Pro is connected and calibrate
% -------------------------------------------------------------------------
if I1('IsConnected')
    fprintf(['i1 detected!\nPlease place the photometer on the white',...
        'calibration tile and turn off light.',...
        '\nPress i1-button to calibrate!\n']);
    while ~I1('KeyPressed')
        % wait for keypress
    end
    disp('Starting calibration...')
    I1('Calibrate');
else
    error('X-rite i1 not detected. Try restarting the computer.')
end
disp('Finished calibration.')

% -------------------------------------------------------------------------
% 2. Setup Psychtoolbox
% -------------------------------------------------------------------------
AssertOpenGL;
KbName('UnifyKeyNames');
if nargin == 0
    ScreenPointer = max(Screen('Screens'));
end
monitor = Screen('Resolution', ScreenPointer);
center = [monitor.width, monitor.height] ./ 2;

wPtr = Screen(ScreenPointer, 'OpenWindow', [.5, .5, .5]);

info = Screen('GetWindowInfo', wPtr);
sca;
% -------------------------------------------------------------------------
% 3. Setup of the procedure
% -------------------------------------------------------------------------
% Sample at these intensities. Must be in 0:255 and must contain 0 & 255.
CAL.Intensities = 0:5:255;
assert(all(ismember([0 ,255], CAL.Intensities)));

% pre allocate space for gamma samples
TriStimDat  = zeros(length(CAL.Intensities), 3);
SpectralDat = zeros(length(CAL.Intensities), 36);

% generate initial linear gamma CLUT
linearCLUT = repmat(linspace(0, 1, 256)', 1, 3);

% save the original CLUT and apply the linear CLUT
preCLUT = Screen('LoadNormalizedGammaTable', wPtr, linearCLUT);


% -------------------------------------------------------------------------
% 4. Draw a target point and ask for the i1 to be placed on it
% -------------------------------------------------------------------------
instr = ['Please use the heavy strap to place to I1''s lense on\n'...
         'the target point (screen center)\nPress Space to start.'];
DrawFormattedText(wPtr, instr, 'center', centerY * 1.5);
Screen('DrawDots', wPtr, center, 200);
Screen('Flip', wPtr);
RestrictKeysForKbCheck(KbName('SPACE'));
KbWait;

% -------------------------------------------------------------------------
% 5. Loop over each of the Gamma intensities and take measurements
% -------------------------------------------------------------------------
for irow = length(CAL.Intensities)
    Screen('FillRect', wPtr, CAL.Intensities(irow));
    Screen('Flip', wPtr);
    I1('TriggerMeasurement');
    CAL.TriStimDat(irow, :)  = I1('GetTriStimulus');
    CAL.SpectralDat(irow, :) = I1('GetSpectrum');
end

CAL.Luminance = CAL.TriStimDat(:,1);
CAL.normLumi = (CAL.Luminance - min(CAL.Luminance))./range(CAL.Luminance);
save(['i1proOriginalLumi_' datestr(now,30)], 'Cal');

% -------------------------------------------------------------------------
% 6. Find the best fitting function for the measurements
% -------------------------------------------------------------------------
% fitType == 1:  Power function
% fitType == 2:  Extended power function
% fitType == 3:  Sigmoid
% fitType == 4:  Weibull
% fitType == 5:  Modified polynomial
% fitType == 6:  Linear interpolation
% fitType == 7:  Cubic spline
fitType = 7;
outputx = [0:255]';
[fit, x, comment] = FitGamma(Cal.indexvalues,Cal.normLumi,outputx,fitType);
    
    % invert gamma table
    invertedInput = InvertGammaTable(outputx,extendedFit,256);
    % expand inverse gamma to full 3-channel CLUT %
    inverseCLUT = repmat(invertedInput,1,3);
    inverseCLUT = inverseCLUT./max(inverseCLUT(:));
    
    save(['inverse_CLUT' datestr(now,30)], 'inverseCLUT');

end

