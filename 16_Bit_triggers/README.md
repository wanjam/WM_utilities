# Splitting a 16-bit trigger into two 8-bit trigger channels

Our lab uses a Biosemi Active two system. Theoretically, this system is capable of reading 24bit triggers. However, we only send 8bit triggers from our PC and additional 8bit triggers from our Monitor (a Viewpixx /EEG).
That is, pins 1-8 are PC triggers and pins 9-13 are the second device.
However, the resulting .bdf file contains a single(!) event-channel with both kinds of triggers clashed together to one 16bit channel.
To get rid of that mess, this folder contains a modified version of EEGlab's 'pop_fileio.m' and FieldTrip's 'fileio' plugin.

## Usage
* pop_fileio calls ft_read_event. This function depends on a lot of /private functions that come with the fileio-plugin. It therefore does not suffice to simply shadow pop_fileio.m & ft_read_event.m with the modified versions. Instead, these modified versions need to be located at exactly the same location as the original ones relative to the fileio plugin folder.
* If you only have a single 8bit triggerchannel in your file, this function will still provide the same output.
* The modified versions need much longer (on our server ~30s/file instead of ~5s/file)

### Option A: Only use this modified version
The simplest solution is to just replace 'pop_fileio.m' and 'ft_read_event.m' in your eeglab folder with the modified ones from this repository.
Obviously, you then cannot use the faster original version anymore.

### Option B: Create an optional copy
Just clone this repo and add it to your path AFTER(!) you called eeglab, so the whole fileio plugin-folder will be shadowed by the modified version.
e.g.,:
```
eeglab;
close all;

%un-shadow the fileio in WM-utilities
tmp = which('16_Bit_triggers/pop_fileio.m');
addpath(genpath(tmp(1:regexp(tmp,'pop_fileio.m')-1)));
```
