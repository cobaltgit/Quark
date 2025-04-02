#!/bin/sh
# Helper functions for Quark

# set_cpuclock: sets CPU governor and frequency, write locks to prevent interference and keep changes
# Possible modes
# - smart: modified conservative governor that responds better to usage spikes, balancing performance with battery life. Minimum frequency can be specified by the user (--min-freq arg) or defaults to 816mhz
# - performance: constant 1344mhz frequency, best for fast forwarding retro systems without too much heat
# - overclock: constant 1536mhz frequency, best suited for harder to run games (i.e. SNES SuperFX or 3D PSX)
set_cpuclock() {
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    chmod a+w /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    while [ "$#" -gt 0 ]; do
        case $1 in
            "--mode") MODE="$2"; shift ;;
            "--min-freq") MIN_FREQ="$2"; shift ;;
        esac
        shift
    done

    case "$MODE" in
        "smart")
            [ -z "$MIN_FREQ" ] && MIN_FREQ=816000 # default minimum frequency
            echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 50 >/sys/devices/system/cpu/cpufreq/conservative/down_threshold
            echo 75 >/sys/devices/system/cpu/cpufreq/conservative/up_threshold
            echo 3 >/sys/devices/system/cpu/cpufreq/conservative/freq_step
            echo 1 >/sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor
            echo 400000 >/sys/devices/system/cpu/cpufreq/conservative/sampling_rate
            echo "$MIN_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
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

# get_setting: gets a setting from quark.ini.
# Args:
# 1. the section to look underneath
# 2. the key to lookup
get_setting() {
    SECTION="$1"
    KEY="$2"
    sed -n "/\[$SECTION\]/,/\[.*\]/p" "/mnt/SDCARD/System/etc/quark.ini" | awk -v key=$KEY -F "=" '$0 ~ key {print $2}'
}

# update_setting: updates a setting in quark.ini.
# Args:
# 1. the section to look underneath for the key
# 2. the key to be updated
# 3. the new value of the specified key
update_setting() {
    SECTION="$1"
    KEY="$2"
    NEW_VALUE="$3"
    sed -i "/\[$SECTION\]/,/^\[/{s/^\($KEY *=\).*/\1$NEW_VALUE/;}" "/mnt/SDCARD/System/etc/quark.ini"
}

# display: displays text on screen for a (optional) set duration with a (optional) background image
display() {
    DEFAULT_BG="/mnt/SDCARD/System/res/quarkbg.png"
    DEFAULT_FONT="/mnt/SDCARD/System/res/TwCenMT.ttf"

    while [ "$#" -gt 0 ]; do
        case $1 in
            "-b|--bg") DISPLAY_BG="$2"; shift ;;
            "-f|--font") DISPLAY_FONT="$2"; shift ;;
            "-d|--duration") DISPLAY_DURATION=$2; shift ;;
        esac
        shift
    done

    [ -z "$DISPLAY_BG" ] && DISPLAY_BG=$DEFAULT_BG
    [ -z "$DISPLAY_FONT" ] && DISPLAY_FONT=$DEFAULT_FONT

    if pgrep display.elf 2>&1; then # we kill the previous instance of display
        killall -9 display.elf
    fi

    DISPLAY_CLI="-b \"$DISPLAY_BG\" -f \"$DISPLAY_FONT\""
    if [ -n "$DISPLAY_DURATION" ]; then
        DISPLAY_CLI="$DISPLAY_CLI -d $DISPLAY_DURATION"
    fi

    /mnt/SDCARD/System/bin/display.elf "$DISPLAY_CLI" "$@"
}
