#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd "$(dirname "$0")"

BOOTLOGO_MAX_BYTES=524288 # 512KiB
BOOTLOGO="bootlogo.bmp"
LOG_FILE="/mnt/SDCARD/System/log/bootlogo.log"

if [ $(wc -c <$BOOTLOGO) -gt $BOOTLOGO_MAX_BYTES ]; then
    log_message "BootLogo: must be 512KiB or smaller" "$LOG_FILE"
    display -d 2000 -t "Boot logo must be 512KiB or smaller. Exiting..."
    exit 1
fi

log_message "BootLogo: Updating boot logo..." "$LOG_FILE"
display -t "Updating bootlogo..."
dd if=$BOOTLOGO of=/dev/by-name/bootlogo bs=65536 >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log_message "BootLogo: update success" "$LOG_FILE"
    display -d 2000 -t "Boot logo update success."
else
    log_message "BootLogo: update failed" "$LOG_FILE"
    display -d 2000 -t "Boot logo update failed. Check the log for more details."
fi
