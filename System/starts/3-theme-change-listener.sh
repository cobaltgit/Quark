#!/bin/sh
# Listens for theme changes in system.json and restarts MainUI

. /mnt/SDCARD/System/scripts/helpers.sh

SYSTEM_JSON="/mnt/UDISK/system.json"
THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"

while [ "$PLATFORM" = "tg2040" ]; do
    inotifywait -e modify "$SYSTEM_JSON"

    NEW_THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"

    if [ "$NEW_THEME_PATH" != "$THEME_PATH" ]; then
        killall -9 MainUI
        cat /dev/zero > /dev/fb0
        reboot
    fi
    sleep 1
done &