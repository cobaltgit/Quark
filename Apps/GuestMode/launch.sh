#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

GUEST_MODE=$(get_setting "user" "guest")

if [ "$GUEST_MODE" = "true" ]; then
    GUEST_MODE=false
    umount /mnt/SDCARD/Saves
    sed -i -e 's|\[ON\]|\[OFF\]|' -e 's|icon-on.png|icon-off.png|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Disabled guest profile..."
else
    GUEST_MODE=true
    mount -o bind /mnt/SDCARD/Saves/.guest /mnt/SDCARD/Saves
    sed -i -e 's|\[OFF\]|\[ON\]|' -e 's|icon-off.png|icon-on.png|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Enabled guest profile..."
fi

update_setting "user" "guest" "$GUEST_MODE"