function [P, window] = EyelinkStart(P, window, Name, inputDialog, FilePreamble, eyelinkconnected)
% EYELINKSTART performs startup routines for the EyeLink 1000 Plus
%
% [P, window] = EYELINKSTART(P, window, Name, inputDialog, FilePreamble)
%
% INPUT:
%   'P': struct with parameters. (all optional. struct can be empty)
%       'P.myWidth' & 'P.myHeight': Optional, (= Screen Resolution),
%       'P.BgColor': Background color, default: 0.5
%       'P.trackr.dummymode': 1=there's no real tracker connected (def.: 0)
%       'P.isET': 1(default) or 0. If 0, does nothing and returns.
%       'P.CalibLocations': Optional. Specify custom calibration grid.
%         example:
%           %x1,y1,[...],x9,y9 ;must be nine x-y pairs
%           X = P.CenterX;
%           A = P.PicWidth/2-20;
%           Y = P.CenterY;
%           B = P.PicHeight/2-20;
%           P.CalibLocations = [X-A,Y-B,  X,Y-B,  X+A,Y-B,...
%                               X-A,Y,    X,Y,    X+A,Y,...
%                               X-A,Y+B,  X,Y+B,  X+A,Y+B];
%       'P.binocular': optional boolean. Prepare the tracker to do
%                      binocular measurements? Default is 0 (monocular).
%
%       The following fields all have default values. They assure a
%       consistent setup and should only be specified in case you have good
%       reason to deviate from the default:
%       'P.binocular': boolean. 0 (default) = monocular
%       'P.heuristic_filter': char, default is '1 2' (as in DEFAULT.INI)
%       'P.active_eye': char, 'L' or 'R'
%       'P.pupil_size_diameter': char, 'AREA' (def.),'DIAMETER',..(see man)
%       'P.sampling_rate': int, 1000 (def.), 500, 250
%       'P.ellipse_mode': bool, 0 (def.) centroid, 1 is ellipse
%       'P.initial_thresholds': char, see SR programmers guide
%       'P.corneal_mode': bool, 1 (def.) use pupil-CR mode, 0 is pupil-only
%       'P.elcl_tt_power': float, Illuminator power. default is 1 (100%)
%
%   'window': PTB window pointer
%   'Name': char. Filename to which data are written. Check eyelink naming
%           conventions. If inputDialog is 1, you're prompted for a
%           filename, with 'Name' entered as default. Else, Name is simply
%           taken as filename.
%   'inputDialog': bool. Ask the user whether the filename is good (pop-up)?
%                  Default is 0 (don't ask).
%   'FilePreamble': Optional, specify an experiment-specific preamble in 
%                   the edf-files. Defaults to:'''Eyetracking Dataset AE 
%                   Busch WWU Muenster <current working directory>'''
%                   Always needs to start & end with <'''> (3x)
%   'eyelinkconnected': Optional boolean. If present, it overrides P.isET.
% 
%
% OUTPUT:
%   'P.el': Eyelink object. Necessary for interfacing the eyelink.
%   'P.eye_used': Which eye is being tracked?
%
% Wanja Moessing, June 2016
% WM: added FilePreamble on 26/09/2016
% WM: added custom calibrationpoints on 08/09/2017
% WM: add defaults and new documentation (22.08.2018)
% WM: add additional defaults to circumvent LASTRUN.INI 29/07/2019

%  Copyright (C) 2016-2019 Wanja Mössing
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


%% Parse Input %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist('eyelinkconnected', 'var')
    if eyelinkconnected
        P.isET = 1;
    else
        P.isET = 0;
    end
end

if ~isfield(P, 'isET')
    P.isET = 1;
elseif P.isET == 0
    disp('No Eyelink connected - no connection started.');
    return
end

if ~isfield(P, 'binocular')
    P.binocular = 0;
end
if ~isfield(P, 'heuristic_filter')
    P.heuristic_filter = '1 2';
end
if ~isfield(P, 'active_eye')
    P.active_eye = 'R';
end
if ~isfield(P, 'pupil_size_diameter')
    P.pupil_size_diameter = 0;
end
if ~isfield(P, 'sampling_rate')
    P.sampling_rate = 1000; %(250, 500, 1000, 2000) 
end
if ~isfield(P, 'ellipse_mode')
    P.ellipse_mode = 0;
end
if ~isfield(P, 'initial_thresholds')
    P.initial_thresholds = '66, 40, 66, 150, 150';
    disp('Image processing thresholds set to default.');
end
if ~isfield(P, 'corneal_mode')
    P.corneal_mode = 1;
end
if ~isfield(P, 'elcl_tt_power')
    P.elcl_tt_power = 1;
end


Screen(window, 'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


if ~isfield(P, 'myWidth')
    myres = Screen('Resolution', window);
    P.myWidth = myres.width;
end

if ~isfield(P, 'myHeight')
    myres = Screen('Resolution', window);
    P.myHeight = myres.height;
end

if ~isfield(P, 'BgColor')
    P.BgColor = 0.5;
end


if isfield(P, 'trackr')
    if ~isfield(P.trackr, 'dummymode')
        P.trackr.dummymode = 0;
    end
else
    P.trackr.dummymode = 0;
end

if isempty(regexp(Name,'.edf', 'once'))
    if length(Name) > 8
        error('EDF filename is too long.')
    else
        Name = strcat(Name,'.edf');
    end
elseif length(Name)>12 %8+4 ('.edf')
    Screen('CloseAll');
    error('EDF filename is too long.')
end

if ~exist('inputDialog','var')
    inputDialog = 0;
elseif isempty('inputDialog')
    inputDialog = 0;
end

if ~isfield(P, 'CalibLocations')
    P.CalibLocations = [];
end

if ~exist('FilePreamble','var')
    [~, currentFolder, ~] = fileparts(pwd);
    FilePreamble = ['''Eyetracking Dataset AE Busch WWU Muenster Experiment: ',currentFolder,''''];
elseif isempty('FilePreamble')
    [~, currentFolder, ~] = fileparts(pwd);
    FilePreamble = ['''Eyetracking Dataset AE Busch WWU Muenster Experiment: ',currentFolder,''''];
end

%make sure filepreamble is in the right format
quoteloc = regexp(FilePreamble,'''');
ErrText = ['The specified EDF Filename does not match the desired format. '...
        'Make sure that it`s one string with single quotation marks at'...
        ' beginning and end. To include single quotation marks in a string'...
        ' add two additional single quotation marks (so 3 in total).'];
if ~isempty(quoteloc)
    if  ~quoteloc(1)==1 || ~quoteloc(2)==length(FilePreamble)
        error(ErrText)
    end
else
    error(ErrText)
end

% get name for Eyetracker output
if inputDialog
    prompt = {'Please enter a filename for the Eyetracker EDF output.'};
    P.trackr.edfFile  = inputdlg(prompt,'Create EDF file',1,{Name});
    P.trackr.edfFile  = P.trackr.edfFile{1};
else
    P.trackr.edfFile = Name;
end

%name can only include alpha+digit+underscore------- -
if length(Name(1:strfind(Name,'.edf')-1))>8 || ~isempty(Name(regexp(Name(1:strfind(Name,'.edf')-1),'\W')))
    fprintf(2,'Eyelink EDF File does not match the requested format.\n Only [0-9], [A-z] and [_] are allowed.\n');
    CloseAndCleanup;
end

P.el = EyelinkInitDefaults(window);

% Open connection and throw an error if unsuccessful
if ~EyelinkInit(P.trackr.dummymode)
    fprintf('Eyelink Init aborted.\n');
    fprintf('Try to restart the Eyelink host PC.\n');
    CloseAndCleanup;  % cleanup function
    return;
end
[~,P.trackr.ETversion] = Eyelink('GetTrackerVersion'); %Store EL-Software version


% set EDF file contents using the file_sample_data and
% file-event_filter commands
% set link data thtough link_sample_data and link_event_filter
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,AREA,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,AREA,BLINK,MESSAGE,BUTTON,INPUT');

% check the software version
% add "HTARGET" to record possible target data for EyeLink Remote
if P.trackr.ETversion >=4
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
else
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
end

% Open File on EyeLink Host
if ~P.trackr.dummymode
    i = Eyelink('Openfile', P.trackr.edfFile);
    if i~=0
        fprintf('Cannot create EDF file ''%s'' ', P.trackr.edfFile);
        Eyelink( 'Shutdown');
        Screen('CloseAll');
        return;
    end
end
% write preamble to edf file

preamble = ['add_file_preamble_text ',FilePreamble];
Eyelink('command', preamble);
% tell tracker the screen resolution
Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, P.myWidth-1, P.myHeight-1);
Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, P.myWidth-1, P.myHeight-1);
Eyelink('command', 'calibration_type = HV9'); %9-Pt Grid calibration

% modify calibration and validation target locations
if ~isempty(P.CalibLocations)
    Eyelink('command', 'generate_default_targets = NO');
    T = P.CalibLocations;
    
    Eyelink('command','calibration_samples = 10');
    Eyelink('command','calibration_sequence = 0,1,2,3,4,5,6,7,8,0');
    Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
        T(9),T(10),  T(3),T(4),  T(15),T(16),  T(7),T(8),  T(11),T(12),...
        T(1),T(2),  T(5),T(6),  T(13),T(14),  T(17),T(18));
    Eyelink('command','validation_samples = 10');
    Eyelink('command','validation_sequence = 0,1,2,3,4,5,6,7,8,0');
    Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
        T(9),T(10),  T(3),T(4),  T(15),T(16),  T(7),T(8),  T(11),T(12),...
        T(1),T(2),  T(5),T(6),  T(13),T(14),  T(17),T(18));
else
    Eyelink('command', 'generate_default_targets = YES');
end

%% build setup defaults, to avoid having settings of a previous measurement

% always initiate the right Eye (just to have a default)
if strcmp(P.active_eye, 'R')
    Eyelink('command', 'active_eye = RIGHT');
elseif strcmp(P.active_eye, 'L')
    Eyelink('command', 'active_eye = LEFT');
end

% track monocular or binocular?
if P.binocular
    Eyelink('command', 'binocular_enabled = YES');	
else
    Eyelink('command', 'binocular_enabled = NO');	
end

% Use heuristic filtering?
Eyelink('command', 'heuristic_filter = %s', P.heuristic_filter);

% Convert pupil size to diameter?
if P.pupil_size_diameter
    Eyelink('command', 'pupil_size_diameter = DIAMETER');
else
    Eyelink('command', 'pupil_size_diameter = AREA');
end

% set default sampling rate
Eyelink('command', 'sample_rate = %d', P.sampling_rate);

% set centroid mode
if P.ellipse_mode
    Eyelink('command', 'use_ellipse_fitter = YES');
else
    Eyelink('command', 'use_ellipse_fitter = NO');
end

% set default graphical thresholds
Eyelink('command', 'initial_thresholds = %s', P.initial_thresholds);

% set to use pupil-corneal mode and not just pupil-only mode
if P.corneal_mode
    Eyelink('command', 'corneal_mode = YES');
else
    Eyelink('command', 'corneal_mode = NO');
end

% set Illuminator to 100%
Eyelink('command', 'elcl_tt_power = %d', P.elcl_tt_power); 

%% start calibration
% make sure we're still connected.
if Eyelink('IsConnected')~=1 && P.trackr.dummymode == 0
    fprintf('not connected, clean up\n');
    Eyelink('Shutdown');
    Screen('CloseAll');
    return;
end

% Calibrate the eye tracker
% setup the proper calibration foreground and background colors
if length(P.BgColor)==3
    P.el.backgroundcolor = P.BgColor;
elseif length (P.BgColor)==1
    P.el.backgroundcolour = [P.BgColor P.BgColor P.BgColor];
end
P.el.calibrationtargetcolour = [0 0 0];

% parameters are in frequency, volume, and duration
% set the second value in each line to 0 to turn off the sound
P.el.cal_target_beep=[600 0.5 0.05];
P.el.drift_correction_target_beep=[600 0.5 0.05];
P.el.calibration_failed_beep=[400 0.5 0.25];
P.el.calibration_success_beep=[800 0.5 0.25];
P.el.drift_correction_failed_beep=[400 0.5 0.25];
P.el.drift_correction_success_beep=[800 0.5 0.25];
% you must call this function to apply the changes from above
EyelinkUpdateDefaults(P.el);

% Hide the mouse cursor;
Screen('HideCursorHelper', window);
EyelinkDoTrackerSetup(P.el);

% The SR-example code continues with restarting recording each
% trial. I don't really see a reason why we shouldn't have
% continuous data with event-markers. So I'll just start recording
% once and send messages.

% put tracker in idle mode and wait 50ms, then really start it.
Eyelink('Message', 'SETUP_FINISHED');
Eyelink('Command', 'set_idle_mode');
Eyelink('Command', 'clear_screen 0'); %clear ET-host screen
WaitSecs(0.05);

% this can optionally take four boolean input values, specifiying
% the datatypes recorded (file_samples, file_events, link_samples, link_events)
%Eyelink('StartRecording',P.trackr.capture(1),P.trackr.capture(2),P.trackr.capture(3),P.trackr.capture(4));
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.05);
Eyelink('StartRecording');
% record a few samples before we actually start displaying
% otherwise you may lose a few msec of data
WaitSecs(0.1);

%set eye_used for gaze controla
P.eye_used = Eyelink('EyeAvailable'); % get eye that's tracked for gaze-control
if P.eye_used == P.el.BINOCULAR % if both eyes are tracked
    P.eye_used = P.el.LEFT_EYE; % use left eye
end

% to activate parallel port readout without modifying the FINAL.INI on the
% eyelink host pc, uncomment these lines
%%tyical settings for straight-through TTL cable (data pins -> data pins)
Eyelink('Command','write_ioport 0xA 0x20');
Eyelink('Command','create_button 1 8 0x01 0');
Eyelink('Command','create_button 2 8 0x02 0'); 
Eyelink('Command','create_button 3 8 0x04 0');   
Eyelink('Command','create_button 4 8 0x08 0'); 
Eyelink('Command','create_button 5 8 0x10 0'); 
Eyelink('Command','create_button 6 8 0x20 0'); 
Eyelink('Command','create_button 7 8 0x40 0'); 
Eyelink('Command','create_button 8 8 0x80 0'); 
Eyelink('Command','input_data_ports  = 8');
Eyelink('Command','input_data_masks = 0xFF');

%%tyical settings for crossover TTL cable (data pins -> status pins)
%Eyelink('Command','write_ioport 0xA 0x0');
%Eyelink('Command','create_button 1 9 0x20 1'); 
%Eyelink('Command','create_button 2 9 0x40 1'); 
%Eyelink('Command','create_button 3 9 0x08 1');   
%Eyelink('Command','create_button 4 9 0x10 1');
%Eyelink('Command','create_button 5 9 0x80 0'); 
%Eyelink('Command','input_data_ports  = 9');
%Eyelink('Command','input_data_masks = 0xFF');
 
Eyelink('Message', '>EndOfEyeLinkStart');