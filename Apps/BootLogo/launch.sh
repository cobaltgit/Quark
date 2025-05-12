#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

BOOTLOGO="bootlogo_$PLATFORM.bmp"
LOG_FILE="/mnt/SDCARD/System/log/bootlogo.log"

cd "$(dirname "$0")"

case "$PLATFORM" in
    "tg2040")
        BOOTLOGO_MAX_BYTES=524288 # 512KiB
        BOOTLOGO_WIDTH=$(magick identify -ping -format "%w" "$BOOTLOGO")
        BOOTLOGO_HEIGHT=$(magick identify -ping -format "%h" "$BOOTLOGO")

        if [ $(wc -c <$BOOTLOGO) -gt $BOOTLOGO_MAX_BYTES ]; then
            log_message "BootLogo: must be 512KiB or smaller" "$LOG_FILE"
            display -d 2000 -t "Boot logo must be 512KiB or smaller. Exiting..."
            exit 1
        elif [ $BOOTLOGO_WIDTH -gt 240 ] || [ $BOOTLOGO_HEIGHT -gt 320 ]; then
            log_message "BootLogo: dimensions must not exceed 240x320, got ${BOOTLOGO_WIDTH}x${BOOTLOGO_HEIGHT}" "$LOG_FILE"
            display -d 2000 -t "Boot logo dimensions must not exceed 240x320. Exiting..."
            exit 1
        fi

        log_message "BootLogo: Updating boot logo..." "$LOG_FILE"
        display -t "Updating bootlogo..."
        if dd if=$BOOTLOGO of=/dev/by-name/bootlogo bs=65536 >> "$LOG_FILE" 2>&1; then
            log_message "BootLogo: update success" "$LOG_FILE"
            display -d 2000 -t "Boot logo update success."
        else
            log_message "BootLogo: update failed" "$LOG_FILE"
            display -d 2000 -t "Boot logo update failed. Check the log for more details."
        fi
        ;;
    "tg5040"|"tg3040")
        BOOTLOGO_MAX_BYTES=6000000 # 6MB
        case "$PLATFORM" in
            "tg5040") MAX_WIDTH=1280 MAX_HEIGHT=720 ;;
            "tg3040") MAX_WIDTH=1024 MAX_HEIGHT=768 ;;
        esac
        BOOTLOGO_WIDTH=$(magick identify -ping -format "%w" "$BOOTLOGO")
        BOOTLOGO_HEIGHT=$(magick identify -ping -format "%h" "$BOOTLOGO")

        if [ $(wc -c <$BOOTLOGO) -gt $BOOTLOGO_MAX_BYTES ]; then
            log_message "BootLogo: must be 6MB or smaller" "$LOG_FILE"
            display -d 2000 -t "Boot logo must be MB or smaller. Exiting..."
            exit 1
        elif [ $BOOTLOGO_WIDTH -gt $MAX_WIDTH ] || [ $BOOTLOGO_HEIGHT -gt $MAX_HEIGHT ]; then
            log_message "BootLogo: dimensions must not exceed ${MAX_WIDTH}x${MAX_HEIGHT}, got ${BOOTLOGO_WIDTH}x${BOOTLOGO_HEIGHT}" "$LOG_FILE"
            display -d 2000 -t "Boot logo dimensions must not exceed ${MAX_WIDTH}x${MAX_HEIGHT}. Exiting..."
            exit 1
        fi

        log_message "BootLogo: Updating boot logo..." "$LOG_FILE"
        display -t "Updating bootlogo..."

        if mkdir -p /mnt/boot && mount -t vfat /dev/mmcblk0p1 /mnt/boot && \
            cp "$BOOTLOGO" /mnt/boot/bootlogo.bmp && \
            sync; then
            log_message "BootLogo: update success" "$LOG_FILE"
            display -d 2000 -t "Boot logo update success."
        else
            log_message "BootLogo: update failed" "$LOG_FILE"
            display -d 2000 -t "Boot logo update failed. Check the log for more details."
        fi
        umount /mnt/boot 2>/dev/null
        rm -rf /mnt/boot
        sync
        ;;
esac