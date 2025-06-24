#!/bin/sh
# Refresh icon by Icons8
# https://icons8.com/icon/59872/refresh

. /mnt/SDCARD/System/scripts/helpers.sh

GUEST_MODE=$(get_setting "user" "guest")

if $GUEST_MODE; then
    GUEST_MODE=false
    umount /mnt/SDCARD/Saves
    sed -i 's|\[ON\]|\[OFF\]|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Disabled guest profile..."
else
    GUEST_MODE=true
    mount -o bind /mnt/SDCARD/Saves/.guest /mnt/SDCARD/Saves
    sed -i 's|\[OFF\]|\[ON\]|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Enabled guest profile..."
fi

update_setting "user" "guest" "$GUEST_MODE"