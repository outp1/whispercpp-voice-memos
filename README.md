A minimal Zsh script for dictating short memos:  
Records microphone audio using FFmpeg, transcribes to text with Whisper, and optionally inserts the result into your terminal via simulated typing.

## Dependencies

- `zsh` or `bash` (change the script)
- `ffmpeg`
- `whisper-cli` ([Whisper.cpp](https://github.com/ggerganov/whisper.cpp))
- `zenity`
- `xclip`
- `xdotool`

Ensure the Whisper model (`ggml-base.bin` by default) exists at `$HOME/repos/whisper.cpp/models/` or change the `$MODEL_PATH` variable in the script.

## Usage

```sh
./dictate-loop.sh
```

Follow the on-screen prompts to record and handle transcriptions.

### I3 Integration

Add this snippet to your i3 config to trigger speech-to-text with Mod+Shift+S using your script.
```
# Trigger speech-to-text with Mod+Shift+S
bindsym $mod+Shift+s exec --no-startup-id /path/to/dictate-loop.sh
```
