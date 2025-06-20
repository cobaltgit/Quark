#!/bin/sh

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
        mount -o remount,rw /dev/mmcblk0p1 /mnt/SDCARD
    fi
}

display_msg() {
    DEFAULT_BG="/mnt/SDCARD/Updater/bin/res/quarkbg.png"
    DEFAULT_FONT="/mnt/SDCARD/Updater/bin/res/TwCenMT.ttf"

    while [ "$#" -gt 0 ]; do
        case $1 in
            "-b"|"--bg") DISPLAY_BG="$2"; shift ;;
            "-f"|"--font") DISPLAY_FONT="$2"; shift ;;
            "-d"|"--duration") DISPLAY_DURATION=$2; shift ;;
            "-t"|"--text") DISPLAY_TEXT=$2; shift ;;
        esac
        shift
    done

    DISPLAY_BG=${DISPLAY_BG:-DEFAULT_BG}
    DISPLAY_FONT=${DISPLAY_FONT:-DEFAULT_FONT}
    DISPLAY_DURATION=${DISPLAY_DURATION:-0}

    killall -9 display.elf

    DISPLAY_CMD="/mnt/SDCARD/Updater/bin/display.elf -d $DISPLAY_DURATION -b \"$DISPLAY_BG\" -f \"$DISPLAY_FONT\" \"$DISPLAY_TEXT\""
    if [ $DISPLAY_DURATION -eq 0 ]; then
        eval "$DISPLAY_CMD" &
    else
        eval "$DISPLAY_CMD"
    fi
}