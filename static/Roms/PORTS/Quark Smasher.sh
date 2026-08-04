#!/bin/sh

#### BEGIN USER SECTION ####
PORT_EXE="butterscotch" # executable file to run
PORT_GAMEDATA_PATH="assets/game.unx"
PORT_CMDLINE="--renderer software $PORT_GAMEDATA_PATH" # CLI args to pass to port executable
#### END USER SECTION ####

PORT_HOME="$(dirname "$0")/.data/$(basename "$0" .sh)"

export HOME="$PORT_HOME"
export SDL_VIDEO_FBCON_ROTATION="CCW" # correct rotation for screen (240x320 -> 320x240) for SDL 1.2-based applications

# fix esc not registering, needed to gracefully quit
L2R2_COMBO=$(cat /sys/module/gpio_keys_polled/parameters/l2r2combokey)
echo 0 > /sys/module/gpio_keys_polled/parameters/l2r2combokey

cd "$PORT_HOME"

# do stuff here before launching the port

[ -f "$PORT_GAMEDATA_PATH" ] || exit 1

./$PORT_EXE $PORT_CMDLINE

echo $L2R2_COMBO > /sys/module/gpio_keys_polled/parameters/l2r2combokey
