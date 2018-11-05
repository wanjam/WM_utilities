# Eyelink Wrappers

A collection of functions to make interacting with the Eyelink 1000+ during the experiment more straight-forward. All of these functions require the Eyelink C API included in SR-Research's developer pack.

## Install

### Matlab functions

Just add the directory to your path and call the .m-functions from within your Psychtoolbox script.

### Python functions

Place EyelinkWrapper.py and EyeLinkCoreGraphicsPsychoPy.py in your working directory.
import the EyelinkWrapper module at the top of your Psychopy script.

The EyelinkWrapper module requires SR's **pylink** module which is included in their **Eyelink Developers Kit**. Download the kit from their support forum and install it. The installation should place pylink modules somewhere on your computer (`C:\Users\Public\Documents\EyeLink\SampleExperiments\Python` on Windows). Simply copy the folder appropriate for your distribution of Python (most likely `pylink27-amd64`) to `python install path>\Lib\site-packages`. I use Anaconda with an environment called **psychopy**. So my destination looks like this: `C:\Users\moessing.IVV5NET\AppData\Local\Continuum\anaconda3\envs\psychopy\Lib\site-packages`. Finally, rename the copied folder to **pylink**. Note that there's a pip-installable package called *pylink*, which seems like the easier way to install it. It's not. Actually that package is completely unrelated.

Note: EyeLinkCoreGraphicsPsychoPy is developed, maintained and copyrighted by SR-Research and distributed under GPL. It is included here with SR-Research's permission. For the most recent version check their support forum.

---

## Usage

Note that this is probably quite specific to our lab. Use this in any other lab at your own risk.

### Matlab
The Matlab code consists of six simple functions: `EyelinkStart.m, EyelinkStop.m, EyelinkRecalibration.m, EyelinkgGetGaze.m, EyelinkControlFixation.m, and EyelinkAvoidWrongTriggers.m`

A typical workflow in Psychtoolbox would look like this:

1. Start your Experiment with the typical settings until you open a window. Typically, you'll have a line like this:  
  `wPtr = Screen('Openwindow', P.PresentScreen, [ 0.5, 0.5, 0.5 ],[],[],[],[],1);`  
2. Do whatever else you want to do with that window (e.g., load a CLUT)  
3. Start a connection to the Eyetracker with `EyelinkStart`  
  `EyelinkStart.m` requires a couple of input arguments. Here's a solution that should work for most circumstances. Check `doc EyelinkStart` in Matlab to get more information on the specific arguments.  
	`[P,wPtr] = EyelinkStart(P, wPtr, 'filename.dat');`  	  
  `P` is a struct which should contain a few parameters like width and height of the screen, background color etc. Again, check `doc EyelinkStart` for the specific subfields.
  Running this line of code will do the following:
   1. set the parallel port of the eyetracking host-pc to zero and to listening mode. This assures that the right triggers appear at the EEG-recording PC. Also, recording these triggers with the Eyelink host-pc is immensely helpful for later coregistration of EEG with ET data.  
   2. Tell the Eyetracker that all data possible should be stored.  
   3. Start the initial Calibration procedure and open the respective Screen on the computer  
   4. some more technical stuff - look into the code or ask me if you're interested.  
  
4. After calibration you'll return to your normal Psychtoolbox code. Typically, you'll reach a point where you'll loop over trials. 

5. Two things can happen:  
    0. (i) you want to control fixation on-line and have your experiment react to what the subject's eyes are doing **and/or** (ii) you want to recalibrate every now and then.
    1. Gaze control <br> You can simply use `EyelinkGetGaze.m`. Typically, you'd want to control where subjects look at between two screens. To do this, build up a scren and flip it. Now, you'd place a code like the one below between this and the code that builds the subsequent screen. A more high-leve version, that allows you to specify a maximum time until fixation must start, for how long fixation must be maintained and if you want a recalibration, whenever subjects don't fixate in time is `EyelinkControlFixation`. This is a one-liner, that is sufficient in most situations. Check it's documentation for usage instructions.
       ```matlab
       onset_time = Screen('Flip', wPtr);
       screen_time = 0.500 % time the current screen is supposed to be shown
       %Gaze control
       while GetSecs< onset_time + screen_time - .05 %50ms so the next window can be prepared
        [x, y, eye_moved] = EyelinkGetGaze(P);
        if eye_moved
         return
        end
       end
       ```
       This code simply keeps checking where the subject looks and returns the x & y coordinate (in screen pixels) of the current gaze. You can then use `x` & `y` to define whatever if statements you like. The third output argument, `eye_moved`, tells us whether the subject looked outside of some predefined window. You should define this window in `P` as `P.CenterX, P.CenterY, and P.FixLenDeg` (i.e., a (x,y)-coordinate and a circle with radius FixLenDeg around it).<br>*Note: it's called `CenterX & Y` but you can use any (x,y) pair you like.*<br>The while loop ends 50ms before the next flip should happen. This should be enough time to prepare the next screen.
      2. Recalibration<br>People move their heads. So it's wise to recalibrate after breaks. Do that with 'EyelinkRecalibration.m'.<br>Typically, you'd place a piece of code like this at the end of your break:  
    `EyelinkRecalibration(P)`  
    Here, `P` really only needs the subfield `P.el` which is created when running `EyelinkStart`  
    
6. Once your subject is done, run `EyelinkStop.m` **before** closing the Psychtoolbox-Screen.  
  Code should look something like this:  
	  ```matlab
	  EyelinkStop(P);
	  sca;
	  ```
	  `P` only needs subfield `P.trackr.edfFile`, which is the current filename and should have been created during the call to `EyelinkStart`.
	  `EyelinkStop` does the following:
  	1. it tells the eyetracker to stop recording
  	2. it copies the datafile from the tracker-pc to the stimulation-pc  
	
#### Special Case: `EyelinkAvoidWrongTriggers`

`EyelinkAvoidWrongTriggers` is a special case. When you turn on the Eyetracker but aren't using it, the crossed parallel-cables mess up the triggers. As we sometimes just turn on all the computers and then want to start an experiment, it's a good idea to place this code at the top of a non-eyetracking experiment that runs in our lab. It will throw an informative error, whenever you start the experiment and the eyetracker is turned on.
