#!/bin/sh

EMU="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emus/${EMU}/config.json"
OPT="/mnt/SDCARD/Emus/.emu/setup/opts/${EMU}.opt"

. "$OPT"

case "$CPU_MODE" in
    "smart")
        NEW_MODE="performance"
        NEW_DISPLAY="Smart-(✓PERFORMANCE)-Overclock"
        ;;
    "performance")
        NEW_MODE="overclock"
        NEW_DISPLAY="Smart-Performance-(✓OVERCLOCK)"
        ;;
    "overclock")
        NEW_MODE="smart"
		NEW_DISPLAY="(✓SMART)-Performance-Overclock"
        ;;
esac

sed -i "s|\"CPU Mode:.*\"|\"CPU Mode: $NEW_DISPLAY\"|g" "$CONFIG"
sed -i "s|CPU_MODE=.*|CPU_MODE=\"$NEW_MODE\"|g" "$OPT"

sleep 1