# -----------------------
# SPLIT BY SILENCE
# Requirements:
#    ffmpeg
#    $ apt-get install bc
# How To Run:
# $ ./split_by_silence.sh "full_lowq.flac" %03d_output.flac

# output title format
OUTPUTTITLE="%d_output.flac"
# input audio filepath
IN="/mnt/c/Users/marti/Documents/projects/split_by_silence2/full.flac"
# output audio filepath
OUTPUTFILEPATH="/mnt/c/Users/marti/Documents/projects/split_by_silence2"
# ffmpeg option: split input audio based on this silencedetect value
SD_PARAMS="-11dB"
MIN_FRAGMENT_DURATION=120 # split option: minimum fragment duration
export MIN_FRAGMENT_DURATION

# -----------------------
# step: ffmpeg
# goal: get comma separated list of split points (use ffmpeg to determine points where audio is at SD_PARAMS [-18db] )

echo "_______________________"
echo "Determining split points..."
SPLITS=$(
    ffmpeg -v warning -i "$IN" -af silencedetect="$SD_PARAMS",ametadata=mode=print:file=-:key=lavfi.silence_start -vn -sn  -f s16le  -y /dev/null \
    | grep lavfi.silence_start= \
    | cut -f 2-2 -d= \
    | perl -ne '
        our $prev;
        INIT { $prev = 0.0; }
        chomp;
        if (($_ - $prev) >= $ENV{MIN_FRAGMENT_DURATION}) {
            print "$_,";
            $prev = $_;
        }
    ' \
    | sed 's!,$!!'
)
#echo "split points list= $SPLITS"

# add '5.5' to each split (padding)
IFS=',' read -ra SPLITS_ARRAY <<< "$SPLITS"
for i in "${!SPLITS_ARRAY[@]}"; do
  SPLITS_ARRAY[i]=$(echo "${SPLITS_ARRAY[i]}+5.5" | bc)
done

SPLITS_DISPLAY=$SPLITS
# add zero '0' to start o SPLITS_DISPLAY list
SPLITS_DISPLAY="0,$SPLITS_DISPLAY"

# get the full audio filelength for the input file $IN, and add that length (in seconds) to end of $SPLITS
FILE_LENGTH=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$IN")

# add file length to end of SPLITS
SPLITS_DISPLAY="$SPLITS_DISPLAY,$FILE_LENGTH"
echo "SPLITS_DISPLAY=$SPLITS_DISPLAY"

# print out splits 
SPLITS=$(IFS=','; echo "${SPLITS_ARRAY[*]}")
echo "SPLITS=$SPLITS"

# using the split points list, calculate how many output audio files will be created 
num=0
res="${SPLITS//[^,]}"
CHARCOUNT="${#res}"
num=$((CHARCOUNT + 2))
echo "_______________________"
echo "Exporting $num tracks with ffmpeg"

ffmpeg -i "$IN" -c copy -map 0 -f segment -segment_times "$SPLITS" "$OUTPUTFILEPATH/$OUTPUTTITLE"

echo "Done."

echo "------------------------------------------------"
echo "$num TRACKS EXPORTED"