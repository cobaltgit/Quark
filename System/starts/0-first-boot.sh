#!/bin/sh

FIRST_BOOT_COMPLETE_FLAG="/mnt/SDCARD/System/etc/first_boot"

if [ ! -f "$FIRST_BOOT_COMPLETE_FLAG" ]; then
    echo "Running first boot script"
    /mnt/SDCARD/Apps/EmuClean/launch.sh

    touch "$FIRST_BOOT_COMPLETE_FLAG"
fi