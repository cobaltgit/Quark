#!/bin/sh
# Helper functions for Quark

CPUINFO=$(cat /proc/cpuinfo 2> /dev/null)
case $CPUINFO in
    *"TG5040"*)	export PLATFORM="tg5040"  ;;
    *"TG3040"*)	export PLATFORM="tg3040"  ;;
    *"sun8i"*)  export PLATFORM="tg2040"  ;;
esac

if [ "$PLATFORM" = "tg2040" ]; then
    QUARK_LD_PATH="/mnt/SDCARD/System/lib"
    QUARK_BIN_PATH="/mnt/SDCARD/System/bin"
else
    QUARK_LD_PATH="/mnt/SDCARD/System/lib64"
    QUARK_BIN_PATH="/mnt/SDCARD/System/bin64"
fi

export LD_LIBRARY_PATH="$QUARK_LD_PATH:$LD_LIBRARY_PATH"
export PATH="$QUARK_BIN_PATH:$PATH"

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
            case "$PLATFORM" in
                "tg2040") MAX_FREQ=1344000 ;;
                "tg3040"|"tg5040") MAX_FREQ=1800000 ;;
            esac
            echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo 50 >/sys/devices/system/cpu/cpufreq/conservative/down_threshold
            echo 75 >/sys/devices/system/cpu/cpufreq/conservative/up_threshold
            echo 3 >/sys/devices/system/cpu/cpufreq/conservative/freq_step
            echo 1 >/sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor
            echo 400000 >/sys/devices/system/cpu/cpufreq/conservative/sampling_rate
            echo "$MIN_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
            echo $MAX_FREQ > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
            ;;
        "performance")
            case "$PLATFORM" in
                "tg2040") MAX_FREQ=1344000 ;;
                "tg3040"|"tg5040") MAX_FREQ=1800000 ;;
            esac
            echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo $MAX_FREQ > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
            ;;
        "overclock")
            case "$PLATFORM" in
                "tg2040") MAX_FREQ=1536000 ;;
                "tg3040"|"tg5040") MAX_FREQ=2000000 ;;
            esac
            echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            echo $MAX_FREQ > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
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

# kill_display: kill any instances of display.elf, should be used before starting another display.
kill_display() {
    killall -9 display.elf
}

# display: displays text on screen for a (optional) set duration with a (optional) background image
display() {
    DEFAULT_BG="/mnt/SDCARD/System/res/quarkbg.png"
    DEFAULT_FONT="/mnt/SDCARD/System/res/TwCenMT.ttf"

    while [ "$#" -gt 0 ]; do
        case $1 in
            "-b"|"--bg") DISPLAY_BG="$2"; shift ;;
            "-f"|"--font") DISPLAY_FONT="$2"; shift ;;
            "-d"|"--duration") DISPLAY_DURATION=$2; shift ;;
            "-t"|"--text") DISPLAY_TEXT=$2; shift ;;
        esac
        shift
    done

    [ -z "$DISPLAY_BG" ] && DISPLAY_BG=$DEFAULT_BG
    [ -z "$DISPLAY_FONT" ] && DISPLAY_FONT=$DEFAULT_FONT
    [ -z "$DISPLAY_DURATION" ] && DISPLAY_DURATION=0

    kill_display

    DISPLAY_CMD="display.elf -d $DISPLAY_DURATION -b \"$DISPLAY_BG\" -f \"$DISPLAY_FONT\" \"$DISPLAY_TEXT\""
    if [ $DISPLAY_DURATION -eq 0 ]; then
        eval "$DISPLAY_CMD" &
    else
        eval "$DISPLAY_CMD"
    fi
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

# Take a screenshot of framebuffer and rotate to the correct orientation
fbscreenshot() {
    TMP_SCREENSHOT="/tmp/$$.png"
    SCREENSHOT="$1"
    [ -z "$SCREENSHOT" ] && SCREENSHOT="/mnt/SDCARD/Saves/screenshots/$(date +"Screenshot_%Y%m%d_%H%M%S.png")"
    fbgrab -a "$TMP_SCREENSHOT" && magick convert "$TMP_SCREENSHOT" -rotate 90 -alpha set "$SCREENSHOT" && rm -f "$TMP_SCREENSHOT"
}
