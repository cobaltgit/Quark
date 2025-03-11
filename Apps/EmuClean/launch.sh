#!/bin/sh

EMU_DIR="/mnt/SDCARD/Emus"

for EMU in "$EMU_DIR"/*; do
    if [ -d "$EMU" ]; then
        EXTENSIONS="$(awk -F ':' '/extlist/ {print $2}' "$EMU/config.json" | sed 's/^ \"//;s/\",$//')" # no jq? no problem. might add it later down the line though
        ROM_DIR="$EMU/$(awk -F ':' '/rompath/ {print $2}' "$EMU/config.json" | sed 's/^ \"//;s/\",$//')"
        ROM_COUNT="$(find "$ROM_DIR" -type f -iname "*.*[$EXTENSIONS]" | grep -v "Imgs\/$" | wc -l)"
        
        if [ "$ROM_COUNT" -eq 0 ]; then
            echo "EmuClean: no roms, hiding $EMU"
            sed -i 's/^{*$/{{/' "$EMU/config.json" # break config.json so emulator doesn't show
        elif [ "$ROM_COUNT" -gt 0 ]; then
            echo "EmuClean: $ROM_COUNT roms detected in system $EMU, showing"
            sed -i 's/^{{*$/{/' "$EMU/config.json" # fix config.json to show emulator
        fi
    fi
done