#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

GUEST_MODE=$(get_setting "user" "guest")

if [ "$GUEST_MODE" = "true" ]; then
    GUEST_MODE=false

    umount /mnt/SDCARD/Saves
    umount /mnt/SDCARD/Roms/favourite2.json
    umount /mnt/SDCARD/Roms/recentlist.json
    umount /mnt/SDCARD/RetroArch/content_history.lpl
    umount /mnt/SDCARD/RetroArch/content_image_history.lpl
    umount /mnt/SDCARD/RetroArch/content_music_history.lpl
    umount /mnt/SDCARD/RetroArch/content_favorites.lpl

    sed -i -e 's|\[ON\]|\[OFF\]|' -e 's|icon-on.png|icon-off.png|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Disabled guest profile..."
else
    GUEST_MODE=true

    mount -o bind /mnt/SDCARD/Saves/.guest /mnt/SDCARD/Saves
    mount -o bind /mnt/SDCARD/Roms/favourite2.guest.json /mnt/SDCARD/Roms/favourite2.json
    mount -o bind /mnt/SDCARD/Roms/recentlist.guest.json /mnt/SDCARD/Roms/recentlist.json
    mount -o bind /mnt/SDCARD/RetroArch/content_history_guest.lpl /mnt/SDCARD/RetroArch/content_history.lpl
    mount -o bind /mnt/SDCARD/RetroArch/content_image_history_guest.lpl /mnt/SDCARD/RetroArch/content_image_history.lpl
    mount -o bind /mnt/SDCARD/RetroArch/content_music_history_guest.lpl /mnt/SDCARD/RetroArch/content_music_history.lpl
    mount -o bind /mnt/SDCARD/RetroArch/content_favorites_guest.lpl /mnt/SDCARD/RetroArch/content_favorites.lpl

    sed -i -e 's|\[OFF\]|\[ON\]|' -e 's|icon-off.png|icon-on.png|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Enabled guest profile..."
fi

update_setting "user" "guest" "$GUEST_MODE"