#!/bin/sh
# alternative to MENU Force Save
# relies on auto save/load state

SAVED_CMD_TO_RUN="/mnt/SDCARD/Saves/.quicksave.sh"

. /mnt/SDCARD/System/scripts/helpers.sh

if grep -q "/mnt/SDCARD/Emus" /tmp/cmd_to_run.sh && ! [ -f "/tmp/.quicksave" ]; then
  cp /tmp/cmd_to_run.sh "$SAVED_CMD_TO_RUN"
  touch /tmp/.quicksave
  if pgrep pico8_dyn >/dev/null 2>&1; then
      killall -15 pico8_dyn
  else
    killall ra32.trimui ra32.trimui_sdl drastic
    while killall -q -0 ra32.trimui ||
        killall -q -0 ra32.trimui_sdl ||
        killall -q -0 drastic; do
        sleep 0.5
    done
  fi
  sync
  LD_LIBRARY_PATH="/usr/trimui/lib" display -t "It's now safe to turn off your Smart"
fi
