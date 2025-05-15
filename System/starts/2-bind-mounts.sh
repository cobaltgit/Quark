#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

SRC_DIR="/mnt/SDCARD/System/trimui/$PLATFORM"
DEST_DIR="/usr/trimui"

{
    mount -o bind /mnt/SDCARD/System/etc/retroarch/retroarch.$PLATFORM.cfg /mnt/SDCARD/RetroArch/retroarch.cfg
    mount -o bind /mnt/SDCARD/System/res/overlays/$PLATFORM /mnt/SDCARD/RetroArch/.retroarch/overlay

    if [ "$PLATFORM" = "tg2040" ]; then
        rm -rf /mnt/UDISK/Store/.cache

        mount -o bind "/mnt/SDCARD/System/scripts/usb_storage_disabled.sh" "/usr/trimui/apps/usb_storage/launch.sh" # disable USB storage app
        mount -o bind "/mnt/SDCARD" "/mnt/UDISK/Apps" # app store will install onto SD card
        mount -o bind "$SRC_DIR/bin/MainUI" "$DEST_DIR/bin/MainUI" # patched MainUI for appstore
        mount -o bind "$SRC_DIR/res/lang" "$DEST_DIR/res/lang"

        for UNSUPPORTED_SYSTEM in N64 DC PSP SATURN; do
            mkdir -p "/tmp/$UNSUPPORTED_SYSTEM" && mount -o bind "/tmp/$UNSUPPORTED_SYSTEM" "/mnt/SDCARD/Emus/$UNSUPPORTED_SYSTEM"
        done
    fi
} &