#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

BOOTLOGO_LOG="/mnt/SDCARD/System/log/bootlogo.log"

cd "$(dirname "$0")"

if ! bootlogo --reboot > "$BOOTLOGO_LOG" 2>&1; then
  display -d 1500 -t "$(tail -1 "$BOOTLOGO_LOG")"
fi
