Naive-FFmpeg
============

A simple command line FFmpeg wrapper for converting videos to .mp4 or .webm (in parallel). 
Set quality and scaling with simple parameters. The formats determine the codecs: mp4 for x264 and mp3lame; webm for VPx and vorbis.

Multiple files can be converted and scaled easily in parallel. 
E.g., to convert 1080p .MOV videos to 720p .mp4 (with x264 encoding) in parallel, simply excecute in Bash

` $ ./naiveffmpeg.sh -codec mp4 -quality high -scale 2:3 -parallel ./videos/*.MOV `

The program creates a new thread for every video file. 
The quality (low, med, high) determines the compression rate which has been optimized for the encoder type and video resolution.
	
ATTENTION
----------
Not in a fully working condtion as is.

Requirements
----------

 * FFmpeg installed
 * Bash shell (for Windows users e.g. Cygwin)



