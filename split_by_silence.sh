# -----------------------
# SPLIT BY SILENCE
# Requirements:
#    ffmpeg
#    $ apt-get install bc
# How To Run:
# $ ./split_by_silence.sh "full_lowq.flac" %03d_output.flac

# output title format
OUTPUTTITLE="%d_output.mp3"
# input audio filepath
IN="/mnt/c/Users/marti/Documents/projects/split_by_silence/lowquality_example.mp3"
# output audio filepath
OUTPUTFILEPATH="/mnt/c/Users/marti/Documents/projects/split_by_silence"
# ffmpeg option: split input audio based on this silencedetect value
SD_PARAMS="-11dB"
# split option: minimum fragment duration
MIN_FRAGMENT_DURATION=120
export MIN_FRAGMENT_DURATION

#  close (12 tracks)
#  -11db
#  120


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
echo "split points list= $SPLITS"

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