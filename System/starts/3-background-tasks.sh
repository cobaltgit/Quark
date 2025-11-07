#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

sysjson-monitor & # Listens for system changes
quark-hotkeyd & # Hotkey listeners
