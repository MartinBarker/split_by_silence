#!/bin/bash

input_file="input_short.mp3"
output_file="output.csv"

# Run FFmpeg command to get volume information
ffmpeg -i "$input_file" -af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 | grep "max_volume" | awk -F ':' '{print $2}' | tr -d ' ' | awk '{printf "%.2f\n", (10*log($1)/log(10)) * ((($1 > 0) - ($1 < 0))*2-1)}' > "$output_file"

echo "Volume in dB for every second in $input_file:"
cat "$output_file"

# Cleanup the output file
rm "$output_file"
