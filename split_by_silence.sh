#!/bin/bash
# -----------------------
# SPLIT BY SILENCE
# Requirements:
#    ffmpeg
#    bc (apt-get install bc)
# How To Run:
# $ ./split_by_silence.sh <input_file> [-numTracks <target_num>]

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: ./split_by_silence.sh <input_file> [-numTracks <target_num>]"
    exit 1
fi

# Input audio filepath
IN="$1"
# Output folder path
OUTPUTFOLDER="output"
# Delete 'output' folder and its contents if it exists
if [ -d "$OUTPUTFOLDER" ]; then
    rm -rf "$OUTPUTFOLDER"
fi
# Create output folder
mkdir -p "$OUTPUTFOLDER"
# Output title format
OUTPUTTITLE="$OUTPUTFOLDER/%03d_output.mp3"
# Output audio filepath
OUTPUTFILEPATH="$PWD/$OUTPUTTITLE"
# ffmpeg option: split input audio based on this silencedetect value
SD_PARAMS="-11dB"
MIN_FRAGMENT_DURATION=120 # split option: minimum fragment duration
export MIN_FRAGMENT_DURATION

# Parse command-line arguments
shift
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -numTracks)
            NUM_TRACKS="$2"
            shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Convert input file to MP3 format if not already converted
if [ "${IN##*.}" != "mp3" ]; then
    TEMP_FILE="${IN%.*}_mp3_converted.mp3"
    if [ ! -f "$TEMP_FILE" ]; then
        ffmpeg -i "$IN" -q:a 2 "$TEMP_FILE"
    fi
else
    TEMP_FILE="$IN"
fi

# -----------------------
# Step: ffmpeg
# Goal: Get comma-separated list of split points (use ffmpeg to determine points where audio is at SD_PARAMS [-18db] )

echo "_______________________"
echo "Determining split points..."

# Function to check the number of tracks obtained for given SD_PARAMS and MIN_FRAGMENT_DURATION
check_num_tracks() {
    local splits="$1"
    local num_tracks=$(IFS=','; echo "${#splits[@]}")
    echo "$num_tracks"
}

# Function to run ffmpeg with given SD_PARAMS and MIN_FRAGMENT_DURATION
run_ffmpeg() {
    local splits="$1"
    echo "Running ffmpeg with SD_PARAMS: $SD_PARAMS and MIN_FRAGMENT_DURATION: $MIN_FRAGMENT_DURATION"
    ffmpeg -i "$TEMP_FILE" -c copy -map 0 -f segment -segment_times "$splits" "$OUTPUTFILEPATH"
}

# Initialize variables
best_splits=()
best_num_tracks=$((NUM_TRACKS + 1))

# Loop through different combinations of SD_PARAMS and MIN_FRAGMENT_DURATION
for db in -11 -12 -13; do
    for duration in 120 150 180; do
        SD_PARAMS="${db}dB"
        MIN_FRAGMENT_DURATION="$duration"

        # Determine split points
        splits=$(
            ffmpeg -v warning -i "$TEMP_FILE" -af silencedetect="$SD_PARAMS",ametadata=mode=print:file=-:key=lavfi.silence_start -vn -sn -f s16le -y /dev/null \
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

        # Add '5.5' to each split (padding)
        IFS=',' read -ra splits_array <<<"$splits"
        for i in "${!splits_array[@]}"; do
            splits_array[i]=$(echo "${splits_array[i]}+5.5" | bc)
        done

        # Check the number of tracks obtained
        num_tracks=$(check_num_tracks "${splits_array[@]}")

        # If the number of tracks is closest to the target, update the best splits and number of tracks
        if [ "$num_tracks" -ge "$NUM_TRACKS" ] && [ "$num_tracks" -lt "$best_num_tracks" ]; then
            best_splits=("${splits_array[@]}")
            best_num_tracks=$num_tracks
            best_params="SD_PARAMS: $SD_PARAMS, MIN_FRAGMENT_DURATION: $MIN_FRAGMENT_DURATION"
        fi
    done
done

# Export tracks with best splits
if [ ${#best_splits[@]} -eq 0 ]; then
    echo "No suitable combination of SD_PARAMS and MIN_FRAGMENT_DURATION found to achieve the target number of tracks."
else
    echo "Best combination found:"
    echo "$best_params"

    # Print out splits
    splits_display=$(IFS=','; echo "${best_splits[*]}")
    echo "SPLITS=$splits_display"

    echo "_______________________"
    echo "Exporting $best_num_tracks tracks with ffmpeg"

    # Run ffmpeg with best splits
    run_ffmpeg "${best_splits[@]}"

    echo "Done."
fi

# Clean up temporary file
if [ "$TEMP_FILE" != "$IN" ]; then
    rm "$TEMP_FILE"
fi

echo "------------------------------------------------"
echo "$best_num_tracks TRACKS EXPORTED"
