# -*- coding: utf-8 -*-
"""
WM_EyelinkWrapper.py
A custom module to make interaction with the eyelink 1000+ more
straightforward.

First Version July 2017
__author__ = "Wanja A. Mössing"
__copyright__ = "Copyright 2017, Institute for Experimental Psychology, WWU Münster, Germany"
__email__ = "moessing@wwu.de"
"""

#import dependencies to global
import pylink

def AvoidWrongTriggers():
    """ Throws an error if Eyelink is connected but not configured.
    Since we use a Y-cable, that is supposed to send the TTL-triggers from
    the PTB-PC to the EEG and he Eyetracker host, there is a permanent
    connection between the three parallelports (1. EEG, 2.PTB, 3.Eyelink).
    Therefore, all parallelports need to be set low, except for the one
    putting the triggers (i.e. PTB). The Eyelink host-pc sends a random
    trigger at startup if not configured properly. So if an experiment that
    doesn't use the Eyetracker sends a trigger to the EEG while the
    Eyetracker host-pc is turned on, that causes a wrong trigger in the EEG
    signal. EYELINKAVOIDWRONGTRIGGERS can be placed at the beginning of an
    experiment that doesn't use the eyelink to throw an error if the eyelink
    is still connected.
    """
    from os import system as sys
    from platform import system as sys_name
    print 'Pinging Eyelink to check if connected and powered...'

    if sys_name() == 'Windows':
        r = sys('ping -n 1 100.1.1.1')
    else:
        r = sys('ping -c 1 100.1.1.1')

    if r != 0:
        msg = """Eyelink host PC is turned on. Without running the appropriate
        startup routines (e.g., `EyelinkStart` from Wanja`s Github repo),
        this will cause faulty triggervalues in your EEG signal, because the
        parallel-port of the Eyelink-PC is set to a random value at startup
        instead of reading the port. Either turn off the Eyelink-PC or
        configure it!"""
        print(msg)
        raise SystemExit

def EyelinkCalibrate(el, dispsize, colors=((0,0,0),(192,192,192))):
    pylink.setCalibrationColors(colors[0], colors[1]) 	#Sets the calibration target and background color
    pylink.setTargetSize(int(dispsize[0]/70), int(dispsize[0]/300))	#select best size for calibration target
    pylink.setCalibrationSounds("", "", "")
    pylink.setDriftCorrectSounds("", "off", "off")
    pylink.openGraphics()
    el.doTrackerSetup()
    pylink.closeGraphics()

def EyelinkStart(dispsize, Name, bits=32, dummy=False, colors=((0,0,0),(192,192,192))):
    """ Start connection to EL1000+
    dispsize: two-item tuple width & height
    bits    : color-depth, defaults to 32
    
    Performs startup routines for the EyeLink 1000 Plus
    eyetracker. 'P' as input should P.myWidth & P.myHeight (= Scrn Resolution),
    P.BgColor (Background color of the experiment), and P.trackr.dummymode
    (1=there's no real tracker connected).
    window' refers to the current window pointer
    Name' is the filename to which data are written. Should end with
    .edf'. Must be called after first window has been flipped.
    If inputDialog is 1, you're prompted for a filename, with 'Name' entered
    as default. Else, Name is simply taken as filename.
    Can take the optional argument FilePreamble to specify an
    experiment-specific preamble in the edf-files. Defaults to:
    Eyetracking Dataset AE Busch WWU Muenster <current working directory>
    NOTE: FilePreamble always needs to start & end with <'''> (3x)
    Creates P.el & P.eye_used
    """
    # import modules that don't necessarily need to imported to global
    from os import path, getcwd

    # get filename
    if '.edf' not in Name.lower():
        if len(Name) > 8:
            print('EDF filename too long! (1-8 characters/letters)')
            raise SystemExit
        else:
            Name += '.edf'
    elif '.edf' in Name.lower():
        if len(Name) > 12:
            print('EDF filename too long! (1-8 characters/letters)')
            raise SystemExit

    # initialize tracker object
    if dummy:
        el = pylink.EyeLink(None)
    else:
        el = pylink.EyeLink("100.1.1.1")

    # initiate graphics
    pylink.openGraphics(dispsize, bits)
    
    # Open EDF file on host
    el.openDataFile(Name)
    
    #flush old keys
    pylink.flushGetkeyQueue()

    # Sets the display coordinate system and sends mesage to that
    # effect to EDF file;
    el.sendCommand("screen_pixel_coords =  0 0 %d %d" %
                             (dispsize[0] - 1, dispsize[1] - 1))
    el.sendMessage("DISPLAY_COORDS  0 0 %d %d" %
                             (dispsize[0] - 1, dispsize[1] - 1))



    # select parser configuration for online saccade etc detection
    ELversion = el.getTrackerVersion()
    ELsoftVer = 0
    if ELversion == 3:
        tmp = el.getTrackerVersionString()
        tmpidx = tmp.find('EYELINK CL')
        ELsoftVer = int(float(tmp[(tmpidx + len("EYELINK CL")):].strip()))
    if ELversion>=2:
        el.sendCommand("select_parser_configuration 0")
    if ELversion==2:
        # turn off scenelink stuff (that's an EL2 front-cam addon...)
        el.sendCommand("scene_camera_gazemap = NO")
    else:
        el.sendCommand("saccade_velocity_threshold = 35")
        el.sendCommand("saccade_acceleration_threshold = 9500")
	    
	
    # set EDF file contents 
    el.sendCommand("file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,AREA,BLINK,MESSAGE,BUTTON,INPUT")
    if ELsoftVer>=4:
	    el.sendCommand("file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT")
    else:
        el.sendCommand("file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT")

    # set link data (online interaction) 
    el.sendCommand("link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,AREA,BLINK,MESSAGE,BUTTON,INPUT")
    if ELsoftVer>=4:
	    el.sendCommand("link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT")
    else:
        el.sendCommand("link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT")
        
    #set file preamble
    currentdir = path.basename(getcwd())
    FilePreamble = "''Eyetracking Dataset AE Busch WWU Muenster Experiment: "
    FilePreamble += currentdir + "''"
    el.sendcommand("add_file_preamble_text " + FilePreamble)
    
    EyelinkCalibrate(el, dispsize, colors)
    
    #put tracker in idle mode and wait 50ms, then really start it.
    el.sendMessage('SETUP_FINISHED')
    el.sendCommand('set_idle_mode')
    el.sendCommand('clear_screen 0')
    pylink.msecDelay(500)
    
    #start recording
    el.startRecording()