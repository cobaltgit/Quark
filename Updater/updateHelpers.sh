#!/bin/sh

CPUINFO=$(cat /proc/cpuinfo 2> /dev/null)
case $CPUINFO in
    *"TG5040"*)	export PLATFORM="tg5040"  ;;
    *"TG3040"*)	export PLATFORM="tg3040"  ;;
    *"sun8i"*)  export PLATFORM="tg2040"  ;;
esac

case "$PLATFORM" in
    "tg2040") 
        UPDATER_BIN_PATH="/mnt/SDCARD/Updater/bin"
        SDCARD_DEV="/dev/mmcblk0p1"
        POWER_SUPPLY="/sys/class/power_supply/lrdac_battery"
        ;;
    "tg5040"|"tg3040") 
        UPDATER_BIN_PATH="/mnt/SDCARD/Updater/bin64" 
        SDCARD_DEV="/dev/mmcblk1p1"
        POWER_SUPPLY="/sys/class/power_supply/axp2202-battery"
        ;;
esac

export PATH="$UPDATER_BIN_PATH:$PATH"
export LOG_FILE="/mnt/SDCARD/Updater/updater.log"

log_message() {
    MESSAGE="$1"
    LOGFILE="$2"

    if [ -z "$LOGFILE" ]; then # print to stdout
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MESSAGE"
    else # append to log
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MESSAGE" >> "$LOGFILE"
    fi
}

ro_check() {
    if [ $(mount | grep SDCARD | cut -d"(" -f 2 | cut -d"," -f1 ) = "ro" ]; then
        log_message "Updater: SD card read only, attempting remount as rw" "$LOG_FILE"
        mount -o remount,rw $SDCARD_DEV /mnt/SDCARD
    fi
}

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

display() {
    DEFAULT_BG="/mnt/SDCARD/Updater/res/quarkbg_$PLATFORM.png"
    DEFAULT_FONT="/mnt/SDCARD/Updater/res/TwCenMT.ttf"

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

    killall -9 display.elf
    killall -9 sdl2imgshow

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
        DISPLAY_CMD="sdl2imgshow -i \"$DISPLAY_BG\" -f \"$DISPLAY_FONT\" -s $FONT_SIZE -c 255,255,255 -a center -t \"$(doublepipe_wrap "$DISPLAY_TEXT" 32)\""
        eval "$DISPLAY_CMD" &
        if [ $DISPLAY_DURATION -gt 0 ]; then
            sleep $(($DISPLAY_DURATION / 1000))
            killall -9 sdl2imgshow
        fi
    fi
}