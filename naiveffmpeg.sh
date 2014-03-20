#!/bin/bash

# ./gfachvideo.sh "C:/cygwin/home/Lenovo/tmp/pwd2.mp4" ble3

# convert a video file using ffmpeg
usage="Usage: `basename $0` [OPTIONS] [FILEIN] ([FILEOUT])"

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]; then 
	echo $usage
	echo "Convert a video file using ffmpeg with simple optimized compression options"
	echo ""
	echo "   -codec c         set codec by file format"
	echo "                       (\"mp4\" (x264, default),\"webm\")"	
	echo "   -quality q       set quality of compression "
	echo "                       (\"low\", \"med\" (default), \"high\") "
	echo "   -scale s         set output to input scaling ratio"
	echo "                       e.g. \"2:3\" for 1080p->720p conversion"
	echo "                       \"1:1\" is default"	
	echo "   -parallel        set parallel mode on, takes FILEIN as expression"
	echo "                       e.g. \"./*.MOV\" to convert all MOV files"	
	echo "                       no FILEOUT string allowed, overwrites mode on"
	echo "                       and any printed output sent to null"
	echo "   -filter f        set additional video filter"
	echo "                       e.g. \", frei0r=contrast0r:0.56\""
	echo "   -preopt pr       set extra ffmpeg options pre infile, .e.g \"-ss 00:00:10\""
	echo "   -postopt po      set extra ffmpeg options post infile, .e.g \"-t 8\""
	echo "   -nthreads n      set number of threads for process (3 default)"
	echo "   -movie           crop video to a 2.40:1 aspect ratio"
	echo ""
	echo "Examples: $ ./`basename $0` -webm -quality med -scale \"2:3\" ./videos/011.MOV ./tmp/test011"
	echo "          $ ./`basename $0` -quality high -parallel ./videos/*.MOV"
	exit
fi	

get_size()
{
	ffmpeg -i "$1" 2>&1 | perl -lane 'print $1 if /([0-9]{2,}x[0-9]+)/'
}
get_info()
{
	ffmpeg -i "$1" 2>&1 | grep Stream
}

# =================================


if [ "$1" = "-info" ]; then 
	get_info "$2"
	exit
fi	

####### default options #######

codec=mp4  # webm, mp4
scale="1:1"
parallel=0 		# 0=false, -y overwrites output files
movie=0
nthreads=3		# use default in ffmpeg if not specified?
quality=med		# low, med, high
preopt=""
postopt=""
filterin=""

####### get options #######

scale="2:3"
scaleo=${scale%:*}
scalei=${scale#*:}
codec=webm
quality=high
# parallel=1  # add parallel mode

preopt="-ss 00:00:10"
postopt="-t 8"

# filterin=", frei0r=contrast0r:0.56"

####### set file names #######

if [ $# -ne 1 ] && [ $# -ne 2 ]; then 		# variable supplied?
	echo $usage 1>&2
	exit 1 
fi

INFILE="$1"
shift
insize=$(get_size "$INFILE")
inpath=$(gfafilename -path "$INFILE")

if [ $# -eq 0 ]; then 
	OUTNAME=$(gfafilename -base "$INFILE")
	outfile=$inpath$OUTNAME
else
	OUTNAME="$1"
	outbase=$(gfafilename -base "$OUTNAME")
	if [ $outbase = "$OUTNAME" ]; then 
		outfile=$inpath$OUTNAME
	else  # a path
		outfile=$OUTNAME
	fi
fi


####### set options #######

in_w=${insize%x*}
in_h=${insize#*x}
out_h=$((in_h*$scaleo/$scalei))
out_w=$((in_w*$scaleo/$scalei))
refbitrate=2000 # K
refarea=$((1280*720))
bitrate=$((refbitrate*out_h*out_w/refarea))

filterstr="scale=-1:ih*$scaleo/$scalei"$filterin


if [ $quality = "low" ]; then 
	bitrate=$(echo $((bitrate/2)))K
elif [ $quality = "med" ]; then 
	bitrate=$(echo $bitrate)K
elif [ $quality = "high" ]; then 
	bitrate=$(echo $((bitrate*3/2)))K
fi

# low crf is better quality
if [ $codec = "webm" ]; then 
	codecstr="-vcodec libvpx -acodec libvorbis"
	outfile=$outfile.webm
	if [ $quality = "low" ]; then 
		qualstr="-vb $bitrate -ab 128k -crf 12 -qmin 8 -qmax 60"
	elif [ $quality = "med" ]; then 
		qualstr="-vb $bitrate -ab 160k -crf 8 -qmin 4 -qmax 56"
	elif [ $quality = "high" ]; then 
		qualstr="-vb $bitrate -ab 256k -crf 4 -qmin 0 -qmax 50"
	fi
elif [ $codec = "mp4" ]; then 
	codecstr="-vcodec libx264 -acodec libmp3lame"
	outfile=$outfile.mp4
	if [ $quality = "low" ]; then 
		qualstr="-vb $bitrate -ab 128k -crf 28 -qmin 10 -qmax 62"
	elif [ $quality = "med" ]; then 
		qualstr="-vb $bitrate -ab 160k -crf 22 -qmin 6 -qmax 58"
	elif [ $quality = "high" ]; then 
		qualstr="-vb $bitrate -ab 256k -crf 19 -qmin 3 -qmax 53"
	fi
fi



####### convert video #######

echo "converting:"
echo "$INFILE   ($in_w""x""$in_h) ->"
echo "$outfile   ($out_w""x""$out_h) at bitrate $bitrate"

if [ $parallel -eq 1 ]; then 
	ffmpeg $preopt -i "$INFILE" $postopt $qualstr -vf "$filterstr" $codecstr -threads $nthreads -y "$outfile" </dev/null > /dev/null 2>&1 &
else
	ffmpeg $preopt -i "$INFILE" $postopt $qualstr -vf "$filterstr" $codecstr -threads $nthreads -vframes 1000 "$outfile"
fi


exit
