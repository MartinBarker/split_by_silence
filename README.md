input.mp3 is vinyl rip of "Donn Clayton And The Add A Manual – The Gourmet Touch" 

#### NEW BELOW:

./split_by_silence.sh "12 Tracks Donn Clayton Add A Manual Gourmet Touch.mp3" -numTracks 12

#### OLD BELOW:: 

Instructions:

1) Get comma seperated string list of SPLIT points, add zero to start and total length to end
`$ ./split_by_silence.sh "full_lowq.flac" %03d_output.flac`

2) Convert list of split point times into a .cue file
`$ ./readable_points_to_readable.sh`

2) Use shntool to split the flac based on .cue input
`$ shntool split -f times.cue -O always -o flac -d "%a - %t" -v -e 24/96 full.flac`



--------------------------------------------

### detect audio level 

1. cut out first second of audio from input.mp3 for duration 0->1 seconds:
    ffmpeg -i input.mp3 -ss 0 -t 1 -c copy input_sec1.mp3

2. determine max volume from that segment with ffmpeg command:
    ffmpeg -i input_sec1.mp3 -filter_complex "[0:a]atrim=start=0:end=1,volumedetect" -f null /dev/null 2>&1 | awk '/max_volume/ {print $5}'
-28.2

3. determine max volume frmo segment in audacity:
    open input_sec1.mp3 in audacity
    effect->volume->amplify
    Amplify is what is needed to bring audio to zero db, so take the opposite of this value, so +28.2 turn negative becomes:
-28.2

4. run ffmpeg command to get max_volume for duration 0->1 seconds:
    ffmpeg -i input.mp3 -filter_complex "[0:a]atrim=start=0:end=1,volumedetect" -f null /dev/null 2>&1 | awk '/max_volume/ {print $5}'
-28.2

5. get duration of audio file in seconds:
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp3
1945.626122
1946

6. run script to get volume of every second from input.mp3 from zero to 1946 seconds and create csv of data
    ./detect_volume.sh input.mp3 1946 -csv