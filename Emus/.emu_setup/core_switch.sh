#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emus/${EMU}/config.json"
OPT="/mnt/SDCARD/Emus/.emu_setup/opts/${EMU}.opt"

case "$EMU" in
    "GBA")
        if [ "$CORE" = "gpsp" ]; then
            NEW_CORE="mgba"
            DISPLAY="Core: mGBA"
        else
            NEW_CORE="gpsp"
            DISPLAY="Core: gpSP"
        fi
        ;;
    "SFC")
        if [ "$CORE" = "chimerasnes" ]; then
            NEW_CORE="snes9x2005_plus"
            DISPLAY="Core: Snes9x-05+"
        else
            NEW_CORE="chimerasnes"
            DISPLAY="Core: Chimera"
        fi
        ;;
    "GG"|"MD"|"MS"|"SEGACD"|"SG1000")
        if [ "$CORE" = "picodrive" ]; then
            NEW_CORE="genesis_plus_gx"
            DISPLAY="Core: Gen+ GX"
        else
            NEW_CORE="picodrive"
            DISPLAY="Core: Picodrive"
        fi
        ;;
esac

sed -i "s|CORE=.*|CORE=\"$NEW_CORE\"|" "$OPT"
sed -i "s|\"Core:.*\"|\"$NEW_DISPLAY\"|g" "$CONFIG"

display -d 1000 -t "Core for $EMU changed to $NEW_CORE."