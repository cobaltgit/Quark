#!/bin/sh
# Listens for theme changes in system.json and restarts MainUI

. /mnt/SDCARD/System/scripts/helpers.sh

LD_LIBRARY_PATH="/mnt/SDCARD/System/lib"
SYSTEM_JSON="/mnt/UDISK/system.json"
THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')"

{
     while true; do
        /mnt/SDCARD/System/bin/inotifywait -e modify "$SYSTEM_JSON"

        NEW_THEME_PATH=$(awk -F'"' '/"theme":/ {print $4}' "$SYSTEM_JSON" | sed 's:/*$:/:')

        if [ "$NEW_THEME_PATH" != "$THEME_PATH" ]; then
            killall -9 MainUI
            THEME_PATH="$NEW_THEME_PATH"
        fi
        sleep 1
    done
} &