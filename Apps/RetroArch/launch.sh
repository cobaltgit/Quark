#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

[ "$PLATFORM" = "tg2040" ] && RA_BIN="ra32.trimui" || RA_BIN="ra64.trimui"

RA_DIR=/mnt/SDCARD/RetroArch
cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/$RA_BIN -v
