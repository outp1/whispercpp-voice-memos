#!/usr/bin/env zsh

set -x

AUDIO_FILE="/tmp/dictation.wav"
OUTPUT_BASENAME="/tmp/dictation"
TRANSCRIPT_FILE="${OUTPUT_BASENAME}.txt"
MODEL_PATH="$HOME/repos/whisper.cpp/models/ggml-base.bin"
WHISPER_LANG="auto"

rm -f "$AUDIO_FILE" "$TRANSCRIPT_FILE"

# Запуск записи
ffmpeg -f pulse -i default -ac 1 -ar 16000 -y "$AUDIO_FILE" >/dev/null 2>&1 &
FFMPEG_PID=$!
echo "Запущен ffmpeg, PID=$FFMPEG_PID"
sleep 0.2  # даём ffmpeg время на инициализацию
ps -p $FFMPEG_PID || echo "ffmpeg не запустился!"

# Окно: пользователь сам останавливает
zenity --version
zenity --question \
  --title="Запись" \
  --text="Нажми 'ОК', чтобы остановить запись." \
  --ok-label="Остановить" --cancel-label="Отмена" \
  --width=300

CHOICE=$?

# Остановить ffmpeg
kill "$FFMPEG_PID"
wait "$FFMPEG_PID" 2>/dev/null || true

# Ждём, пока файл точно появится
for i in {1..10}; do
    [ -f "$AUDIO_FILE" ] && break
    sleep 0.2
done

# Проверка отмены
if [ "$CHOICE" -ne 0 ]; then
    zenity --info --text="Запись отменена."
    exit 1
fi

# Проверка файла
if [ ! -f "$AUDIO_FILE" ]; then
    zenity --error --text="Файл записи не создан."
    exit 1
fi

# Транскрипция
whisper-cli \
  -m "$MODEL_PATH" \
  -l "$WHISPER_LANG" \
  -otxt \
  -of "$OUTPUT_BASENAME" \
  "$AUDIO_FILE"

# Проверка результата
if [ ! -f "$TRANSCRIPT_FILE" ]; then
    zenity --error --text="Транскрипция не получена."
    exit 1
fi

TRANSCRIPT=$(cat "$TRANSCRIPT_FILE")

zenity --question \
  --title="Результат" \
  --text="\"$TRANSCRIPT\"\n\nВставить в терминал?" \
  --width=500 --height=300

if [ $? -eq 0 ]; then
    echo -n "$TRANSCRIPT" | xclip -selection clipboard
    xdotool type --delay 1 --clearmodifiers "$TRANSCRIPT"
else
    zenity --info --text="Вставка отменена."
fi
