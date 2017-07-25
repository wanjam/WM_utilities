# -*- coding: utf-8 -*-
"""
WM_EyelinkWrapper.py
A collection of functions to make interaction with the eyelink 1000+ more
straightforward.

Created on Fri Jul 14 17:46:46 2017
@author: Wanja Moessing
"""


def AvoidWrongTriggers():
    """
    Throws an error if Eyelink is connected but not
    configured.

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
        startup routines (e.g., `EyelinkStart.m` from Wanja`s Github repo),
        this will cause faulty triggervalues in your EEG signal, because the
        parallel-port of the Eyelink-PC is set to a random value at startup
        instead of reading the port. Either turn off the Eyelink-PC or
        configure it!"""
        print(msg)
        raise SystemExit


def EyelinkStart(P, window, Name, inputDialog, FilePreamble):
    """
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
