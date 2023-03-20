#!/bin/bash

# Get input arguments
timestamp_list=$1
output_file=$2

# Split the timestamps into an array
IFS=',' read -ra timestamp_array <<< "$timestamp_list"

# Calculate the number of tracks
num_tracks=${#timestamp_array[@]}

# Define variables for time calculation
seconds_per_track=60
current_time=0

# Create output file and write header
echo "FILE \"audio.wav\" WAVE" > "$output_file"
echo "TRACK 01 AUDIO" >> "$output_file"

# Loop through each timestamp and write cue information to output file
for (( i=0; i<$num_tracks; i++ )); do
  timestamp=${timestamp_array[i]}
  minutes=${timestamp/.*}
  seconds=$(echo "scale=0; ${timestamp#*.}" | sed 's/0*$//')
  echo "  TITLE \"Track $((i+1))\"" >> "$output_file"
  echo "  INDEX 01 $current_time:$minutes:$seconds" >> "$output_file"
  current_time=$((current_time+seconds_per_track))
done
