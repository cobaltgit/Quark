#!/bin/sh

SRC_DIR="/mnt/SDCARD/System/trimui"
DEST_DIR="/usr/trimui"

{
    rm -f /mnt/UDISK/Store/cache.zip
    rm -rf /mnt/UDISK/Store/.cache

    mount -o bind "/mnt/SDCARD/System/scripts/usb_storage_disabled.sh" "/usr/trimui/apps/usb_storage/launch.sh" # disable USB storage app
    mount -o bind "/mnt/SDCARD" "/mnt/UDISK/Apps" # app store will install onto SD card
    mount -o bind "$SRC_DIR/bin/MainUI" "$DEST_DIR/bin/MainUI" # patched MainUI for appstore
    mount -o bind "$SRC_DIR/res/lang" "$DEST_DIR/res/lang"
} &