#!/usr/bin/env python

from pydub import AudioSegment
from pydub.utils import mediainfo
from glob import glob
from os import path
from warnings import warn

# get all flacs in current folder
flac_files = glob('./*.flac')


for i in range(0, len(flac_files)):
    cur_flac = AudioSegment.from_file(flac_files[i], 'flac')
    outfile = path.splitext(flac_files[i])[0] + '.mp3'
    
    if path.isfile(outfile):
        warn('File ' + outfile + ' already exists. Skipping...')
    else:
        id3tags = mediainfo(flac_files[i]).get('TAG', {})
        cur_flac.export(outfile, format = 'mp3', tags = id3tags, bitrate = '192k')