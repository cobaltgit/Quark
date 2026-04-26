#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd "$(dirname "$0")"

exec bootlogo --reboot > "$BOOTLOGO_LOG" 2>&1
