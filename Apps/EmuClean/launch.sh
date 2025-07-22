#!/bin/sh
# Refresh icon by Icons8
# https://icons8.com/icon/59872/refresh

. /mnt/SDCARD/System/scripts/helpers.sh

LOG_FILE="/mnt/SDCARD/System/log/emuclean.log"
EMU_DIR="/mnt/SDCARD/Emus"
SHOWN_COUNT=0
HIDDEN_COUNT=0

set_cpuclock --mode performance

display -t "Refreshing displayed emulators..."

for EMU in "$EMU_DIR"/*; do
    if [ -d "$EMU" ]; then
        BASENAME="$(basename "$EMU")"
        EXTENSIONS="$(awk -F ':' '/extlist/ {print $2}' "$EMU/config.json" | sed 's/^[[:space:]]*//; s/[",]//g')" # no jq? no problem. might add it later down the line though
        ROM_DIR="$EMU/$(awk -F ':' '/rompath/ {print $2}' "$EMU/config.json" | sed 's/^[[:space:]]*//; s/[",]//g')"
        ROM_COUNT="$(find "$ROM_DIR" -type f ! -path "*/Imgs/*" ! -name *.xml ! -name *.txt ! -name ".gitkeep" ! -name "*cache7.db" | sed '/^\s*$/d' | grep -icE "\.($EXTENSIONS)$")"
        
        if [ "$ROM_COUNT" -eq 0 ]; then
            log_message "EmuClean: no roms found in $EMU, hiding" "$LOG_FILE"
            sed -i 's/^{*$/{{/' "$EMU/config.json" # intentionally break config.json so system doesn't show in MainUI
            HIDDEN_COUNT=$((HIDDEN_COUNT + 1))
        elif [ "$ROM_COUNT" -gt 0 ]; then
            log_message "EmuClean: $ROM_COUNT roms detected in system $EMU, showing" "$LOG_FILE"
            sed -i 's/^{{*$/{/' "$EMU/config.json" # fix config.json to show system in MainUI
            rm -f "/mnt/SDCARD/Roms/$BASENAME/${BASENAME}_cache7.db"
            SHOWN_COUNT=$((SHOWN_COUNT + 1))
        fi
    fi
done

log_message "EmuClean: finished - $SHOWN_COUNT show, $HIDDEN_COUNT hidden" "$LOG_FILE"

display -d 2000 -t "Done! $SHOWN_COUNT systems shown, $HIDDEN_COUNT systems hidden"

set_cpuclock --mode smart # reset cpu clock