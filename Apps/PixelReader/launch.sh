#!/bin/sh

export HOME="$(dirname "$0")"
export LD_LIBRARY_PATH="$HOME/lib:$LD_LIBRARY_PATH"
export SDL_VIDEO_FBCON_ROTATION="ccw"

cd "$HOME"

./reader
