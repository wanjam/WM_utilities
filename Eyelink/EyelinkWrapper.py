# -*- coding: utf-8 -*-
"""
A custom module to make interaction with the eyelink 1000+ more
straightforward. Depends on the **pylink** module that ships with SR-Research's
'Developer Pack'. After installation, you will have folder containing this
module somewhere on your computer. Make sure to copy it to the
``site-packages`` folder of your python distribution.
Official Python repositories include another module called *pylink*, which is
absolutely unrelated. So ``pip`` or ``conda install`` won't work!

**Author** :
    Wanja Mössing, WWU Münster | moessing@wwu.de
**Version**:
    July 2017
**copyright** :
    Copyright 2017, Institute for Experimental Psychology, WWU Münster, Germany
"""

# import dependencies to global
import pylink
from os import path, getcwd, mkdir
from numpy import sqrt as np_sqrt, sum as np_sum, array as np_array

def AvoidWrongTriggers():
    """ Throws an error if Eyelink is connected but not configured.\n
    *Only needed in EEG experiments without Eyetracking!*

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Since we use a Y-cable which is supposed to send the TTL-triggers from
    the Python-PC to EEG & Eyetracker host, there is a permanent
    connection between the three parallelports (1. EEG, 2.Python, 3.Eyelink).
    Therefore, all parallelports need to be set low, except for the one
    putting the triggers (i.e. Python). The Eyelink host-pc sends a random
    trigger at startup if not configured properly. So if an experiment that
    doesn't use the Eyetracker sends a trigger to the EEG while the
    Eyetracker host-pc is turned on, that causes a wrong trigger in the EEG
    signal. This function can be placed at the beginning of an
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
    return


def EyelinkCalibrate(dispsize, el=pylink.getEYELINK(),
                     colors=((0, 0, 0), (192, 192, 192)), bits=32):
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
    bits    : integer
        color-depth, defaults to 32
    """
    # open eyelink host graphics
    pylink.openGraphics(dispsize, bits)
    # Sets the calibration target and background color
    pylink.setCalibrationColors(colors[0], colors[1])
    # Select best size for calibration target
    pylink.setTargetSize(int(dispsize[0]/70), int(dispsize[0]/300))
    pylink.setCalibrationSounds("", "", "")
    pylink.setDriftCorrectSounds("", "", "")
    pylink.openGraphics()
    el.doTrackerSetup()
    pylink.closeGraphics()
    return


def EyelinkDriftCheck(TargetLoc, el=pylink.getEYELINK()):
    """ Performs drift check for Eyelink 1000+.

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters:
    ----------
    TargetLoc : tuple
        two-item tuple x & y coordinates of the target in px
        Usually screen center
    el :
        Eyelink object, optional

    Returns:
    --------
    Success: bool
        was driftcheck successful?
    """
    el = pylink.EyeLink("100.1.1.1")
    success = True
    while 1:
        # if EL is connected in normal or broadcast mode
        if el.isConnected() not in (1, 2):
            success = False
            return
        # run check
        status = el.doDriftCorrect(TargetLoc[0], TargetLoc[1], 1, 1)
        # check how driftcorrection went
        if status is pylink.TERMINATE_KEY:
            success = False
        if status is not pylink.ESC_KEY:
            break
    return success


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

    # set to realtime mode
    pylink.beginRealTimeMode(200)
    # start recording
    # note: sending everything over the link *potentially* causes buffer
    # overflow. However, with modern PCs and EL1000+ this shouldn't be a real
    # problem
    el.startRecording(1, 1, 1, 1)

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
    el.getNewestSample()
    # mark end of Eyelinkstart in .edf
    el.sendMessage('>EndOfEyeLinkStart')
    # return Eyelink object
    return el


def EyelinkStop(Name, el=pylink.getEYELINK()):
    """ Performs stopping routines for the EyeLink 1000 Plus eyetracker.

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters:
    -----------
    Name    : string
        filename of the edf. Doesn't have to, but can, end on '.edf'
        Must be the same name used during EyelinkStart()
    el : Eyelink Object
        Eyelink object returned by EyelinkStart().
        By default this function tried to find it itself.
    """
    # Check filename
    if '.edf' not in Name.lower():
            Name += '.edf'
    # stop realtime mode
    pylink.endRealTimeMode(200)
    # make sure all experimental procedures finished
    pylink.msecDelay(1000)
    # stop the recording
    el.stopRecording()
    # put Eyelink back to idle
    el.setOfflineMode()
    # wait for stuff to finish
    pylink.msecDelay(500)
    # close edf
    el.closeDataFile()
    # transfer edf to display-computer
    try:
        print('Wait for EDF to be copied over LAN...')
        if not path.exists('./EDF'):
            mkdir('./EDF')
        el.receiveDataFile(Name, './EDF/'+Name)
        print('Done. EDF has been copied to ./EDF folder.')
    except RuntimeError:
        print('Error while pulling EDF file. Try to find it on Eyelink host..')
    el.close()
    pylink.closeGraphics()
    return


def EyelinkGetGaze(targetLoc, FixLen, el=pylink.getEYELINK(),
                   isET=True, PixPerDeg=[], IgnoreBlinks=False,
                   OversamplingBehavior=None):
    """ Online gaze position output and gaze control for Eyelink 1000+.

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters
    ----------
    targetLoc : tuple
        two-item tuple x & y coordinates in px; defines where subject should
        look at.
    FixLen : int
        A circle around a specified point is set as area that subjects are
        allowed to look at. ``FixLen`` defines the radius of that circle.
        Can be in degree or pixels. If ``PixPerDeg`` is not empty, assumes
        degree, else pixels.
    el: Eyelink object
        ...as returned by, e.g., ``EyelinkStart()``. You can try to run it
        without passing ``el``. In that case ``EyelinkGetGaze()`` will try to
        find ``el``.
    isET: boolean, default=True
        Is Eyetracker connected? If ``False``, returns display center as
        coordinates and ``hsmvd=False``.
    PixPerDeg: float
        How many pixels per one degree of visual angle? If provided, ``FixLen``
        is assumed to be in degree.
    IgnoreBlinks: boolean, default=False
        If True, missing gaze position is replaced by center coordinates.
    OversamplingBehavior: None
        Defines what is returned if nothing new is available.

    Returns
    -------
    GazeInfo: dict
        Dict with elements ``x``,``y``, and ``hsmvd``. ``x`` & ``y`` are gaze
        coordinates in pixels. ``hsmvd`` is boolean and defines whether gaze
        left the circle set with FixLen.
    """
    # IF EYETRACKER IS CONNECTED...
    if isET:
        # This is just for clarity
        RIGHT_EYE = 1
        LEFT_EYE = 0
        BINOCULAR = 2

        # ---------- deprecated but maybe useful later...----------------------
        # check if new data available via link
        # eventType = el.getNextData()
        # if it's a saccade or fixation, get newest gaze data available
        # if eventType in {pylink.STARTFIX, pylink.FIXUPDATE, pylink.ENDFIX,
        #                 pylink.STARTSACC, pylink.ENDSACC}:
        # if it's a blink, adjust output accordingly
        # elif eventType in {pylink.STARTBLINK,pylink.ENDBLINK}:
        # ---------------------------------------------------------------------

        # Get the newest data sample
        sample = el.getNewestSample()
        # get the newest event
        event = el.getNextData()
        # returns none, if no new sample available
        if sample is not None:
            # check which eye has been tracked and retrieve data for this eye
            if el.eyeAvailable() is LEFT_EYE:
                # getGaze() return Two-item tuple in the format of
                # (float, float). -> (x,y) in px
                # getPupilSize return float in arbitrary units. The meaning of
                # this depends on the settings made (area or diameter)
                gaze = sample.getLeftEye().getGaze()
                pupil = sample.getLeftEye().getPupilSize()
            elif el.eyeAvailable() is RIGHT_EYE:
                gaze = sample.getRightEye().getGaze()
                pupil = sample.getRightEye().getPupilSize()
            elif el.eyeAvailable() is BINOCULAR:
                print 'Binocular mode not yet implemented'
                return None
            else:
                raise Exception('Could not detect which eye has been tracked')

            # Check if subject blinks or if data are just randomly missing
            if pylink.MISSING_DATA in gaze:
                # check how sure we are whether it is a blink
                if event is pylink.STARTBLINK:
                    print('Subject is definitely blinking')  # debugging
                    blinked = True
                elif pupil == 0:
                    print('Subject is probably blinking')  # debugging
                    blinked = True
                else:
                    print('Missing data but no blink?')  # debugging
                    blinked = False
                # assign values accordingly
                if blinked and not IgnoreBlinks:
                    hsmvd = True
                elif blinked and IgnoreBlinks:
                    hsmvd = False
                    gaze = targetLoc
                elif not blinked:
                    hsmvd = True
            else:
                # transform location data to numpy arrays, so we can calculate
                # euclidean distance
                a = np_array(targetLoc)
                b = np_array(gaze)
                # get euclidean distance in px
                dist = np_sqrt(np_sum((a-b)**2))
                # check if we know how many px form one degree.
                # If we do, convert to degree
                if PixPerDeg is not []:
                    dist = dist/PixPerDeg
                # Now check whether gaze is in allowed frame
                hsmvd = dist >= FixLen

            # return dict
            return {'x': gaze[0], 'y': gaze[1], 'hsmvd': hsmvd,
                    'pupilSize': pupil}
        # If no new sample is available return None
        elif sample is None:
            return None
    # IF EYETRACKER NOT CONNECTED RETURN TARGETLOCATION AND NO PUPIL SIZE
    elif not isET:
        return {'x': targetLoc[0], 'y': targetLoc[1], 'hsmvd': False,
                'pupilSize': None}


def EyelinkSendTabMsg(infolist, el=pylink.getEYELINK()):
    """ Sends tab-delimited message to EDF

    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *July 2017*

    Parameters
    ----------
    infolist : list
        a list with information. The first item in the list is used as
        event-definition (e.g., ['trialOnset', 1, 'Condition X', 0.78])
        Can take strings, integers, floats
    el: Eyelink object
        ...as returned by, e.g., EyelinkStart()
    """
    # prepend identifier if necessary
    if infolist[0] is not '>':
        infolist.insert(0, '>')
    # make it a tab delimited list and convert everything to string
    msg = '\t'.join(str(i) for i in infolist)
    # send to Eyetracker
    el.sendMessage(msg)
    return
























