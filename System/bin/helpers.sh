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
            echo 80 >/sys/devices/system/cpu/cpufreq/conservative/up_threshold
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