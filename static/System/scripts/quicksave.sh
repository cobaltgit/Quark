#!/bin/sh
# alternative to MENU Force Save
# relies on auto save/load state

SAVED_CMD_TO_RUN="/mnt/SDCARD/Saves/quicksave_cmd_to_run.sh"
SAVED_MAINUI_STATE="/mnt/SDCARD/Saves/quicksave_mainui_state.json"

. /mnt/SDCARD/System/scripts/helpers.sh

if grep -q "/mnt/SDCARD/Emus" /tmp/cmd_to_run.sh && pgrep "ra32\.trimui(_sdl)?" >/dev/null 2>&1 && ! [ -f "/tmp/.quicksave" ]; then
  cp /tmp/cmd_to_run.sh "$SAVED_CMD_TO_RUN"
  cp /tmp/state.json "$SAVED_MAINUI_STATE"

  touch /tmp/.quicksave

  killall ra32.trimui ra32.trimui_sdl
  while killall -q -0 ra32.trimui ||
      killall -q -0 ra32.trimui_sdl; do
      sleep 0.5
      killall ra32.trimui ra32.trimui_sdl
  done
  sync
fi
