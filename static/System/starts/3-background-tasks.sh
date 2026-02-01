#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

touch /tmp/.play_bootvideo

sysjson-monitor & # Listens for system changes
quark-hotkeyd & # Hotkey listeners
