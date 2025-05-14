#!/bin/sh
# evtest hotkey listeners

. /mnt/SDCARD/System/scripts/helpers.sh

case "$PLATFORM" in
    "tg2040")
        EVTEST_DEV="/dev/input/event0"
        EV_KEY_SELECT=97
        EV_KEY_MENU=1
        EV_KEY_START=28
        ;;
    "tg3040"|"tg5040")
        EVTEST_DEV="/dev/input/event3"
        EV_KEY_SELECT=314
        EV_KEY_MENU=316
        EV_KEY_START=315
        ;;
esac

reboot_hotkey() {
    BOTH_PRESSED_TIME=0
    MAX_PRESS_LENGTH=10
    PROCESSES="MainUI ra32.trimui ra32.trimui_sdl display.elf mp3player.elf OpenBOR.trimui drastic"

    while true; do
        evtest --query $EVTEST_DEV EV_KEY $EV_KEY_SELECT
        if [ $? = 10 ]; then
            evtest --query $EVTEST_DEV EV_KEY $EV_KEY_START
            if [ $? = 10 ]; then
                if [ $BOTH_PRESSED_TIME -eq 0 ]; then
                    BOTH_PRESSED_TIME=$(date +%s)
                else
                    CUR_TIME=$(date +%s)
                    ELAPSED=$((CUR_TIME - BOTH_PRESSED_TIME))

                    if [ $ELAPSED -ge $MAX_PRESS_LENGTH ]; then
                        log_message "Key combo held for 5 seconds. Rebooting..." "/mnt/SDCARD/System/log/killswitch.log"
                        for PROC in $PROCESSES; do
                            if [ "$PROC" = "ra32.trimui" ] || [ "$PROC" = "ra32.trimui_sdl" ] || [ "$PROC" = "ra64.trimui" ]; then # will create a savestate when terminated
                                killall "$PROC"
                            else
                                killall -9 "$PROC"
                            fi
                        done
                        sleep 0.5
                        cat /dev/zero > /dev/fb0
                        sync
                        reboot
                        exit 0
                    fi
                fi
            else
                BOTH_PRESSED_TIME=0
            fi
        else
            BOTH_PRESSED_TIME=0
        fi
        sleep 0.15
    done
}

screenshot_hotkey() {
    while true; do
        if [ "$PLATFORM" = "tg2040" ]; then
            evtest --query $EVTEST_DEV EV_KEY $EV_KEY_SELECT # SELECT
            if [ $? = 10 ]; then
                if [ "$PLATFORM" = "tg2040" ]; then
                    evtest --query $EVTEST_DEV EV_KEY 109 # MENU + R
                    if [ $? = 10 ]; then
                        echo default-on > /sys/devices/platform/sunxi-led/leds/led2/trigger
                        fbscreenshot
                        echo none > /sys/devices/platform/sunxi-led/leds/led2/trigger
                    fi
                fi
            fi
        else
            # L2 and R2 on tg5040 and tg3040 are wired as analog triggers (EV_ABS)
            # but act as digital inputs, only having values of 0 (not pressed) and 255 (pressed)
            evtest $EVTEST_DEV | while read line; do
                if echo "$line" | grep -q "type 3.*code 5.*value 255"; then
                    evtest --query $EVTEST_DEV EV_KEY $EV_KEY_SELECT # SELECT
                    if [ $? = 10 ]; then
                        fbscreenshot
                        killall -9 evtest
                    fi
                fi
            done
        fi
        sleep 0.15
    done
}

{
    sleep 3 # wait for input devices to be initialised
    reboot_hotkey &
    screenshot_hotkey &
} &