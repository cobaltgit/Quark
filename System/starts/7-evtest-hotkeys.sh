#!/bin/sh
# evtest hotkey listeners

. /mnt/SDCARD/System/scripts/helpers.sh

reboot_hotkey() {
    BOTH_PRESSED_TIME=0
    MAX_PRESS_LENGTH=10
    KEY_97_PRESSED=0
    KEY_28_PRESSED=0

    # Create state file and initialize
    STATE_FILE="/tmp/key_state_$$"
    echo "0 0 0" > "$STATE_FILE"  # KEY_97_PRESSED KEY_28_PRESSED BOTH_PRESSED_TIME

    # Background evtest loop to update state file
    evtest /dev/input/event0 | while read -r line; do
        log_message "EVTEST: $line" "/mnt/SDCARD/System/log/killswitch.log"
        
        read KEY_97_PRESSED KEY_28_PRESSED BOTH_PRESSED_TIME < "$STATE_FILE"
        
        case "$line" in
            *"code 97"*"value 1"*)
                echo "1 $KEY_28_PRESSED $BOTH_PRESSED_TIME" > "$STATE_FILE"
                ;;
            *"code 97"*"value 0"*)
                echo "0 $KEY_28_PRESSED 0" > "$STATE_FILE"
                ;;
            *"code 28"*"value 1"*)
                echo "$KEY_97_PRESSED 1 $BOTH_PRESSED_TIME" > "$STATE_FILE"
                ;;
            *"code 28"*"value 0"*)
                echo "$KEY_97_PRESSED 0 0" > "$STATE_FILE"
                ;;
        esac
    done &
    EVTEST_PID=$!

    while kill -0 $EVTEST_PID; do  
        read KEY_97_PRESSED KEY_28_PRESSED BOTH_PRESSED_TIME < "$STATE_FILE"
        if [ $KEY_97_PRESSED -eq 1 ] && [ $KEY_28_PRESSED -eq 1 ]; then
            if [ $BOTH_PRESSED_TIME -eq 0 ]; then
                BOTH_PRESSED_TIME=$(date +%s)
                echo "$KEY_97_PRESSED $KEY_28_PRESSED $BOTH_PRESSED_TIME" > "$STATE_FILE"
            else
                CUR_TIME=$(date +%s)
                ELAPSED=$((CUR_TIME - BOTH_PRESSED_TIME))
                
                if [ $ELAPSED -ge $MAX_PRESS_LENGTH ]; then
                    kill $EVTEST_PID 2>/dev/null
                    kill_cmd_to_run
                    sleep 0.5
                    cat /dev/zero > /dev/fb0
                    sync
                    reboot
                    exit 0
                fi
            fi
        fi
        sleep 1
    done
}

screenshot_hotkey() {
    SELECT_PRESSED=false
    MENU_R_PRESSED=false

    evtest /dev/input/event0 | while read line; do
        case "$line" in
            *"EV_KEY"*"KEY_RIGHTCTRL"*"value 1") SELECT_PRESSED=true ;;
            *"EV_KEY"*"KEY_RIGHTCTRL"*"value 0") SELECT_PRESSED=false ;;
            *"EV_KEY"*"KEY_PAGEDOWN"*"value 1") MENU_R_PRESSED=true ;;
            *"EV_KEY"*"KEY_PAGEDOWN"*"value 0") MENU_R_PRESSED=false ;;
        esac

        if $SELECT_PRESSED && $MENU_R_PRESSED; then
            echo default-on > /sys/devices/platform/sunxi-led/leds/led2/trigger
            fbscreenshot "/mnt/SDCARD/Saves/screenshots/$(date +"Screenshot_%Y%m%d_%H%M%S.png")"
            echo none > /sys/devices/platform/sunxi-led/leds/led2/trigger
        fi
    done
}

quicksave_hotkey() {
    SELECT_PRESSED=false
    MENU_L_PRESSED=false

    evtest /dev/input/event0 | while read line; do
        case "$line" in
            *"EV_KEY"*"KEY_RIGHTCTRL"*"value 1") SELECT_PRESSED=true ;;
            *"EV_KEY"*"KEY_RIGHTCTRL"*"value 0") SELECT_PRESSED=false ;;
            *"EV_KEY"*"KEY_PAGEUP"*"value 1") MENU_L_PRESSED=true ;;
            *"EV_KEY"*"KEY_PAGEUP"*"value 0") MENU_L_PRESSED=false ;;
        esac

        if $SELECT_PRESSED && $MENU_L_PRESSED; then
            /mnt/SDCARD/System/scripts/quicksave.sh
        fi
    done
}

reboot_hotkey &
screenshot_hotkey &
quicksave_hotkey &
