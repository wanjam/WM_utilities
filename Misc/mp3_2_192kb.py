#!/usr/bin/env python

from pydub import AudioSegment
from pydub.utils import mediainfo
from glob import glob
from os import path
from warnings import warn

# get all mp3 in current folder
mp3_files = glob('./*.mp3')


for i in range(0, len(mp3_files)):
    cur_mp3 = AudioSegment.from_file(mp3_files[i], 'mp3')
    outfile = path.splitext(mp3_files[i])[0] + '_192kb_' + '.mp3'
    
    if path.isfile(outfile):
        warn('File ' + outfile + ' already exists. Skipping...')
    else:
        id3tags = mediainfo(mp3_files[i]).get('TAG', {})
        cur_mp3.export(outfile, format = 'mp3', tags = id3tags, bitrate = '192k')