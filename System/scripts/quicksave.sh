#!/bin/sh
# alternative to MENU Force Save
# relies on auto save/load state

SAVED_CMD_TO_RUN="/mnt/SDCARD/Saves/.quicksave.sh"
SAVED_MAINUI_STATE="/mnt/SDCARD/Saves/.mainui_state"

. /mnt/SDCARD/System/scripts/helpers.sh

if grep -q "/mnt/SDCARD/Emus" /tmp/cmd_to_run.sh && ! [ -f "/tmp/.quicksave" ]; then
  cp /tmp/cmd_to_run.sh "$SAVED_CMD_TO_RUN"
  cp /tmp/state.json "$SAVED_MAINUI_STATE"
  
  touch /tmp/.quicksave
  if pgrep pico8_dyn >/dev/null 2>&1; then
      killall -15 pico8_dyn
  else
    killall ra32.trimui ra32.trimui_sdl
    while killall -q -0 ra32.trimui ||
        killall -q -0 ra32.trimui_sdl; do
        sleep 0.5
        killall ra32.trimui ra32.trimui_sdl
    done
  fi
  sync
  LD_LIBRARY_PATH="/usr/trimui/lib" display -p -t "It's now safe to turn off your Smart"
fi
