#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd "$(dirname "$0")"

BOOTLOGO_MAX_BYTES=524288 # 512KiB
BOOTLOGO="bootlogo.bmp"
LOG_FILE="/mnt/SDCARD/System/log/bootlogo.log"

BOOTLOGO_RESOLUTION="$(magick identify -format "%xx%y" "$BOOTLOGO")"
BOOTLOGO_DEPTH="$(magick identify -format "%[bit-depth]-%[type]" "$BOOTLOGO")"

if [ $(wc -c <$BOOTLOGO) -gt $BOOTLOGO_MAX_BYTES ]; then
    log_message "BootLogo: must be 512KiB or smaller" "$LOG_FILE"
    display -d 2000 -t "Boot logo must be 512KiB or smaller. Exiting..."
    exit 1
elif [ "$BOOTLOGO_RESOLUTION" != "240x320" ]; then
    log_message "BootLogo: expected 240x320 resolution, got $BOOTLOGO_RESOLUTION" "$LOG_FILE"
    display -d 2000 -t "Boot logo must be 240x320 resolution. Exiting..."
    exit 1 
elif [ "$BOOTLOGO_DEPTH" != "16-TrueColor" ]; then
    log_message "BootLogo: must be 16-bit RGB565 (16-TrueColor), got $BOOTLOGO_DEPTH" "$LOG_FILE"
    display -d 2000 -t "Boot logo must be a 16-bit (RGB565) image. Exiting..."
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
