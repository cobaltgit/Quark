#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
GAME="$(basename "$1")"
SYS_OPT="/mnt/SDCARD/Emus/.emu_setup/opts/${EMU}.opt"

OVERRIDE_FILE="/mnt/SDCARD/Emus/.emu_setup/overrides/${EMU}/${GAME}.opt"
OVERRIDE_DIR="$(dirname "$OVERRIDE_FILE")"

mkdir -p "$OVERRIDE_DIR"

cp -f "$SYS_OPT" "$OVERRIDE_FILE"

display -d 1000 -t "Saved CPU override for game $GAME"