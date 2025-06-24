#!/bin/sh
# Setup guest mode on boot

. /mnt/SDCARD/System/scripts/helpers.sh

GUESTMODE_APP="/mnt/SDCARD/Apps/GuestMode"

if [ $(get_setting "user" "guest") = "true" ]; then
    mount -o bind /mnt/SDCARD/Saves/.guest /mnt/SDCARD/Saves
    sed -i -e 's|\[OFF\]|\[ON\]|' -e 's|icon-off.png|icon-on.png|' "$(dirname "$0")/config.json"
else
    sed -i -e 's|\[ON\]|\[OFF\]|' -e 's|icon-on.png|icon-off.png|' "$(dirname "$0")/config.json"
fi