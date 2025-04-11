#!/bin/sh

FIRST_BOOT_COMPLETE_FLAG="/mnt/SDCARD/System/etc/first_boot"

if [ ! -f "$FIRST_BOOT_COMPLETE_FLAG" ]; then
    echo "Running first boot script"

    find "/mnt/SDCARD" -type f -name ".gitkeep" -exec rm -f {} +

    cp /mnt/SDCARD/System/etc/system.json /mnt/UDISK/system.json

    /mnt/SDCARD/Apps/EmuClean/launch.sh

    touch "$FIRST_BOOT_COMPLETE_FLAG"
fi