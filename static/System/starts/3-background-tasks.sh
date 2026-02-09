#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

BOOT_VIDEO="$THEME_PATH/bootvideo.mp4"

[ -f "$BOOT_VIDEO" ] && touch /tmp/.play_bootvideo

sysjson_monitor & # Listens for system changes
quark_hotkeyd & # Hotkey listeners
