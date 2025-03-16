#!/bin/sh

. /mnt/SDCARD/System/bin/helpers.sh

export EMU="$(echo "$1" | cut -d'/' -f5)"
export GAME="$(basename "$1")"
export EMU_DIR="/mnt/SDCARD/Emus/${EMU}"
export OPT_DIR="/mnt/SDCARD/Emus/.emu_setup/opts"

OVERRIDE_FILE="/mnt/SDCARD/Emus/.emu_setup/overrides/$EMU/$GAME.opt"

[ -f "$OPT_DIR/$EMU.opt" ] && . "$OPT_DIR/$EMU.opt"
[ -f "$OVERRIDE_FILE" ] && . "$OVERRIDE_FILE"

run_retroarch() {
    RA_DIR="/mnt/SDCARD/RetroArch"

    if [ "$EMU" = "SEGACD" ] && [ "${ROM_FILE##*.}" = "chd" ]; then # picodrive doesn't seem to like playing CD audio with chds
        CORE="genesis_plus_gx"
    fi

    CORE_PATH="$RA_DIR/.retroarch/cores/${CORE}_libretro.so"
    RA_BIN="ra32.trimui"

    cd "$RA_DIR"

    if [ "$EMU" = "PS" ]; then # alleviates stutter in some PSX games
        RA_BIN="ra32.trimui_sdl"
        [ ! -f "retroarch_sdl.cfg" ] && cp retroarch.cfg retroarch_sdl.cfg # config path is hard-coded, unfortunately. attempting to use bind mount causes a segmentation fault when accessing the menu on first run
    fi

    HOME="$RA_DIR/" "$RA_DIR/$RA_BIN" -v -L "$CORE_PATH" "$ROM_FILE"

    [ "$RA_BIN" = "ra32.trimui_sdl" ] && cp retroarch_sdl.cfg retroarch.cfg # copy back
}

run_port() {
    cd "$EMU_DIR"
    /bin/sh "$ROM_FILE"
}

run_openbor() {
    cd "$EMU_DIR"
    export LD_LIBRARY_PATH="$EMU_DIR:$LD_LIBRARY_PATH"

    ./OpenBOR.trimui "$ROM_FILE"
}

ROM_FILE="$(readlink -f "$1")"

if [ "$CPU_MODE" = "smart" ]; then
    { # speed up game launch
        set_cpuclock "performance"
        sleep 5
        set_cpuclock "smart"
    } &
else
    set_cpuclock "$CPU_MODE"
fi

case "$EMU" in
    "OPENBOR") run_openbor ;;
    "PORTS") run_port ;;
    *) run_retroarch ;;
esac

CPU_MIN_FREQ=816000 set_cpuclock "smart" # reset cpu clock