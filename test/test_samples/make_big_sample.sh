#!/bin/bash

RATE=${3:-0.5M}
QUALITY=${4:-23}
INPUT=${1:-out9.webm}
LOGFILE="$1-pass"
OUTPUT=${2:-${1%.*}-big.webm}
LOOP=${LOOP:-1}
SCALE=${SCALE:-3.75}
HWACCEL=${HWACCEL:-}
if ! [ -z "$HWACCEL" ]; then
    HWACCEL="-hwaccel $HWACCEL"
fi

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}


echo "Converting $INPUT to $OUTPUT at $RATE, or Q$QUALITY, whichever is smaller"
set -e
# http://wiki.webmproject.org/ffmpeg/vp9-encoding-guide
# -row-mt: https://groups.google.com/a/webmproject.org/forum/#!topic/codec-devel/oiHjgEdii2U
start=$SECONDS
ffmpeg $HWACCEL -i "$INPUT" -c:v libvpx-vp9 -b:v $RATE -pass 1 -passlogfile "$LOGFILE" \
	-an -f webm -y \
	-threads 12 \
	-tile-columns 6 -frame-parallel 1 -row-mt 1 \
	-crf $QUALITY \
	/dev/null
ffmpeg $HWACCEL \
    -stream_loop $LOOP \
    -i "$INPUT" \
    -vf scale=iw*$SCALE:ih*$SCALE \
    -c:v libvpx-vp9 -b:v $RATE -pass 2 -passlogfile "$LOGFILE" \
	-c:a libopus -threads 12 \
	-tile-columns 6 -frame-parallel 1 -row-mt 1 \
	-auto-alt-ref 1 -lag-in-frames 25 \
	-crf $QUALITY \
	"$OUTPUT"
rm -f "$LOGFILE-0.log" || true
end=$SECONDS
echo ""
duration=$(( end - start ))
echo "Encoded $(basename -- $OUTPUT) in $(displaytime $duration)"

