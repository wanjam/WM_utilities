function [ inverseCLUT ] = CalibrateMonitorWithI1Pro(ScreenPointer)
%CALIBRATEMONITORWITHI1PRO creates a CLUT for the current monitor
%   Requires i1d3SDK64.dll, i1.mexw64, and Psychtoolbox
%   1. To install Psychtoolbox, ask google.
%   2. To get the low-level interfacing with the i1 to work, download
%      http://www.vpixx.com/developer/setup_xrite.exe.
%      On Windows (did not test other systems), this places the mex and dll
%      files in the following folders:
%      I1.mexw64: C:\Program Files\VPixx Technologies\Software Tools\
%                 i1ProToolbox_trunk\mexdev\build\matlab\win64
%      i1d3SDK64.dll in: C:\Windows\SysWOW64
%      i1Pro64.dll in:  C:\Program Files\VPixx Technologies\
%                       Software Tools\libi1Pro\x64
%      Copy both files to your folder.
%
%   Currently this function only takes care of luminance. That is, it
%   treats the monitor as monochromatic at RGB[.5,.5.,5] and finds the
%   luminance per proton-intensity 0-255.
%
%   Check this 2002 article if you want to know more about how calibration
%   works:
%   Brainard, D. H., Pelli, D. G. and Robson, T. (2002). Display
%    Characterization. In Encyclopedia of Imaging Science and Technology,
%    J. P. Hornak (Ed.). doi:10.1002/0471443395.img011
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
        ' calibration tile and turn off light.',...
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

wPtr = Screen(ScreenPointer, 'OpenWindow', 128);
HideCursor;


% -------------------------------------------------------------------------
% 3. Setup of the procedure
% -------------------------------------------------------------------------
% Sample at these (phosphor-)intensities.
% Must be in 0:255 and must contain 0 & 255.
% Recommendation is to sample at ~83 values (i.e., :3:)

CAL.Intensities = 0:51:255;%17%15%3
assert(all(ismember([0, 255], CAL.Intensities)));

% pre allocate space for gamma samples
CAL.TriStimDat  = zeros(length(CAL.Intensities), 3);
CAL.SpectralDat = zeros(length(CAL.Intensities), 36);

% generate initial linear gamma CLUT
linearCLUT = repmat(linspace(0, 1, 256)', 1, 3);

% save the original CLUT and apply the linear CLUT
preCLUT = Screen('LoadNormalizedGammaTable', wPtr, linearCLUT);
save(['PreviousCLUT' datestr(now, 29)], 'preCLUT');


% -------------------------------------------------------------------------
% 4. Draw a target point and ask for the i1 to be placed on it
% -------------------------------------------------------------------------
Screen('FillRect', wPtr, 128);
instr = ['Please use the heavy strap to place to I1''s lense on\n'...
    'the target point (screen center)\nPress Space to start.'];
DrawFormattedText(wPtr, instr, 'center', center(2) * 1.5);
Screen('DrawDots', wPtr, center, 50, 0, [], 1);
Screen('Flip', wPtr);
RestrictKeysForKbCheck(KbName('SPACE'));
KbWait;


% -------------------------------------------------------------------------
% 5. Loop over each of the Gamma intensities and take measurements
% -------------------------------------------------------------------------
% i1('GetTriStimulus') provides three values:
% L, the luminance in cd/m2,
% x, the CIE 1931 x-chromaticity
% y, the CIE 1931 y-chromaticity

for irow = 1:length(CAL.Intensities)
    fprintf('Measurement %i/%i\n', irow, length(CAL.Intensities))
    Screen('FillRect', wPtr, CAL.Intensities(irow));
    Screen('Flip', wPtr);
    failcount = 0;
    while true
        try
            % for some reason, this measurement fails every now and then.
            % It's not a normal error, so try catch alone doesn't do.
            % We need to reopen the PTB window as well.
            % This appears to be an error in the mex file. So nothing we
            % can do about it. It shouldn't mess with our measurements,
            % anyways.
            I1('TriggerMeasurement');
            break
        catch
            disp('Measurement failed. Trying again...')
            failcount = failcount + 1;
            if failcount > 5
                break
            end
            wPtr = Screen(ScreenPointer, 'OpenWindow', 128);
            Screen('LoadNormalizedGammaTable', wPtr, linearCLUT);
            HideCursor;
        end
    end
    CAL.TriStimDat(irow, :)  = I1('GetTriStimulus');
    CAL.SpectralDat(irow, :) = I1('GetSpectrum');
end

CAL.Luminance = CAL.TriStimDat(:,1);
CAL.normLumi = (CAL.Luminance - min(CAL.Luminance)) ./...
    range(CAL.Luminance);



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

RMSE = zeros(1, 7);
[fit, msg] = deal(cell(1, 7));
outlen  = (0:255)';
for fitType = 1:7
    try
        [fit{fitType}, ~, msg{fitType}] = ...
            FitGamma(CAL.Intensities', CAL.normLumi, outlen, fitType);
        tmpstr = strsplit(msg,'RMSE: ');
        RMSE(fitType) = str2double(tmpstr{2});
    catch ME
        disp(ME.message)
    end
end

% Which fit has the smallest root mean square error? That is, which of the
% functions above, fits our measured gamma increase best?
[~, bestfitindex] = min(RMSE);
dispmsg = sprintf(['%s seems to be the best option.\n',...
    'I''ll create a CLUT based on that function, load it,\n',...
    'and take another round of measurements, to validate that we get\n',...
    'a linearly increasing gamma table, once this CLUT is loaded.\n',...
    '\nLeave the i1 at the dot and press Space to proceed...'],...
    msg{bestfitindex});
DrawFormattedText(wPtr, dispmsg, 'center', center(2) * 1.5);
Screen('DrawDots', wPtr, center, 50, 0, [], 1);
Screen('Flip', wPtr);
RestrictKeysForKbCheck(KbName('SPACE'));
KbWait;


% The best fitting function created a gamma table that perfectly fit's our
% non-linear initial input. By inverting it, we should get linearity!
inverseFit = InvertGammaTable(outlen, fit{bestfitindex}, 256);

% Because we're ignoring color for now, we'll just apply our values to all
% three RGB columns.
inverseCLUT = repmat(inverseFit, 1, 3);

% convert to normalized RGB values
inverseCLUT = inverseCLUT./max(inverseCLUT(:));

% save the inverse CLUT
save(['inverse_CLUT_' datestr(now,29)], 'inverseCLUT');


% -------------------------------------------------------------------------
% 7. Take validation measurements
% -------------------------------------------------------------------------
Screen('LoadNormalizedGammaTable', wPtr, inverseCLUT);
for irow = 1:length(CAL.Intensities)
    fprintf('Measurement %i/%i\n', irow, length(CAL.Intensities))
    Screen('FillRect', wPtr, CAL.Intensities(irow));
    Screen('Flip', wPtr);
    failcount = 0;
    while true
        try
            I1('TriggerMeasurement');
            break
        catch
            disp('Measurement failed. Trying again...')
            failcount = failcount + 1;
            if failcount > 5
                break
            end
            wPtr = Screen(ScreenPointer, 'OpenWindow', 128);
            Screen('LoadNormalizedGammaTable', wPtr, inverseCLUT)
            HideCursor;
        end
    end
    CAL.inv.TriStimDat(irow, :)  = I1('GetTriStimulus');
    CAL.inv.SpectralDat(irow, :) = I1('GetSpectrum');
end

CAL.inv.Luminance = CAL.inv.TriStimDat(:,1);
CAL.inv.normLumi = (CAL.inv.Luminance - min(CAL.inv.Luminance)) ./...
    range(CAL.inv.Luminance);
save(['i1proMeasurements', datestr(now, 29)], 'CAL');
sca;
ShowCursor;


% -------------------------------------------------------------------------
% 8. Plot results and store as pdf
% -------------------------------------------------------------------------

% initial values and best fitting function
h = figure;
subplot(1, 2, 1);
plot(CAL.Intensities, CAL.normLumi, '*', 'Color', 'red'); % samples
line(outlen, inverseCLUT(:,1), 'Color', 'blue');  % best fitting function
xlabel('Intensity (0-255)');
ylabel('Normalized Luminance (0-1)');
title('First run samples and function fit');
axis('square');
annotation('textbox', [.2, .8, .4, .1], 'String', msg{bestfitindex},...
    'FitBoxToText', 1);

% Corrected gamma ramp
subplot(1, 2, 2);
plot(CAL.Intensities, CAL.inv.normLumi, '*', 'Color', 'green'); % samples
xlabel('Intensity (0-255)');
ylabel('Normalized Luminance (0-1)');
title('Samples taken with corrected CLUT');
axis('square');

h.PaperOrientation = 'landscape';
h.PaperType = 'A3';
print(h, ['i1proMeasurementPlots_', datestr(now, 29)],...
    '-dpsc','-fillpage');
end