#!/bin/sh

SAVED_CMD_TO_RUN="/mnt/SDCARD/Saves/.quicksave.sh"

. /mnt/SDCARD/System/scripts/helpers.sh

if grep -q "/mnt/SDCARD/Emus" /tmp/cmd_to_run.sh; then
  cp /tmp/cmd_to_run.sh "$SAVED_CMD_TO_RUN"
  kill_cmd_to_run
  sync
  display -t "It's now safe to turn off your Smart"
fi
