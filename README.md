# WM_utilities
wanja's utility functions

currently containing:
* Wrapperfunctions for sending TTL triggers from Matlab on MS Windows
  * this is based on io64 and similar to their functions but finetuned for
    our (and maybe many other EEG/Psychophysics-labs) purposes.
* Psychtoolbox functions to send TTL triggers via a ViewPixx /EEG
  * contains Pixxput, which converts a decimal number to an RGB value that
    triggers the respective binary code via the parallel port of the Monitor.
* Wrapper for PTB-Eyelink 1000 functions
  * makes life easier by including the most regular routines in just a few
    functions of the kind 'startingroutines'...experiment...'stopping routines'
  * also includes wrappers to get the current gaze position
* Code to read-in Biosemi .bdf files that have a 16bit event channel, that
  consists of two seperate 8-bit streams of input.
  * this is just an adaptation of eeglabs pop_fileio and fieldtrips ft_read_header
  * it's based on the files from eeglab 13_6_5b, so if the authors change stuff in future versions, that might cause trouble.