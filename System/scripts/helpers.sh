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

    export EVTEST_DEV="/dev/input/event0"
    export EV_KEY_SELECT=97
    export EV_KEY_MENU=1
    export EV_KEY_START=28
else
    QUARK_LD_PATH="/mnt/SDCARD/System/lib64"
    QUARK_BIN_PATH="/mnt/SDCARD/System/bin64"

    export EVTEST_DEV="/dev/input/event3"
    export EV_KEY_SELECT=314
    export EV_KEY_MENU=316
    export EV_KEY_START=315
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

# kill_display: kill any instances of display.elf or sdl2imgshow (dependent on platform), should be used before starting another display.
kill_display() {
    killall -9 display.elf
    killall -9 sdl2imgshow
    killall -9 sdl2imgshow.new
}

# doublepipe_wrap: wrap text for sdl2imgshow
doublepipe_wrap() {
    text="$1"
    n="$2"
    result=""
    current_length=0
    
    OLD_IFS="$IFS"
    IFS=' '
    
    for word in $text; do
        word_len=$(expr length "$word")
        
        if [ $((current_length + word_len)) -gt "$n" ]; then
            result="${result}||"
            current_length=0
        fi
        
        if [ "$current_length" -gt 0 ]; then
            result="${result} "
            current_length=$((current_length + 1))
        fi
        
        result="${result}${word}"
        current_length=$((current_length + word_len))
    done
    
    # Restore IFS
    IFS="$OLD_IFS"
    
    printf '%s\n' "$result"
}

# display: displays text on screen for a (optional) set duration with a (optional) background image
display() {
    DEFAULT_BG="/mnt/SDCARD/System/res/$PLATFORM/quarkbg.png"
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

    DISPLAY_BG="${DISPLAY_BG:-${DEFAULT_BG}}"
    DISPLAY_FONT="${DISPLAY_FONT:-${DEFAULT_FONT}}"
    DISPLAY_DURATION="${DISPLAY_FONT:-0}"

    kill_display

    if [ "$PLATFORM" = "tg2040" ]; then
        DISPLAY_CMD="display.elf -d $DISPLAY_DURATION -b \"$DISPLAY_BG\" -f \"$DISPLAY_FONT\" \"$DISPLAY_TEXT\""
        if [ $DISPLAY_DURATION -eq 0 ]; then
            eval "$DISPLAY_CMD" &
        else
            eval "$DISPLAY_CMD"
        fi
    else
        case "$PLATFORM" in
            "tg3040") FONT_SIZE=40 ;;
            "tg5040") FONT_SIZE=48 ;;
        esac
        DISPLAY_CMD="sdl2imgshow.new -i \"$DISPLAY_BG\" -f \"$DISPLAY_FONT\" -s $FONT_SIZE -c 255,255,255 -a center -t \"$(doublepipe_wrap "$DISPLAY_TEXT" 32)\""
        eval "$DISPLAY_CMD" &
        if [ $DISPLAY_DURATION -gt 0 ]; then
            sleep $(($DISPLAY_DURATION / 1000))
            kill_display
        fi
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
    fbgrab -a "$TMP_SCREENSHOT"
    if [ "$PLATFORM" = "tg2040" ]; then
        magick convert "$TMP_SCREENSHOT" -rotate 90 -alpha set "$TMP_SCREENSHOT"
    fi
    mv "$TMP_SCREENSHOT" "$SCREENSHOT"
}
