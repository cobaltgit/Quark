#!/bin/sh
# Listens for changes to system.json

. /mnt/SDCARD/System/scripts/helpers.sh

SYSTEM_JSON="/mnt/UDISK/system.json"
THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"
VOLUME="$(awk '/\"vol\":/ { gsub(/[,]/,"",$2); print $2}' "$SYSTEM_JSON")"

amixer sset 'headphone volume' $(($VOLUME * 5))% &

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

    if [ "$NEW_VOLUME" != "$VOLUME" ]; then
        VOLUME="$NEW_VOLUME"
        amixer sset 'headphone volume' $(($VOLUME * 5))% 
    fi
done &