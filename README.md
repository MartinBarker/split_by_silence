Goal:
Generate 11 split points, render 12 audio files using the included mp3.

https://www.discogs.com/release/1347350-LTD-Gittin-Down

Call with command:
```
./split_by_silence
```
~~~~~~~~ Status ~~~~~~~~~~~
https://github.com/MartinBarker/split_by_silence

I am trying to automate the process of splitting a single audio file into 12 tracks. you can see in the below image that this 35:62 length mp3 file has 11 visible split points (where the audio more quiet), which means 12 distinct segments. 
[![enter image description here][1]][1]

I'd like to be able to run a script to automatically find these split points and split my file, my first split point should be around `159` seconds, and second around `360`, third around `540`, 4th around `780`, 5th around `960`, and so on for a total of 11 split points:
```
1 159
2 360
3 540
4 780
5 960
6 1129
7 1309
8 1500
9 1680
10 1832
11 1980
``` 
but my test results have not been working so good:

```
- Goal:
11 split points found
12 tracks rendered

- Test 1
SD_PARAMS="-24dB"
MIN_FRAGMENT_DURATION="3"
5 split points found: 361.212,785.811,790.943,969.402,2150.24`
6 tracks rendered

-Test 2
SD_PARAMS="-24dB"
MIN_FRAGMENT_DURATION="3"
10 split points found: 151.422,155.026,158.526,361.212,534.254,783.667,967.253,1128.91,2150.2
11 tracks rendered
```
- Test 2 Problem:
Even though 12 tracks were rendered, some split points are very close
[![enter image description here][2]][2]
leading to tracks being exported that are very short, such as 3, 5, and 2 seconds. as well as one long track being 16 minutes
[![enter image description here][3]][3]


So I added a variable `MIN_SEGMENT_LENGTH` and ran another test
```
- Test 3
SD_PARAMS="-18dB"
MIN_FRAGMENT_DURATION="3"
MIN_SEGMENT_LENGTH=120 (02:00)

log:
_______________________
Determining split points...
split points list= 150.482,155.026,158.526,361.212,530.019,534.254,783.667,967.245,1127.67,2144.57,2150.2
1. The difference between 150.482 and 155.026 is 4.544
       diff is less than MIN_SEGMENT_LENGTH=120
2. The difference between 155.026 and 158.526 is 3.500
       diff is less than MIN_SEGMENT_LENGTH=120
3. The difference between 158.526 and 361.212 is 202.686
4. The difference between 361.212 and 530.019 is 168.807
5. The difference between 530.019 and 534.254 is 4.235
       diff is less than MIN_SEGMENT_LENGTH=120
6. The difference between 534.254 and 783.667 is 249.413
7. The difference between 783.667 and 967.245 is 183.578
8. The difference between 967.245 and 1127.67 is 160.425
9. The difference between 1127.67 and 2144.57 is 1016.90
10. The difference between 2144.57 and 2150.2 is 5.63
       diff is less than MIN_SEGMENT_LENGTH=120
_______________________
Exporting 12 tracks with ffmpeg...
```
I'm unsure how to change my script and vars so that by running it, are calculating the split points, if any of them are too short (less then 120 seconds) to regenerate the split point(s)?

Here is my audio file:
https://filetransfer.io/data-package/HC7GG07k#link

And here is my script, which can be ran by running `./split_by_silence.sh`
```
# -----------------------
# SPLIT BY SILENCE
# Requirements:
#    ffmpeg
#    $ apt-get install bc
# How To Run:
# $ ./split_by_silence.sh "full_lowq.flac" %03d_output.flac

# output title format
OUTPUTTITLE="%03d_output.mp3"
# input audio filepath
IN="/mnt/e/martinradio/rips/vinyl/L.T.D. – Gittin' Down/lowquality_example.mp3"
# output audio filepath
OUTPUTFILEPATH="/mnt/e/folder/rips"
# ffmpeg option: split input audio based on this silencedetect value
SD_PARAMS="-18dB"
# split option: minimum fragment duration
MIN_FRAGMENT_DURATION=3
# minimum segment length
MIN_SEGMENT_LENGTH=120

# -----------------------
# step: ffmpeg
# goal: get comma separated list of split points (use ffmpeg to determine points where audio is at SD_PARAMS [-18db] )

echo "_______________________"
echo "Determining split points..." >& 2
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
# determine if the difference between any two splits is less than MIN_SEGMENT_LENGTH seconds
IFS=',' read -ra VALUES <<< "$SPLITS"

for (( i=0; i<${#VALUES[@]}-1; i++ )); do
  diff=$(echo "${VALUES[$i+1]} - ${VALUES[$i]}" | bc)
  display_i=$((i+1))
  echo "$display_i. The difference between ${VALUES[$i]} and ${VALUES[$i+1]} is $diff"
  if (( $(echo "$diff < $MIN_SEGMENT_LENGTH" | bc -l) )); then
    echo "       diff is less than MIN_SEGMENT_LENGTH=$MIN_SEGMENT_LENGTH"
  fi
done


# using the split points list, calculate how many output audio files will be created 
num=0
res="${SPLITS//[^,]}"
CHARCOUNT="${#res}"
num=$((CHARCOUNT + 2))
echo "_______________________"
echo "Exporting $num tracks with ffmpeg"

ffmpeg -i "$IN" -c copy -map 0 -f segment -segment_times "$SPLITS" "$OUTPUTFILEPATH/$OUTPUTTITLE"

echo "Done."

```

  [1]: https://i.stack.imgur.com/iE6Zg.png
  [2]: https://i.stack.imgur.com/9arxX.png
  [3]: https://i.stack.imgur.com/nfYir.png