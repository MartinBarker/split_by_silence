Instructions:

1) Get comma seperated string list of SPLIT points, add zero to start and total length to end
`$ ./split_by_silence`

2) Convert list of split point times into a .cue file
`$ ./readable_points_to_readable.sh`

2) Use shntool to split the flac based on .cue input
`$ shntool split -f times.cue -O always -o flac -d "%a - %t" -v -e 24/96 full.flac`




