#!/bin/bash

#    Naive-FFmpeg converts and compresses video files using ffmpeg
#    Copyright (C) 2014  Gudmundur Adalsteinsson
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

shellname="bash"
usage="Usage: `basename $0` [OPTIONS] [FILEIN] ([FILEOUT])"

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]; then 
	echo $usage
	echo "Convert a video file using ffmpeg with simple optimized compression options"
	echo ""
	echo "Options:"
	echo "   -mp4,-webm       set codec by file format directly"
	echo "                       (\"-mp4\" (x264, default),\"-webm\" (VPx))"	
	echo "   -quality q       set quality of compression "
	echo "                       (\"low\", \"med\" (default), \"high\") "
	echo "   -scale s         set output to input scaling ratio"
	echo "                       e.g. \"2:3\" for 1080p->720p conversion"
	echo "                       \"1:1\" is default"	
	echo "   -parallel n      set parallel mode on, using at most n threads at once,"
	echo "                       e.g. 4 threads for quad-core CPU"
	echo "                       FILEIN should be a list of files to convert"
	echo "                       e.g. \"./*.MOV\" to convert all MOV files"	
	echo "                       no FILEOUT string allowed, overwrite mode on"
	echo "                       and any printed output sent to null"
	echo "   -filter f        set additional video filter"
	echo "                       e.g. \", frei0r=contrast0r:0.56\""
	echo "   -preopt pr       set extra ffmpeg options pre infile, .e.g \"-ss 00:00:10\""
	echo "   -postopt po      set extra ffmpeg options post infile, .e.g \"-t 8\""
	echo "   -nthreads n      set number of threads per process (1 default) in serial"
	echo "                       use -parallel n in parallel mode"
	#echo "   -movie           crop video to a 2.40:1 aspect ratio"
	echo ""
	echo "Examples: $ ./`basename $0` -webm -quality med -scale 2:3 ./videos/011.MOV ./tmp/test011"
	echo "          $ ./`basename $0` -quality high -parallel ./videos/*.MOV"
	exit
fi	

usage_error() 
{
    echo `basename $0`: ERROR: $1 1>&2
    echo $usage 1>&2
	echo For help: `basename $0` -h 1>&2
    exit 1
}
get_size()
{
	ffmpeg -i "$1" 2>&1 | perl -lane 'print $1 if /([0-9]{2,}x[0-9]+)/'
}
get_info()
{
	ffmpeg -i "$1" 2>&1 | grep Stream
}
floor2even()
{
	num=$1
	echo $((num-(num % 2)))
}
filebase()
{
	filename="$(basename "$1")"
	echo "${filename%.*}"
}

# =================================


if [ "$1" = "-info" ]; then 
	get_info "$2"
	exit
fi	

####### default options #######

codec=mp4  		# webm, mp4
scale="1:1"
parallel=0 		# 0=false, -y overwrites output files
movie=0			# not in use
nthreads=1
quality=med		# low, med, high
preopt=""
postopt=""
filterin=""

####### get options #######

while [ $# -gt 0 ]; do
	case "$1" in
		-mp4)
			codec=mp4;;
		-webm)
			codec=webm;;
		-quality)
			quality=$2
			shift;;
		-scale)
			scale=$2
			shift;;
		-parallel)
			parallel=1
			nthreads=$2
			shift;;
		-filter)
			filterin=$2
			shift;;	
		-preopt)
			preopt=$2
			shift;;	
		-postopt)
			postopt=$2
			shift;;	
		-nthreads)
			nthreads=$2
			shift;;	
		*) break;;
	esac
	shift
done


# "crop=1920:800:0:140, scale=1280:534, ..."

if [ $parallel -eq 0 ] && [ $# -ne 1 ] && [ $# -ne 2 ]; then 		# variable supplied?
	usage_error "number of arguments"
fi

if [ $parallel -eq 1 ]; then
	INLIST=($@)
else
	INLIST="$1"
fi


####### parallel loop #######

#commandfile="naiveffmpeg.tmp"
#>"$commandfile" || usage_error "$commandfile - unable to clear file"

ls -l "${INLIST[@]}"
echo ""

i=0
for INFILE in "${INLIST[@]}"  # $@
do

	insize=$(get_size "$INFILE")
	if [[ "$INFILE" = */* ]]; then
		inpath="${INFILE%/*}/"
	else
		inpath=""
	fi

	if [ $parallel -eq 1 ] || [ $# -eq 1 ]; then 
		OUTNAME=$(filebase "$INFILE")
		outfile=$inpath$OUTNAME
	else
		OUTNAME="$2"
		outbase=$(filebase "$OUTNAME")
		if [ $outbase = "$OUTNAME" ]; then 
			outfile=$inpath$OUTNAME
		else  # a path
			outfile=$OUTNAME
		fi
	fi


	####### set options #######

	in_w=${insize%x*}
	in_h=${insize#*x}
	scaleo=${scale%:*}
	scalei=${scale#*:}
	out_h=$((in_h*$scaleo/$scalei))
	out_w=$((in_w*$scaleo/$scalei))
	refbitrate=2000 # K
	refarea=$((1280*720))
	bitrate=$((refbitrate*out_h*out_w/refarea))

	filterstr="scale=-1:ih*$scaleo/$scalei"$filterin


	case $quality in
		low)  bitrate=$(echo $((bitrate/2)))K;;
		med)  bitrate=$(echo $bitrate)K;;
		high) bitrate=$(echo $((bitrate*3/2)))K;;
		*) usage_error "bad argument ($quality) for -quality";;
	esac

	# low crf is better quality
	if [ $codec = "webm" ]; then 
		codecstr="-vcodec libvpx -acodec libvorbis"
		outfile=$outfile.webm
		case $quality in
			low)  qualstr="-vb $bitrate -ab 128k -crf 12 -qmin 8 -qmax 60";;
			med)  qualstr="-vb $bitrate -ab 160k -crf 8  -qmin 4 -qmax 56";;
			high) qualstr="-vb $bitrate -ab 256k -crf 4  -qmin 0 -qmax 50";;
		esac
	elif [ $codec = "mp4" ]; then 
		codecstr="-vcodec libx264 -acodec libmp3lame"
		outfile=$outfile.mp4
		case $quality in
			low)  qualstr="-vb $bitrate -ab 128k -crf 28 -qmin 10 -qmax 62";;
			med)  qualstr="-vb $bitrate -ab 160k -crf 22 -qmin 6  -qmax 58";;
			high) qualstr="-vb $bitrate -ab 256k -crf 19 -qmin 3  -qmax 53";;
		esac
	else
		usage_error "bad argument ($codec) for -codec"
	fi

	####### convert video or save command #######

	echo "converting ${i}:"
	echo "$INFILE   ($in_w""x""$in_h) ->"
	echo "$outfile   ($out_w""x""$out_h) at bitrate $bitrate"

	if [ $parallel -eq 1 ]; then 
		commands[i++]="ffmpeg $preopt -i \"$INFILE\" $postopt $qualstr -vf \"$filterstr\" $codecstr -threads 1 -y \"$outfile\" </dev/null > /dev/null 2>&1"
	else
		ffmpeg $preopt -i "$INFILE" $postopt $qualstr -vf "$filterstr" $codecstr -threads $nthreads "$outfile"
	fi

done

# execute commands in parallel
if [ $parallel -eq 1 ]; then 
	echo ""
	echo "Converting $i files using at most $nthreads threads..."
	echo ""
	printf '%s\0' "${commands[@]}" | xargs --max-procs=$nthreads --max-args=1 -t -I {} -0 $shellname -c {}
fi

#echo "ffmpeg $preopt -i \"$INFILE\" $postopt $qualstr -vf \"$filterstr\" $codecstr -threads 1 -y \"$outfile\" </dev/null > /dev/null 2>&1" >>"$commandfile"
#xargs --max-procs=$nthreads --max-args=1 -t -I {} -d '\n' $shellname -c {} <"$commandfile"
exit
