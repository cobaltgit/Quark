#!/bin/sh

if [ -f "/mnt/SDCARD/System/bin/helpers.sh" ] && [ ! -d "/mnt/SDCARD/System/scripts" ]; then # Quark v1.0.x Angstrom
    HELPERS_PATH="/mnt/SDCARD/System/bin/helpers.sh"
else # Quark v1.1.0 Baryon and newer
    HELPERS_PATH="/mnt/SDCARD/System/scripts/helpers.sh"
fi

. "$HELPERS_PATH"
. /mnt/SDCARD/Updater/updateHelpers.sh

UPDATER_APP_CONFIG="/mnt/SDCARD/Apps/QuarkUpdater/config.json"
UPDATE_PKG="$(ls -t /mnt/SDCARD/Quark_Update_*.tar.zst | head -1)" # get most recent update file
LOG_FILE="/mnt/SDCARD/Updater/updater.log"
SDCARD_TEST_FILE="/mnt/SDCARD/.test_$$"
SDCARD_UNHEALTHY=false

display_msg -t "Starting updater..."
log_message "Updater: starting update process..." "$LOG_FILE"

if [ $(cat /sys/class/power_supply/lradc_battery/capacity) -lt 20 ]; then
    log_message "Updater: battery is below 20%, exiting" "$LOG_FILE"
    display_msg -d 1500 -t "Battery is too low to update. Please charge to at least 20%"
    exit 1
fi

ro_check

if ! echo "$$" > "$SDCARD_TEST_FILE" 2>/dev/null; then
    log_message "Updater: cannot write to SD card, exiting..." "$LOG_FILE"
    display_msg -d 1500 -t "Cannot write to SD card! Exiting..."
    SDCARD_UNHEALTHY=true
else
    if ! testfile_contents=$(cat "$SDCARD_TEST_FILE" 2>/dev/null) || [ "$testfile_contents" != "$$" ]; then
        log_message "Updater: cannot read from SD card or test data mismatched, exiting..." "$LOG_FILE"
        display_msg -d 1500 -t "Cannot read from SD card! Exiting..."
        SDCARD_UNHEALTHY=true
    fi
    rm -f "$SDCARD_TEST_FILE"
fi

if ! DF=$(df /mnt/SDCARD 2>/dev/null); then
    log_message "Updater: cannot get file system info, exiting..." "$LOG_FILE"
    display_msg -d 1500 -t "Cannot check free space on SD card! Exiting..."
    SDCARD_UNHEALTHY=true
else
    SD_FREE_SPACE="$(echo "$DF" | tail -n1 | awk '{print $4}')"
    if [ $SD_FREE_SPACE -lt 1024 ]; then
        log_message "Updater: insufficient free space on SD card to carry on with the update process..." "$LOG_FILE"
        display_msg -d 1500 -t "Insufficient free space on SD card! Exiting..."
        SDCARD_UNHEALTHY=true
    fi
fi

$SDCARD_UNHEALTHY && exit 1 || log_message "Updater: SD card is healthy, continuing..." "$LOG_FILE"

if [ ! -f "$UPDATE_PKG" ]; then
    log_message "Updater: update package not found" "$LOG_FILE"
    display_msg -d 1500 -t "Update package not found! Exiting..."
    sed -i 's/^{*$/{{/' "$UPDATER_APP_CONFIG" # "self-destruct"
    exit 1
fi

log_message "Checking disk space..." "$LOG_FILE"
UPDATE_SPACE_REQUIRED=$(($(du "$UPDATE_PKG" | awk '{print $1}') * 4))
if [ $SD_FREE_SPACE -lt $UPDATE_SPACE_REQUIRED ]; then
    log_message "Updater: not enough SD card space to extract update package" "$LOG_FILE"
    display_msg -d 1500 -t "Insufficient free space on SD card to install update. Exiting..."
    exit 1
fi

set_cpuclock --mode overclock

echo mmc1 > /sys/devices/platform/sunxi-led/leds/led3/trigger

/mnt/SDCARD/Updater/backup.sh

log_message "Updater: cleaning up SD card..." "$LOG_FILE"
display_msg -t "Cleaning up your SD card..."

cd /mnt/SDCARD

for item in *; do
    if [ "$item" != "Updater" ] && [ "$item" != "$(basename "$UPDATE_PKG")" ] && [ "$item" != "BIOS" ] && \
        [ "$item" != "Roms" ] && [ "$item" != "Saves" ] && [ "$item" != "Themes" ]; then
            log_message "Updater: deleting folder $item" "$LOG_FILE"
            rm -rf "$item"
    fi
done

log_message "Updater: extracting update package $UPDATE_PKG" "$LOG_FILE"

ro_check

display_msg -t "Extracting update package, this should take no more than 2 minutes..."

if ! /mnt/SDCARD/Updater/bin/zstd -d --stdout "$UPDATE_PKG" | tar xv -C /mnt/SDCARD/ >> "$LOG_FILE" 2>&1; then
    log_message "Updater: update package extracted with errors." "$LOG_FILE"
    display_msg -d 1500 -t "Update package extracted with errors. Check the log for details"
else
    log_message "Updater: update package extracted successfully" "$LOG_FILE"
    display_msg -d 1500 -t "Update package extracted successfully!"
fi

sync

log_message "Updater: deleting update package $UPDATE_PKG" "$LOG_FILE"
rm -f "$UPDATE_PKG"

/mnt/SDCARD/Updater/backup.sh --restore

echo none > /sys/devices/platform/sunxi-led/leds/led3/trigger

set_cpuclock --mode smart

display_msg -d 1500 -t "Update finished. Rebooting your device..."

cat /dev/zero > /dev/fb0

reboot