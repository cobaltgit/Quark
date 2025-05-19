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

        mkdir -p /tmp/PortMaster && mount -o bind /tmp/PortMaster /mnt/SDCARD/Apps/PortMaster

        for UNSUPPORTED_SYSTEM in N64 DC PSP SATURN; do
            mkdir -p "/tmp/$UNSUPPORTED_SYSTEM" && mount -o bind "/tmp/$UNSUPPORTED_SYSTEM" "/mnt/SDCARD/Emus/$UNSUPPORTED_SYSTEM"
        done

    else
        mount -o bind "/mnt/SDCARD/System/bin64" "/mnt/SDCARD/System/bin"
        mount -o bind "/mnt/SDCARD/System/lib64" "/mnt/SDCARD/System/lib"

        [ -d "/mnt/SDCARD/Roms/PORTS64" ] && mount -o bind "/mnt/SDCARD/Roms/PORTS64" "/mnt/SDCARD/Roms/PORTS"
        [ -f "/mnt/SDCARD/System/bin64/bash" ] && ln -s "/mnt/SDCARD/System/bin64/bash" "/bin/bash"

        if [ -f "/mnt/SDCARD/System/bin64/busybox" ]; then # PortMaster stuff
            mount -o bind "/mnt/SDCARD/System/bin64/busybox" "/bin/busybox"
            for cmd in $(busybox --list); do
                [ -e "/usr/bin/$cmd" ] || [ -e "/bin/$cmd" ] || [ "$cmd" = "sh" ] || [ "$cmd" = "bash" ] || ln -s "/bin/busybox" "/usr/bin/$cmd"
            done
        fi

        if [ -f "/mnt/SDCARD/Apps/PortMaster/PortMaster/control.txt" ]; then
            mkdir -p "/roms/ports/PortMaster" # todo: can we do this without writing to flash??
            mount -o bind "/mnt/SDCARD/Apps/PortMaster/PortMaster/control.txt" "/roms/ports/PortMaster/control.txt"
        fi
    fi
} &