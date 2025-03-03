#!/bin/sh

export EMU="$(echo "$1" | cut -d'/' -f5)"
export GAME="$(basename "$1")"
export EMU_DIR="/mnt/SDCARD/Emus/${EMU}"
export OPT_DIR="/mnt/SDCARD/Emus/.emu_setup/opts"

OVERRIDE_FILE="/mnt/SDCARD/Emu/.emu_setup/overrides/$EMU/$GAME.opt"

[ -f "$OPT_DIR/$EMU.opt" ] && . "$OPT_DIR/$EMU.opt"
[ -f "$OVERRIDE_FILE" ] && . "$OVERRIDE_FILE"

set_cpuclock() {
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    case "$CPU_MODE" in
        "smart")
            echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 35 >/sys/devices/system/cpu/cpufreq/conservative/down_threshold
            echo 70 >/sys/devices/system/cpu/cpufreq/conservative/up_threshold
            echo 3 >/sys/devices/system/cpu/cpufreq/conservative/freq_step
            echo 1 >/sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor
            echo 400000 >/sys/devices/system/cpu/cpufreq/conservative/sampling_rate
            echo "$CPU_MIN_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
            echo 1200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
            ;;
        "performance")
            echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 1440000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
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
    CORE_PATH="$RA_DIR/.retroarch/cores/${CORE}_libretro.so"

    if $PCSX_SMOOTH; then
        RA_BIN="ra32.trimui_sdl"
    else
        RA_BIN="ra32.trimui"
    fi

    cd "$RA_DIR"
    HOME="$RA_DIR/" "$RA_DIR/$RA_BIN" -v -L "$CORE_PATH" "$ROM_FILE"
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