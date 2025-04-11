#!/bin/sh

cd "$(dirname "$0")"

BOOTLOGO_MAX_BYTES=524288 # 512KiB
BOOTLOGO="bootlogo.bmp"
LOG_FILE="/mnt/SDCARD/System/log/bootlogo.log"

if [ $(wc -c <$BOOTLOGO) -gt $BOOTLOGO_MAX_BYTES ]; then
    echo "BootLogo: image must not be greater than $BOOTLOGO_MAX_BYTES bytes" > "$LOG_FILE"
    exit 1
fi

echo "BootLogo: writing $BOOTLOGO" > "$LOG_FILE"
dd if=$BOOTLOGO of=/dev/by-name/bootlogo bs=65536 > "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "BootLogo: replacement success!" > "$LOG_FILE"
else
    echo "BootLogo: replacement failed!" > "$LOG_FILE"
fi