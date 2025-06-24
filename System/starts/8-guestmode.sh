#!/bin/sh
# Setup guest mode on boot

. /mnt/SDCARD/System/scripts/helpers.sh

GUESTMODE_APP="/mnt/SDCARD/Apps/GuestMode"

if $(get_setting "user" "guest"); then
    mount -o bind /mnt/SDCARD/Saves/.guest /mnt/SDCARD/Saves
    sed -i 's|\[OFF\]|\[ON\]|' "$GUESTMODE_APP/config.json"
else
    sed -i 's|\[ON\]|\[OFF\]|' "$GUESTMODE_APP/config.json"
fi