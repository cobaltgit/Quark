#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

touch /tmp/.play_bootvideo

sysjson_monitor & # Listens for system changes
quark_hotkeyd & # Hotkey listeners
