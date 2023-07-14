#!/bin/bash
#
# Usage: ./detect_volume.sh <input_file> <duration> [-csv]
#
# This script calculates the volume in dB for each second interval
# of the specified audio file.
#
# Arguments:
#   <input_file>    Path to the input audio file
#   <duration>      Duration in seconds for measurement
#   -csv            Optional flag to output as CSV
#

input_file="$1"
duration="$2"
output_csv=false

# Check if the -csv flag is passed
if [[ $3 == "-csv" ]]; then
  output_csv=true
fi

# Output header for CSV file if -csv flag is passed
if [ "$output_csv" = true ]; then
  echo "Second,Volume (dB)" > volumes.csv
fi

for ((i = 0; i < duration; i++))
do
  start=$((i))
  end=$((i + 1))

  # Run FFmpeg command for each second interval
  volume=$(ffmpeg -i "$input_file" -filter_complex "[0:a]atrim=start=$start:end=$end,volumedetect" -f null /dev/null 2>&1 | awk '/max_volume/ {print $5}')

  # Print the formatted output
  echo "$i : $volume"

  # Append to CSV file if -csv flag is passed
  if [ "$output_csv" = true ]; then
    echo "$i,$volume" >> volumes.csv
  fi
done
