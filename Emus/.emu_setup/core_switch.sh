#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emus/${EMU}/config.json"
OPT="/mnt/SDCARD/Emus/.emu_setup/opts/${EMU}.opt"

. "$OPT"

case "$EMU" in
    "FC"|"FDS")
        case "$CORE" in
            "fceumm") NEW_CORE="nestopia" DISPLAY="Core: Nestopia" ;;
            "nestopia") NEW_CORE="fceumm" DISPLAY="Core: FCEUmm" ;;
        esac
        ;;
    "GBA")
        case "$CORE" in
            "gpsp") NEW_CORE="mgba" DISPLAY="Core: mGBA" ;;
            "mgba") NEW_CORE="gpsp" DISPLAY="Core: gpSP" ;;
        esac
        ;;
    "MAME2003PLUS")
        case "$CORE" in
            "mame2003_plus") NEW_CORE="km_mame2003_xtreme_amped" DISPLAY="Core: Xtreme" ;;
            "km_mame2003_xtreme_amped") NEW_CORE="mame2003_plus" DISPLAY="Core: Plus" ;;
        esac
        ;;
    "SFC")
        case "$CORE" in
            "chimerasnes") NEW_CORE="supafaust" DISPLAY="Core: Supafaust" ;;
            "supafaust") NEW_CORE="snes9x2005_plus" DISPLAY="Core: Snes9x-05+" ;;
            "snes9x2005_plus") NEW_CORE="chimerasnes" DISPLAY="Core: Chimera" ;;
        esac
        ;;
    "GG"|"MD"|"MS"|"SEGACD"|"SG1000")
        case "$CORE" in
            "picodrive") NEW_CORE="genesis_plus_gx" DISPLAY="Core: Gen+GX" ;;
            "genesis_plus_gx") NEW_CORE="picodrive" DISPLAY="Core: Picodrive" ;;
        esac
        ;;
esac

sed -i "s|CORE=.*|CORE=\"$NEW_CORE\"|" "$OPT"
sed -i "s|\"Core:.*\"|\"$DISPLAY\"|g" "$CONFIG"

display -d 1000 -t "Core for $EMU changed to $NEW_CORE."