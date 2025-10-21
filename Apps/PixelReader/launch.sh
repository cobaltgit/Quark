#!/bin/sh

export HOME="$(dirname "$0")"
export LD_LIBRARY_PATH="$HOME/lib:$LD_LIBRARY_PATH"

cd "$HOME"

./reader
