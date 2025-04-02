#!/bin/sh

. /mnt/SDCARD/System/bin/helpers.sh

cd "$(dirname "$0")"

BOOTLOGO_MAX_BYTES=524288 # 512KiB
BOOTLOGO="bootlogo.bmp"
LOG_FILE="/mnt/SDCARD/System/log/bootlogo.log"

if [ $(wc -c <$BOOTLOGO) -gt $BOOTLOGO_MAX_BYTES ]; then
    display -d 2000 "Boot logo must be 512KiB or smaller. Exiting..."
    exit 1
fi

display "Updating boot logo..."
dd if=$BOOTLOGO of=/dev/by-name/bootlogo bs=65536 > "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    display -d 2000 "Boot logo update success."
else
    display -d 2000 "Boot logo update failed. Check the log for more details."
fi
