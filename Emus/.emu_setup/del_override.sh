#!/bin/sh

EMU="$(echo "$1" | cut -d'/' -f5)"
GAME="$(basename "$1")"
OVERRIDE_FILE="/mnt/SDCARD/Emus/.emu_setup/overrides/${EMU}/${GAME}.opt"

rm -f "$SYS_OPT" "$OVERRIDE_FILE"