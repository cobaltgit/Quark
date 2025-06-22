#!/bin/sh
# evtest hotkey listeners

. /mnt/SDCARD/System/scripts/helpers.sh

hotkey_listener() {
    BOTH_PRESSED_TIME=0
    MAX_PRESS_LENGTH=10

    SELECT_PRESSED=0
    START_PRESSED=0
    MENU_R_PRESSED=0

    PROCESSES="MainUI ra32.trimui ra32.trimui_sdl display.elf mp3player.elf OpenBOR.trimui drastic"

    evtest /dev/input/event0 | while read line; do
        case "$line" in
            *"EV_KEY"*"KEY_RIGHTCTRL"*"value 1")  # Key 97 pressed
                SELECT_PRESSED=1
                ;;
            *"EV_KEY"*"KEY_RIGHTCTRL"*"value 0")  # Key 97 released
                SELECT_PRESSED=0
                BOTH_PRESSED_TIME=0
                ;;
            *"EV_KEY"*"KEY_ENTER"*"value 1")      # Key 28 pressed
                START_PRESSED=1
                ;;
            *"EV_KEY"*"KEY_ENTER"*"value 0")      # Key 28 released
                START_PRESSED=0
                BOTH_PRESSED_TIME=0
                ;;
            *"EV_KEY"*"KEY_PAGEDOWN"*"value 1")   # Key 109 pressed
                MENU_R_PRESSED=1
                ;;
            *"EV_KEY"*"KEY_PAGEDOWN"*"value 0")   # Key 109 released
                MENU_R_PRESSED=0
                log_message "MENU+R released" "/mnt/SDCARD/hotkey.log"
                ;;
        esac

        # Check for reboot combo (SELECT + START)
        if [ "$SELECT_PRESSED" = "1" ] && [ "$START_PRESSED" = "1" ]; then
            if [ $BOTH_PRESSED_TIME -eq 0 ]; then
                BOTH_PRESSED_TIME=$(date +%s)
            else
                CUR_TIME=$(date +%s)
                ELAPSED=$((CUR_TIME - BOTH_PRESSED_TIME))
                
                if [ $ELAPSED -ge $MAX_PRESS_LENGTH ]; then
                    log_message "Key combo held for ${MAX_PRESS_LENGTH} seconds. Rebooting..." "/mnt/SDCARD/System/log/killswitch.log"
                    for PROC in $PROCESSES; do
                        if [ "$PROC" = "ra32.trimui" ] || [ "$PROC" = "ra32.trimui_sdl" ]; then
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
        fi

        # Check for screenshot combo (SELECT + MENU + R)
        if [ "$SELECT_PRESSED" = "1" ] && [ "$MENU_R_PRESSED" = "1" ]; then
            echo default-on > /sys/devices/platform/sunxi-led/leds/led2/trigger
            fbscreenshot
            echo none > /sys/devices/platform/sunxi-led/leds/led2/trigger
        fi
    done
}

hotkey_listener &