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


def EyelinkStart(P, window, Name, inputDialog, FilePreamble):
    """ Start connection to EL1000+
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
    if '.edf' not in Name:
        if len(Name) > 8:
            print('EDF filename too long! (1-8 characters/letters)')
            raise SystemExit
        else:
            Name += '.edf'
    elif '.edf' in Name:
        if len(Name) > 12:
            print('EDF filename too long! (1-8 characters/letters)')
            raise SystemExit

    # specify file preamble
    currentdir = path.basename(getcwd())
    FilePreamble = "''Eyetracking Dataset AE Busch WWU Muenster Experiment: "
    FilePreamble += currentdir + "''"

    # initialize tracker object
    eyelinktracker = pylink.EyeLink()

    # initialize graphics. This assumes display initialization.
    pylink.openGraphics()

    # Open EDF file on host
    getEyelink().openDataFile(Name)

    # flush all key presses and set tracker mode to offline.
    pylink.flushGetkeyQueue()
    getEYELINK().setOfflineMode()

    # Sets the display coordinate system and sends mesage to that
    # effect to EDF file;
    getEYELINK().sendCommand("screen_pixel_coords =  0 0 %d %d" %
                             (P.myWidth - 1, P.myHeight - 1))
    getEYELINK().sendMessage("DISPLAY_COORDS  0 0 %d %d" %
                             (P.myWidth - 1, P.myHeight - 1))
