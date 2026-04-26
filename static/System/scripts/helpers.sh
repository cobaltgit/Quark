#!/bin/sh
# Helper functions for Quark

export LD_LIBRARY_PATH="/lib:/usr/lib:/usr/trimui/lib:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"
export PATH="/mnt/SDCARD/System/bin:$PATH"
export THEME_PATH="$(awk -F'"' '/"theme":/ {print $4}' "/mnt/UDISK/system.json" | sed 's:/*$:/:')"

# set_cpuclock: sets CPU governor and frequency, write locks to prevent interference and keep changes
# Possible modes
# - smart: modified conservative governor that responds better to usage spikes, balancing performance with battery life. Min/max frequencies can be specified by the user, defaults to 816-1344MHz
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
            "--max-freq") MAX_FREQ="$2"; shift ;;
        esac
        shift
    done

    case "$MODE" in
        "smart")
            echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 50 >/sys/devices/system/cpu/cpufreq/conservative/down_threshold
            echo 75 >/sys/devices/system/cpu/cpufreq/conservative/up_threshold
            echo 3 >/sys/devices/system/cpu/cpufreq/conservative/freq_step
            echo 1 >/sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor
            echo 400000 >/sys/devices/system/cpu/cpufreq/conservative/sampling_rate
            echo "${MIN_FREQ:-816000}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
            echo "${MAX_FREQ:-1344000}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
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

# kill_cmd_to_run: kill all child processes of /tmp/cmd_to_run.sh
kill_cmd_to_run() {
    local cmd_to_run_pid=$(ps | awk '/\/tmp\/cmd_to_run.sh/ {print $1}')
    if [ -z $cmd_to_run_pid ]; then return; fi

    local pids="$cmd_to_run_pid"

    # aggregate all PIDs before killing
    get_all_children() {
        local p=$1
        local children=$(grep -l "^PPid:\s*$p$" /proc/*/status 2>/dev/null | cut -d/ -f3)
        for child in $children; do
            pids="$pids $child"
            get_all_children $child
        done
    }

    get_all_children $cmd_to_run_pid
    kill $pids
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
# 1. the section to look underneath for the key. Will be created if non-existent
# 2. the key to be updated. Will be created if non-existent.
# 3. the new value of the specified key
update_setting() {
    SECTION="$1"
    KEY="$2"
    NEW_VALUE="$3"
    INI_FILE="/mnt/SDCARD/System/etc/quark.ini"

    if ! grep -q "^\[$SECTION\]" "$INI_FILE"; then # create section if non-existent
        echo "" >> "$INI_FILE"
        echo "[$SECTION]" >> "$INI_FILE"
    fi

    if grep -q "^\[$SECTION\]" "$INI_FILE" && ! sed -n "/\[$SECTION\]/,/^\[/p" "$INI_FILE" | grep -q "^$KEY *="; then
        sed -i "/\[$SECTION\]/a\\$KEY=$NEW_VALUE" "$INI_FILE"
    else
        sed -i "/\[$SECTION\]/,/^\[/{s/^\($KEY *=\).*/\1$NEW_VALUE/;}" "$INI_FILE"
    fi
}

kill_display() {
    killall -9 display
}

# log_message: logs a message to a file
log_message() {
    MESSAGE="$1"
    LOGFILE="$2"

    if [ -z "$LOGFILE" ]; then # print to stdout
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MESSAGE"
    else # append to log
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MESSAGE" >> "$LOGFILE"
    fi
}
