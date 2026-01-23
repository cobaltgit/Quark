#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh || . /mnt/SDCARD/System/bin/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
GAME="$(basename "$1")"
EMU_DIR="/mnt/SDCARD/Emus/${EMU}"
OPT_DIR="/mnt/SDCARD/Emus/.emu_setup/opts"

OVERRIDE_FILE="/mnt/SDCARD/Emus/.emu_setup/overrides/$EMU/$GAME.opt"

[ -f "$OPT_DIR/$EMU.opt" ] && . "$OPT_DIR/$EMU.opt"
[ -f "$OVERRIDE_FILE" ] && . "$OVERRIDE_FILE"

export HOME="$EMU_DIR"
export PATH="$EMU_DIR:$PATH"
export LD_LIBRARY_PATH="$EMU_DIR/lib:$LD_LIBRARY_PATH"
export SDL_VIDEO_FBCON_ROTATION="CCW"

if [ "$CPU_MODE" = "smart" ]; then
    { # speed up game launch
        set_cpuclock --mode performance
        sleep 5
        set_cpuclock --mode smart --min-freq $CPU_MIN_FREQ
    } &
else
    set_cpuclock --mode "$CPU_MODE"
fi

cd "$EMU_DIR"

echo 1 > /tmp/stay_awake

cat /dev/zero > /dev/fb0

ffplay -x 320 -y 240 -fs -i "$(readlink -f "$1")" >/dev/null 2>&1

rm -f /tmp/stay_awake

set_cpuclock --mode smart