#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emus/${EMU}/config.json"
OPT="/mnt/SDCARD/Emus/.emu_setup/opts/${EMU}.opt"

. "$OPT"

case "$SATURN_USE_REAL_BIOS" in
    "true") NEW_USE_REAL_BIOS=false NEW_DISPLAY="HLE" ;;
    "false") NEW_USE_REAL_BIOS=true NEW_DISPLAY="Real" ;;
esac

sed -i "s|\"BIOS:.*\"|\"BIOS: $NEW_DISPLAY\"|g" "$CONFIG"
sed -i "s|SATURN_USE_REAL_BIOS=.*|SATURN_USE_REAL_BIOS=\"$NEW_USE_REAL_BIOS\"|g" "$OPT"

display -d 1000 -t "Yaba Sanshiro BIOS set to $NEW_DISPLAY mode."