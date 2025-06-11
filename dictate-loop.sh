#!/usr/bin/env zsh

# Dictate Loop Script
# Records audio via FFmpeg, transcribes using Whisper, and optionally inserts the result into terminal.
#
# Requirements: ffmpeg, whisper-cli, zenity, xclip, xdotool
#
# Usage: Run the script and follow GUI instructions.

set -euo pipefail

# Enable debug mode if needed
#set -x

# --- Configuration ---
AUDIO_FILE="/tmp/dictation.wav"
OUTPUT_BASENAME="/tmp/dictation"
TRANSCRIPT_FILE="${OUTPUT_BASENAME}.txt"
MODEL_PATH="$HOME/repos/whisper.cpp/models/ggml-base.bin"
WHISPER_LANG="auto"

# --- Check Dependencies ---
for cmd in ffmpeg whisper-cli zenity xclip xdotool; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: $cmd not found." >&2
    exit 1
  }
done

rm -f "$AUDIO_FILE" "$TRANSCRIPT_FILE"

# --- Start Recording ---
ffmpeg -f pulse -i default -ac 1 -ar 16000 -y "$AUDIO_FILE" >/dev/null 2>&1 &
FFMPEG_PID=$!
echo "Started FFmpeg recording, PID=$FFMPEG_PID"
sleep 0.2
if ! ps -p "$FFMPEG_PID" >/dev/null; then
  echo "Error: FFmpeg failed to start." >&2
  exit 1
fi

zenity --question \
  --title="Recording" \
  --text="Click 'OK' to stop recording." \
  --ok-label="Stop" --cancel-label="Cancel" \
  --width=300

CHOICE=$?

# --- Stop Recording ---
kill "$FFMPEG_PID" 2>/dev/null || true
wait "$FFMPEG_PID" 2>/dev/null || true

# --- Ensure Audio File is Written ---
for i in {1..10}; do
  [ -f "$AUDIO_FILE" ] && break
  sleep 0.2
done

# --- Handle User Cancel ---
if [ "$CHOICE" -ne 0 ]; then
  zenity --info --text="Recording cancelled."
  exit 1
fi

# --- Validate Audio File ---
if [ ! -f "$AUDIO_FILE" ]; then
  zenity --error --text="Failed to create audio file."
  exit 1
fi

# --- Transcribe Audio ---
whisper-cli \
  -m "$MODEL_PATH" \
  -l "$WHISPER_LANG" \
  -otxt \
  -of "$OUTPUT_BASENAME" \
  "$AUDIO_FILE"

# --- Validate Transcript ---
if [ ! -f "$TRANSCRIPT_FILE" ]; then
  zenity --error --text="Transcript not generated."
  exit 1
fi

TRANSCRIPT=$(cat "$TRANSCRIPT_FILE")

# --- Show Result and Offer to Insert ---
zenity --question \
  --title="Transcription Result" \
  --text="\"$TRANSCRIPT\"\n\nInsert into terminal?" \
  --width=500 --height=300

if [ $? -eq 0 ]; then
  echo -n "$TRANSCRIPT" | xclip -selection clipboard
  xdotool type --delay 1 --clearmodifiers "$TRANSCRIPT"
else
  zenity --info --text="Insert cancelled."
fi
