#!/bin/sh
# Listens for system changes

. /mnt/SDCARD/System/scripts/helpers.sh

SYSTEM_JSON="/mnt/UDISK/system.json"
THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"
VOLUME="$(awk '/\"vol\":/ { gsub(/[,]/,"",$2); print $2}' "$SYSTEM_JSON")"

# Combined theme change and volume control listener
while true; do
    inotifywait -e modify "$SYSTEM_JSON"

    # Check for theme changes
    NEW_THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"
    if [ "$NEW_THEME_PATH" != "$THEME_PATH" ]; then
        killall -9 MainUI
        cat /dev/zero > /dev/fb0
        reboot
    fi

    # Check for volume changes
    NEW_VOLUME="$(awk '/\"vol\":/ { gsub(/[,]/,"",$2); print $2}' "$SYSTEM_JSON")"
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