#!/bin/sh
# Setup guest mode on boot

. /mnt/SDCARD/System/scripts/helpers.sh

GUESTMODE_APP="/mnt/SDCARD/Apps/GuestMode"

if [ $(get_setting "user" "guest") = "true" ]; then
    mount -o bind /mnt/SDCARD/Saves/.guest /mnt/SDCARD/Saves
    mount -o bind /mnt/SDCARD/Roms/favourite2.guest.json /mnt/SDCARD/Roms/favourite2.json
    mount -o bind /mnt/SDCARD/Roms/recentlist.guest.json /mnt/SDCARD/Roms/recentlist.json
    mount -o bind /mnt/SDCARD/RetroArch/content_history_guest.lpl /mnt/SDCARD/RetroArch/content_history.lpl
    mount -o bind /mnt/SDCARD/RetroArch/content_image_history_guest.lpl /mnt/SDCARD/RetroArch/content_image_history.lpl
    mount -o bind /mnt/SDCARD/RetroArch/content_music_history_guest.lpl /mnt/SDCARD/RetroArch/content_music_history.lpl
    mount -o bind /mnt/SDCARD/RetroArch/content_favorites_guest.lpl /mnt/SDCARD/RetroArch/content_favorites.lpl

    sed -i -e 's|\[OFF\]|\[ON\]|' -e 's|icon-off.png|icon-on.png|' "$GUESTMODE_APP/config.json"
else
    sed -i -e 's|\[ON\]|\[OFF\]|' -e 's|icon-on.png|icon-off.png|' "$GUESTMODE_APP/config.json"
fi