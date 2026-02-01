#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

RA_DIR=/mnt/SDCARD/RetroArch
cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra32.trimui -v
