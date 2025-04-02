#!/bin/sh
# Refresh icon by Icons8
# https://icons8.com/icon/59872/refresh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU_DIR="/mnt/SDCARD/Emus"
SHOWN_COUNT=0
HIDDEN_COUNT=0

set_cpuclock --mode performance

display -t "Refreshing displayed emulators..."

for EMU in "$EMU_DIR"/*; do
    if [ -d "$EMU" ]; then
        EXTENSIONS="$(awk -F ':' '/extlist/ {print $2}' "$EMU/config.json" | sed 's/^[[:space:]]*//; s/[",]//g')" # no jq? no problem. might add it later down the line though
        ROM_DIR="$EMU/$(awk -F ':' '/rompath/ {print $2}' "$EMU/config.json" | sed 's/^[[:space:]]*//; s/[",]//g')"
        ROM_COUNT="$(find "$ROM_DIR" -type f ! -path "*/Imgs/*" ! -name *.xml ! -name *.txt ! -name ".gitkeep" ! -name "*cache7.db" | sed '/^\s*$/d' | grep -icE "\.($EXTENSIONS)$")"
        
        if [ "$ROM_COUNT" -eq 0 ]; then
            echo "EmuClean: no roms, hiding $EMU"
            sed -i 's/^{*$/{{/' "$EMU/config.json" # break config.json so emulator doesn't show
            HIDDEN_COUNT=$((HIDDEN_COUNT + 1))
        elif [ "$ROM_COUNT" -gt 0 ]; then
            echo "EmuClean: $ROM_COUNT roms detected in system $EMU, showing"
            sed -i 's/^{{*$/{/' "$EMU/config.json" # fix config.json to show emulator
            SHOWN_COUNT=$((SHOWN_COUNT + 1))
        fi
    fi
done

display -d 2000 -t "Done! $SHOWN_COUNT systems shown, $HIDDEN_COUNT systems hidden"

set_cpuclock --mode smart # reset cpu clock