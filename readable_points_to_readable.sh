#!/bin/bash

# Set the input list of split points
SPLIT_POINTS="0,162.764,380.637,557.345,816.239,1009.69,1174.74,1371.11,1579.49,1767.21,1919.72,2241.561542"

# Set the track number
TRACK_NUM=1

# Set the performer and track title
PERFORMER="Faithless"
TRACK_TITLE="Live in Berlin"

# Set the MP3 filename
MP3_FILENAME="Faithless - Live in Berlin.mp3"

# Split the input list into an array of split points
IFS=',' read -r -a SPLIT_ARRAY <<< "$SPLIT_POINTS"

# Open the output file for writing
CUE_FILENAME="times.cue"
echo "REM GENRE Electronica" > "$CUE_FILENAME"
echo "REM DATE $(date +%Y)" >> "$CUE_FILENAME"
echo "PERFORMER \"$PERFORMER\"" >> "$CUE_FILENAME"
echo "TITLE \"$TRACK_TITLE\"" >> "$CUE_FILENAME"
echo "FILE \"$MP3_FILENAME\" MP3" >> "$CUE_FILENAME"

# Loop through the split points and print the CUE entries
for (( i=0; i<${#SPLIT_ARRAY[@]}; i++ ))
do
    # Get the current split point and the next split point
    CURRENT_SPLIT=${SPLIT_ARRAY[i]}
    if [[ $i -eq ${#SPLIT_ARRAY[@]}-1 ]]; then
        NEXT_SPLIT=""
    else
        NEXT_SPLIT=${SPLIT_ARRAY[i+1]}
    fi
    
    # Calculate track length in seconds
    if [[ -n $NEXT_SPLIT ]]; then
        TRACK_LENGTH=$(echo "$NEXT_SPLIT - $CURRENT_SPLIT" | bc)
        
        echo "CURRENT_SPLIT = $CURRENT_SPLIT"
        # Convert split points to HH:MM:SS format
        START_TIME=$(date -u -d "@$CURRENT_SPLIT" +%M:%S)
        echo "START_TIME = $START_TIME"
        echo "----------------------------------------"

        # Print the track start, end, and length times
        echo "  TRACK $(printf "%02d" $TRACK_NUM) AUDIO" >> "$CUE_FILENAME"
        echo "    TITLE \"$(printf "%02d" $TRACK_NUM)\"" >> "$CUE_FILENAME"
        echo "    PERFORMER \"$PERFORMER\"" >> "$CUE_FILENAME"
        echo "    INDEX 01 $START_TIME" >> "$CUE_FILENAME"
        
###^^ fix above code so it is HH:MM format into .cue file

        # Increment the track number
        TRACK_NUM=$((TRACK_NUM+1))
    else
        # no track length, so last split point, and not a track
        TRACK_LENGTH=""

    fi
done
