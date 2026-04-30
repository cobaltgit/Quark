#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emus/${EMU}/config.json"
OPT="/mnt/SDCARD/Emus/.emu_setup/opts/${EMU}.opt"

. "$OPT"

case "$CPU_MODE" in
    "smart")
        NEW_MODE="performance"
        NEW_DISPLAY="Perf"
        ;;
    "performance")
        NEW_MODE="maximum"
        NEW_DISPLAY="Max"
        ;;
    "maximum"|"overclock")
        NEW_MODE="turbo"
		NEW_DISPLAY="Turbo"
        ;;
    "turbo")
        NEW_MODE="overdrive"
		NEW_DISPLAY="Overdrive"
        ;;
    "overdrive")
        NEW_MODE="unstable"
    	NEW_DISPLAY="Unstable"
        ;;
    "unstable")
        NEW_MODE="smart"
        NEW_DISPLAY="Smart"
        ;;
esac

sed -i "s|\"CPU:.*\"|\"CPU: $NEW_DISPLAY\"|g" "$CONFIG"
sed -i "s|CPU_MODE=.*|CPU_MODE=\"$NEW_MODE\"|g" "$OPT"

case "$NEW_MODE" in
    turbo|overdrive|unstable)
        display -d 1000 -t "CPU mode for $EMU set to $NEW_MODE. This is potentially unstable and will result in reduced battery life."
        ;;
    *)
        display -d 1000 -t "CPU mode for $EMU set to $NEW_MODE."
        ;;
esac
