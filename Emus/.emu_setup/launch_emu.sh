#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

export EMU="$(echo "$1" | cut -d'/' -f5)"
export GAME="$(basename "$1")"
export EMU_DIR="/mnt/SDCARD/Emus/${EMU}"
export OPT_DIR="/mnt/SDCARD/Emus/.emu_setup/opts"

OVERRIDE_FILE="/mnt/SDCARD/Emus/.emu_setup/overrides/$EMU/$GAME.opt"

[ -f "$OPT_DIR/$EMU.opt" ] && . "$OPT_DIR/$EMU.opt"
[ -f "$OVERRIDE_FILE" ] && . "$OVERRIDE_FILE"

run_retroarch() {
    RA_DIR="/mnt/SDCARD/RetroArch"
    cd "$RA_DIR"

    if [ "$EMU" = "SEGACD" ] && [ "${ROM_FILE##*.}" = "chd" ]; then # picodrive doesn't seem to like playing CD audio with chds
        CORE="genesis_plus_gx"
    fi

    RA_BIN="ra32.trimui"
    if [ "$EMU" = "PS" ] || [ "$EMU" = "SFC" ]; then # Improved SNES/PSX performance
        RA_BIN="ra32.trimui_sdl"
        cp -f retroarch.cfg retroarch_sdl.cfg # config path is hard-coded, unfortunately. attempting to use bind mount causes a segmentation fault when accessing the menu on first run
    fi

    if [ -n "$NET_PARAM" ]; then
        for NETPLAY_UNSUPPORTED_CORE in a5200 ardens atari800 bluemsx dosbox_pure easyrpg ecwolf fake08 fbalpha2012_cps3 freechaf \
             freeintv fuse gw hatari neocd pcsx_rearmed pokemini potator prboom prosystem \
             px68k tic80 tyrquake uae4arm vice_x64 vice_xvic; do
            if [ "$CORE" = "$NETPLAY_UNSUPPORTED_CORE" ]; then
                NET_PARAM=
                break
            fi
        done
    fi

    CORE_PATH="$RA_DIR/.retroarch/cores/${CORE}_libretro.so"

    HOME="$RA_DIR/" "$RA_DIR/$RA_BIN" -v $NET_PARAM -L "$CORE_PATH" "$ROM_FILE"

    [ "$RA_BIN" = "ra32.trimui_sdl" ] && cp -f retroarch_sdl.cfg retroarch.cfg # copy back
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

run_mp3() {
    cd "$EMU_DIR"

    echo 1 > /tmp/stay_awake

    ./mp3player.elf "$ROM_FILE"

    rm /tmp/stay_awake
}

ROM_FILE="$(readlink -f "$1")"

if [ "$CPU_MODE" = "smart" ]; then
    { # speed up game launch
        set_cpuclock --mode performance
        sleep 5
        set_cpuclock --mode smart --min-freq $CPU_MIN_FREQ
    } &
else
    set_cpuclock --mode "$CPU_MODE"
fi

case "$EMU" in
    "MP3") run_mp3 ;;
    "OPENBOR") run_openbor ;;
    "PORTS") run_port ;;
    *) run_retroarch ;;
esac

set_cpuclock --mode smart # reset cpu clock