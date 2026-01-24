#!/bin/sh

THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "/mnt/UDISK/system.json" | sed 's:/*$:/:')"
BOOT_SOUND="$THEME_PATH/sound/boot.wav"
QUICKSAVE_CMD_TO_RUN="/mnt/SDCARD/Saves/.quicksave.sh"

if ! [ -f "/tmp/.play_bootvideo" ]; then
    [ -f "$BOOT_SOUND" ] && ! [ -f "$QUICKSAVE_CMD_TO_RUN" ] && \
    	aplay "$BOOT_SOUND" &
fi
