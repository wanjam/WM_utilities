# -*- coding: utf-8 -*-
"""
WM_EyelinkWrapper.py
A custom module to make interaction with the eyelink 1000+ more
straightforward.

First Version July 2017
__author__ = "Wanja A. Mössing"
__copyright__ = "Copyright 2017, Institute for Experimental Psychology,
    WWU Münster, Germany"
__email__ = "moessing@wwu.de"
"""

# import dependencies to global
import pylink
from os import path, getcwd, stat, mkdir


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


def EyelinkCalibrate(dispsize, el=pylink.getEYELINK(),
                     colors=((0, 0, 0), (192, 192, 192))):
    """ Performs calibration for Eyelink 1000+.

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters:
    ----------
    dispsize : tuple
        two-item tuple width & height in px
    el :
        Eyelink object, optional
    colors  : Tuple, Optional.
        Tuple with two RGB triplets
    """
    # Sets the calibration target and background color
    pylink.setCalibrationColors(colors[0], colors[1])
    # Select best size for calibration target
    pylink.setTargetSize(int(dispsize[0]/70), int(dispsize[0]/300))
    pylink.setCalibrationSounds("", "", "")
    pylink.setDriftCorrectSounds("", "", "")
    pylink.openGraphics()
    el.doTrackerSetup()
    pylink.closeGraphics()


def EyelinkStart(dispsize, Name, bits=32, dummy=False,
                 colors=((0, 0, 0), (192, 192, 192))):
    """ Performs startup routines for the EyeLink 1000 Plus eyetracker.

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters:
    -----------
    dispsize : tuple
        two-item tuple width & height in px
    Name    : string
        filename for the edf. Doesn't have to, but can, end on '.edf'
        Maximum length is 8 (without '.edf').
        Possible alphanumeric input: 'a-z', 'A-Z', '0-9', '-' & '_'
    bits    : integer
        color-depth, defaults to 32
    dummy   : boolean
        Run tracker in dummy mode?
    colors  : Tuple, Optional.
        Tuple with two RGB triplets

    Returns
    -------
    'el' the tracker object.
             This can be passed to other functions,
             although they can use pylink.getEYELINK()
             to find it automatically.
    """

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

    # flush old keys
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
    if ELversion >= 2:
        el.sendCommand("select_parser_configuration 0")
    if ELversion == 2:
        # turn off scenelink stuff (that's an EL2 front-cam addon...)
        el.sendCommand("scene_camera_gazemap = NO")
    else:
        el.sendCommand("saccade_velocity_threshold = 35")
        el.sendCommand("saccade_acceleration_threshold = 9500")

    # set EDF file contents
    el.sendCommand("file_event_filter = LEFT,RIGHT,FIXATION,"
                   "SACCADE,AREA,BLINK,MESSAGE,BUTTON,INPUT")
    if ELsoftVer >= 4:
        el.sendCommand("file_sample_data = LEFT,RIGHT,GAZE,HREF,"
                       "AREA,HTARGET,GAZERES,STATUS,INPUT")
    else:
        el.sendCommand("file_sample_data = LEFT,RIGHT,GAZE,HREF,"
                       "AREA,GAZERES,STATUS,INPUT")

    # set link data (online interaction)
    el.sendCommand("link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,"
                   "AREA,BLINK,MESSAGE,BUTTON,INPUT")
    if ELsoftVer >= 4:
        el.sendCommand("link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,"
                       "HTARGET,STATUS,INPUT")
    else:
        el.sendCommand("link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,"
                       "STATUS,INPUT")

    # set file preamble
    currentdir = path.basename(getcwd())
    FilePreamble = "''Eyetracking Dataset AE Busch WWU Muenster Experiment: "
    FilePreamble += currentdir + "''"
    el.sendcommand("add_file_preamble_text " + FilePreamble)

    # run initial calibration
    # 13-Pt Grid calibration
    el.sendCommand('calibration_type = HV13')
    EyelinkCalibrate(el, dispsize, colors)

    # put tracker in idle mode and wait 50ms, then really start it.
    el.sendMessage('SETUP_FINISHED')
    el.sendCommand('set_idle_mode')
    el.sendCommand('clear_screen 0')
    pylink.msecDelay(500)

    # start recording
    el.startRecording()

    # to activate parallel port readout without modifying the FINAL.INI on the
    # eyelink host pc, uncomment these lines
    # tyical settings for straight-through TTL cable (data pins -> data pins)
    el.sendCommand('write_ioport 0xA 0x20')
    el.sendCommand('create_button 1 8 0x01 0')
    el.sendCommand('create_button 2 8 0x02 0')
    el.sendCommand('create_button 3 8 0x04 0')
    el.sendCommand('create_button 4 8 0x08 0')
    el.sendCommand('create_button 5 8 0x10 0')
    el.sendCommand('create_button 6 8 0x20 0')
    el.sendCommand('create_button 7 8 0x40 0')
    el.sendCommand('create_button 8 8 0x80 0')
    el.sendCommand('input_data_ports  = 8')
    el.sendCommand('input_data_masks = 0xFF')
    # tyical settings for crossover TTL cable (data pins -> status pins)
#    el.sendCommand('write_ioport 0xA 0x0')
#    el.sendCommand('create_button 1 9 0x20 1')
#    el.sendCommand('create_button 2 9 0x40 1')
#    el.sendCommand('create_button 3 9 0x08 1')
#    el.sendCommand('create_button 4 9 0x10 1')
#    el.sendCommand('create_button 5 9 0x80 0')
#    el.sendCommand('input_data_ports  = 9')
#    el.sendCommand('input_data_masks = 0xFF')

    # mark end of Eyelinkstart in .edf
    el.sendMessage('>EndOfEyeLinkStart')
    # return Eyelink object
    return(el)


def EyelinkStop(el=pylink.getEYELINK()):
    """ Performs stopping routines for the EyeLink 1000 Plus eyetracker.

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters:
    -----------
    dispsize : tuple
        two-item tuple width & height in px
    Name    : string
        filename for the edf. Doesn't have to, but can, end on '.edf'
        Maximum length is 8 (without '.edf').
        Possible alphanumeric input: 'a-z', 'A-Z', '0-9', '-' & '_'
    bits    : integer
        color-depth, defaults to 32
    dummy   : boolean
        Run tracker in dummy mode?
    colors  : Tuple, Optional.
        Tuple with two RGB triplets

    Returns
    -------
    'el' the tracker object.
             This can be passed to other functions,
             although they can use pylink.getEYELINK()
             to find it automatically.
    """
    # make sure all experimental procedures finished
    pylink.msecDelay(1000)
    # stop the recording
    el.stopRecording()
    # put Eyelink back to idle
    el.sendCommand('set_idle_mode')
    #
    # wait for stuff to finish
    pylink.msecDelay(500)
    # close edf
    el.closeDataFile
    # transfer edf to display-computer
    try:
        disp('Wait for EDF to be copied over LAN...')
        if not os.path.exists('./EDF'):
            os.mkdir('./EDF')
        
        