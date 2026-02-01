#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

BOOTLOGO="${1:-bootlogo.bmp}"
LOG_FILE="/mnt/SDCARD/System/log/bootlogo.log"

cd "$(dirname "$BOOTLOGO")"

bootlogo "$BOOTLOGO" > "$LOG_FILE" 2>&1
BOOTLOGO_EXIT=$?
display -d 2000 -t "$(tail -1 $LOG_FILE)"
case "$BOOTLOGO_EXIT" in
    0)
        sync
        reboot
        ;;
esac
