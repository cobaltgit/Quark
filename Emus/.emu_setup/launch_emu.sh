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

    RA_BIN="ra32.trimui"
    if [ "$EMU" = "PS" ] || [ "$EMU" = "SFC" ]; then # Improved SNES/PSX performance
        RA_BIN="ra32.trimui_sdl"
        cp -f retroarch.cfg retroarch_sdl.cfg # config path is hard-coded, unfortunately. attempting to use bind mount causes a segmentation fault when accessing the menu on first run
    fi

    if [ -n "$NET_PARAM" ]; then
        if [ "$(awk -F ':' '/wifi/ {print $2}' "/mnt/UDISK/system.json" | sed 's/^[[:space:]]*//; s/[",]//g')" -eq 0 ]; then
            NET_PARAM=
        else
            case "$CORE" in
                a5200|ardens|atari800|bluemsx|dosbox_pure|easyrpg|ecwolf|fake08|fbalpha2012_cps3|freechaf|freeintv|fuse|gw|hatari|neocd|pcsx_rearmed|pokemini|potator|prboom|prosystem|px68k|tic80|tyrquake|uae4arm|vice_x64|vice_xvic)
                    NET_PARAM= ;;
            esac
        fi
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

run_pico8() {
    cd "$EMU_DIR"

    if [ "$CORE" != "native" ]; then
        run_retroarch
        return
    fi

    if [ ! -f "/mnt/SDCARD/BIOS/Pico-8/pico8.dat" ] || [ ! -f "/mnt/SDCARD/BIOS/Pico-8/pico8_dyn" ]; then
        display -d 1500 -t "PICO-8 binaries not found. Falling back to FAKE-08. Splore will not work."
        CORE="fake08" run_retroarch
        return
    fi

    SPLORE_LAUNCHER="☆ Splore.p8"
    PICO8_LOG="/mnt/SDCARD/System/log/pico8.log"

    export HOME="$EMU_DIR"
    export PATH="$EMU_DIR/bin:/mnt/SDCARD/BIOS/Pico-8:$PATH"
    export LD_LIBRARY_PATH="$EMU_DIR/lib:$LD_LIBRARY_PATH"
    export SDL_VIDEODRIVER=fbcon

    if [ "$(basename "$ROM_FILE")" = "$SPLORE_LAUNCHER" ]; then
        pico8_dyn -splore -root_path "/mnt/SDCARD/Roms/PICO8" > "$PICO8_LOG" 2>&1
    else
        evtest /dev/input/event0 | while read line; do
            case "$line" in # pressing MENU gets you stuck in the console. Let's have it exit PICO-8 instead
                *"EV_KEY"*"KEY_ESC"*"value 1") killall pico8_dyn ;;
            esac
        done &
        EVTEST_PID=$!
        
        pico8_dyn -run "$ROM_FILE" > "$PICO8_LOG" 2>&1
        kill $EVTEST_PID
    fi
}

run_ebook() {
    EMU_DIR="/mnt/SDCARD/Apps/PixelReader"
    export HOME="$EMU_DIR"
    export LD_LIBRARY_PATH="$HOME/lib:$LD_LIBRARY_PATH"

    cd "$HOME"

    ./reader "$ROM_FILE"
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
    "EBOOKS") run_ebook ;;
    "MP3") run_mp3 ;;
    "OPENBOR") run_openbor ;;
    "PORTS") run_port ;;
    "PICO8") run_pico8 ;;
    *) run_retroarch ;;
esac

set_cpuclock --mode smart # reset cpu clock

if [ -f "/tmp/.quicksave" ]; then
    log_message "Displaying quicksave screen from launch_emu!" "/mnt/SDCARD/System/log/quicksave.log"
    display -t "It's now safe to turn off your Smart" > /mnt/SDCARD/display.log 2>&1
fi
