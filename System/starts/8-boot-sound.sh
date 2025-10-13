#!/bin/sh

THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "/mnt/UDISK/system.json" | sed 's:/*$:/:')"
BOOT_SOUND="$THEME_PATH/sound/boot.wav"

[ -f "$BOOT_SOUND" ] && aplay "$BOOT_SOUND" &
