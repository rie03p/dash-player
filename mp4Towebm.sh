#!/bin/bash

# https://github.com/gpac/gpac/wiki/GPAC-build-MP4Box-only-all-platforms

set -e

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg could not be found. Please install it first."
    exit
fi

# Check if Shaka Packager is installed
if ! command -v packager &> /dev/null
then
    echo "Shaka Packager could not be found. Please install it first."
    exit
fi

if [ "$1" == "" ]; then
    echo "Usage: $0 <input_file.mp4>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "File not found!"
    exit 1
fi

if [ "$2" == "" ]; then
    echo "Usage: $0 <input_file.mp4> <output_dir>"
    exit 1
fi

if [ -f "$2" ]; then
    echo "Output file already exists. Overwrite? (y/n)"
    read answer
    if [ "$answer" != "y" ]; then
        echo "Exiting without conversion."
        exit 1
    fi
fi

INPUT="$1"
OUTPUT_DIR="$2"
SPLIT_DIR="split"
MPD_FILE="index.mpd"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/$SPLIT_DIR"

# mp4を1分ごとに分割
echo "Splitting $INPUT..."
ffmpeg -i "$INPUT" -c copy -map 0 -f segment -segment_time 60 -reset_timestamps 1 "$OUTPUT_DIR/$SPLIT_DIR/part-%03d.mp4"

# 分割したmp4をwebmに変換
echo "Converting to webm..."
for file in "$OUTPUT_DIR/$SPLIT_DIR/part"*.mp4; do
    base=$(basename "$file" .mp4)
    webmfile="$OUTPUT_DIR/$base.webm"
    ffmpeg -i "$file" -c:v libvpx-vp9 -b:v 1M -c:a libopus -b:a 128k "$webmfile"
done

echo "Creating MPD file with Shaka Packager..."
packager_command="packager"

# 最初のWebMファイルからメディアタイプを判定
first_webm=$(ls "$OUTPUT_DIR"/*.webm | head -1)
if [ -n "$first_webm" ]; then
    has_video=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$first_webm")
    has_audio=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$first_webm")
fi

stream_counter=0
for webm_file in "$OUTPUT_DIR"/*.webm; do
    stream_counter=$((stream_counter + 1))
    if [ "$has_video" = "video" ]; then
        packager_command+=" in=$webm_file,stream=video,output=$OUTPUT_DIR/video_$stream_counter.webm"
    fi
    if [ "$has_audio" = "audio" ]; then
        packager_command+=" in=$webm_file,stream=audio,output=$OUTPUT_DIR/audio_$stream_counter.webm"
    fi
done

packager_command+=" --mpd_output $OUTPUT_DIR/$MPD_FILE"
packager_command+=" --min_buffer_time 2"
packager_command+=" --segment_duration 4"
packager_command+=" --generate_static_live_mpd"

echo "Running: $packager_command"
eval "$packager_command"

echo "Done."
