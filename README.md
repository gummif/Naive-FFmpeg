Naive-FFmpeg
============

A simple command line FFmpeg wrapper for converting videos to .mp4 or .webm (in parallel). 
Set quality and scaling with simple parameters. The formats determine the codecs: mp4 for x264 and mp3lame; webm for VPx and vorbis.

Copyright (c) 2014 Gudmundur Adalsteinsson (GNU General Public License v3). See file LICENSE for license and warranty details.

Requirements
----------

 * [FFmpeg](http://www.ffmpeg.org) installed
 * [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) shell (for Windows users e.g. Cygwin)

Usage
----------

Multiple files can be converted and scaled easily in parallel. 
E.g., to convert a folder of 1080p .MOV videos to 720p .mp4 (with x264 encoding) in parallel using at most 4 threads (e.g. quad-core), simply excecute in Bash e.g.

` $ naiveffmpeg -mp4 -quality high -scale 2:3 -parallel 4 "*.MOV" `

or using the default parameters (-mp4 -quality med -scale 1:1)

` $ naiveffmpeg -parallel 4 "*.MOV" `

The program creates a new thread for every video file. The quality (low, med, high) determines the compression rate which has been optimized for the encoder type and video resolution.

Output example:
` $ naiveffmpeg -mp4 -quality high -parallel 7 "./*.MOV" `
```
-rw-r--r-- 1 gfa users  86214416 Jul 25 16:33 ./MVI_1402.MOV
-rw-r--r-- 1 gfa users  55929720 Jul 26 12:17 ./MVI_1425.MOV
-rw-r--r-- 1 gfa users 430840604 Jul 26 12:30 ./MVI_1426.MOV
-rw-r--r-- 1 gfa users 393173536 Jul 26 12:36 ./MVI_1427.MOV
-rw-r--r-- 1 gfa users 190708020 Jul 26 21:41 ./MVI_1445.MOV
-rw-r--r-- 1 gfa users  63936848 Jul 26 21:41 ./MVI_1446.MOV
-rw-r--r-- 1 gfa users 149726536 Jul 26 21:50 ./MVI_1447.MOV

converting 0:
./MVI_1402.MOV   (1920x1080) ->
./MVI_1402.mp4   (1920x1080) at bitrate 6750K
converting 1:
./MVI_1425.MOV   (1920x1080) ->
./MVI_1425.mp4   (1920x1080) at bitrate 6750K
converting 2:
./MVI_1426.MOV   (1920x1080) ->
./MVI_1426.mp4   (1920x1080) at bitrate 6750K
converting 3:
./MVI_1427.MOV   (1920x1080) ->
./MVI_1427.mp4   (1920x1080) at bitrate 6750K
converting 4:
./MVI_1445.MOV   (1920x1080) ->
./MVI_1445.mp4   (1920x1080) at bitrate 6750K
converting 5:
./MVI_1446.MOV   (1920x1080) ->
./MVI_1446.mp4   (1920x1080) at bitrate 6750K
converting 6:
./MVI_1447.MOV   (1920x1080) ->
./MVI_1447.mp4   (1920x1080) at bitrate 6750K

Converting 7 files using at most 7 threads...

bash -c ffmpeg  -i "./MVI_1402.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1402.mp4" </dev/null > /dev/null 2>&1 
bash -c ffmpeg  -i "./MVI_1425.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1425.mp4" </dev/null > /dev/null 2>&1 
bash -c ffmpeg  -i "./MVI_1426.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1426.mp4" </dev/null > /dev/null 2>&1 
bash -c ffmpeg  -i "./MVI_1427.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1427.mp4" </dev/null > /dev/null 2>&1 
bash -c ffmpeg  -i "./MVI_1445.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1445.mp4" </dev/null > /dev/null 2>&1 
bash -c ffmpeg  -i "./MVI_1446.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1446.mp4" </dev/null > /dev/null 2>&1 
bash -c ffmpeg  -i "./MVI_1447.MOV"  -vb 6750K -ab 256k -crf 19 -qmin 3  -qmax 53 -vf "scale=-1:ih*1/1" -vcodec libx264 -acodec libmp3lame -threads 1 -y "./MVI_1447.mp4" </dev/null > /dev/null 2>&1 
```


