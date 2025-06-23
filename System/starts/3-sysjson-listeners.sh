#!/bin/sh
# Listens for changes to system.json

. /mnt/SDCARD/System/scripts/helpers.sh

SYSTEM_JSON="/mnt/UDISK/system.json"
THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"
VOLUME="$(awk '/\"vol\":/ { gsub(/[,]/,"",$2); print $2}' "$SYSTEM_JSON")"

# Reboot on theme change to fully load theme
while true; do
    inotifywait -e modify "$SYSTEM_JSON"

    NEW_THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"

    if [ "$NEW_THEME_PATH" != "$THEME_PATH" ]; then
        killall -9 MainUI
        cat /dev/zero > /dev/fb0
        reboot
    fi
done &

# USB-C headphone volume control
while true; do
    inotifywait -e modify "$SYSTEM_JSON"

    NEW_VOLUME="$(awk '/\"vol\":/ { gsub(/[,]/,"",$2); print $2}' "$SYSTEM_JSON")"

    # only change volume if sound card exists (when USB-C audio output is plugged in)
    if [ "$NEW_VOLUME" != "$VOLUME" ]; then
        VOLUME="$NEW_VOLUME"
        [ -c "/dev/audio1" ] && nice -2 amixer -c 1 sset 'PCM' $(($VOLUME * 5))% 
    fi
done &

# listen for headphones being plugged in, then set volume
while true; do
    inotifywait -e create /dev --include 'audio1'
    if [ -c "/dev/audio1" ]; then
        VOLUME="$(awk '/\"vol\":/ { gsub(/[,]/,"",$2); print $2}' "$SYSTEM_JSON")"
        nice -2 amixer -c 1 sset 'PCM' $(($VOLUME * 5))%
    fi
done &