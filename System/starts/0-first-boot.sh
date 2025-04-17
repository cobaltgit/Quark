#!/bin/sh

FIRST_INSTALL_COMPLETE_FLAG="/mnt/SDCARD/System/etc/.post_new_install"
FIRST_BOOT_COMPLETE_FLAG="/mnt/SDCARD/System/etc/.post_first_boot"

if [ ! -f "$FIRST_BOOT_COMPLETE_FLAG" ]; then
    echo "Running first boot script"

    if [ ! -f "$FIRST_INSTALL_COMPLETE_FLAG" ]; then # new install stuff
        find "/mnt/SDCARD" -type f -name ".gitkeep" -exec rm -f {} +
        cp /mnt/SDCARD/System/etc/system.json /mnt/UDISK/system.json
        touch "$FIRST_INSTALL_COMPLETE_FLAG"
    fi

    /mnt/SDCARD/Apps/EmuClean/launch.sh

    touch "$FIRST_BOOT_COMPLETE_FLAG"
fi