#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

export HOME="$(dirname "$0")"
export LD_LIBRARY_PATH="$HOME/lib:$LD_LIBRARY_PATH"
export SDL_VIDEO_FBCON_ROTATION="CCW"

cd "$HOME"

./reader
