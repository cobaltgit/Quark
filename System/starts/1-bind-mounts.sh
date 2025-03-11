#!/bin/sh

SRC_DIR="/mnt/SDCARD/System/trimui/"
DEST_DIR="/usr/trimui"

{
    mount -o bind "$SRC_DIR/res/lang" "$DEST_DIR/res/lang"
} &