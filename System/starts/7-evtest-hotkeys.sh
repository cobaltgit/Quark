#!/bin/sh
# evtest hotkey listeners

. /mnt/SDCARD/System/scripts/helpers.sh

reboot_hotkey() {
    BOTH_PRESSED_TIME=0
    MAX_PRESS_LENGTH=10
    PROCESSES="MainUI ra32.trimui ra32.trimui_sdl display.elf mp3player.elf OpenBOR.trimui drastic"

    while true; do
        evtest --query /dev/input/event0 EV_KEY 97
        if [ $? = 10 ]; then
            evtest --query /dev/input/event0 EV_KEY 28
            if [ $? = 10 ]; then
                if [ $BOTH_PRESSED_TIME -eq 0 ]; then
                    BOTH_PRESSED_TIME=$(date +%s)
                else
                    CUR_TIME=$(date +%s)
                    ELAPSED=$((CUR_TIME - BOTH_PRESSED_TIME))

                    if [ $ELAPSED -ge $MAX_PRESS_LENGTH ]; then
                        log_message "Key combo held for 5 seconds. Rebooting..." "/mnt/SDCARD/System/log/killswitch.log"
                        for PROC in $PROCESSES; do
                            if [ "$PROC" = "ra32.trimui" ] || [ "$PROC" = "ra32.trimui_sdl" ]; then # will create a savestate when terminated
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
        sleep 0.2
    done
}

screenshot_hotkey() {
    while true; do
        evtest --query /dev/input/event0 EV_KEY 97 # SELECT
        if [ $? = 10 ]; then
            evtest --query /dev/input/event0 EV_KEY 109 # MENU + R
            if [ $? = 10 ]; then
                echo default-on > /sys/devices/platform/sunxi-led/leds/led2/trigger
                fbscreenshot
                echo none > /sys/devices/platform/sunxi-led/leds/led2/trigger
            fi
        fi
        sleep 0.2
    done
}

reboot_hotkey &
screenshot_hotkey &
