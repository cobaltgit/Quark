#!/bin/sh

export EMU="$(echo "$1" | cut -d'/' -f5)"
export GAME="$(basename "$1")"
export EMU_DIR="/mnt/SDCARD/Emus/${EMU}"
export OPT_DIR="/mnt/SDCARD/Emus/.emu_setup/opts"

OVERRIDE_FILE="/mnt/SDCARD/Emus/.emu_setup/overrides/$EMU/$GAME.opt"

[ -f "$OPT_DIR/$EMU.opt" ] && . "$OPT_DIR/$EMU.opt"
[ -f "$OVERRIDE_FILE" ] && . "$OVERRIDE_FILE"

set_cpuclock() {
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    case "$CPU_MODE" in
        "smart")
            echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 45 >/sys/devices/system/cpu/cpufreq/conservative/down_threshold
            echo 80 >/sys/devices/system/cpu/cpufreq/conservative/up_threshold
            echo 3 >/sys/devices/system/cpu/cpufreq/conservative/freq_step
            echo 1 >/sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor
            echo 400000 >/sys/devices/system/cpu/cpufreq/conservative/sampling_rate
            echo "$CPU_MIN_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
            echo 1344000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
            ;;
        "performance")
            echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 1344000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
            ;;
        "overclock")
            echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 1536000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
            ;;
    esac

    chmod a-w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    chmod a-w /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    chmod a-w /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
}

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

set_cpuclock

case "$EMU" in
    "OPENBOR") run_openbor ;;
    "PORTS") run_port ;;
    *) run_retroarch ;;
esac