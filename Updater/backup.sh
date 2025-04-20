#!/bin/sh

. /mnt/SDCARD/Updater/updateHelpers.sh

BACKUP_LOCATION="/mnt/SDCARD/Saves/QuarkBackup_$(date +%Y%m%d).zip"
BACKUP_LOG="/mnt/SDCARD/Updater/updater.log"

export PATH="$(dirname "$0")/bin:$PATH"

if [ "$1" = "--restore" ]; then
    display -t "Restoring user data..."

    BACKUP_TO_RESTORE="$(ls -t /mnt/SDCARD/Saves/QuarkBackup_*.zip | head -1)"
    log_message "Updater: restoring backup $BACKUP_TO_RESTORE..."
    if unzip -o -d / "$BACKUP_TO_RESTORE" >> "$BACKUP_LOG" 2>&1; then
        log_message "Updater: successfully restored backup"
        display_msg -d 1500 -t "Successfully restored user data"
    else
        log_message "Updater: failed to restore backup"
        display_msg -d 1500 -t "Failed to restore user data"
    fi
else
    log_message "Updater: backing up files" "$BACKUP_LOG"

    REQUIRED_SPACE=$((50 * 1024 * 1024))  # 50 MB in bytes
    AVAILABLE_SPACE=$(df -k /mnt/SDCARD | awk 'NR==2 {print $4 * 1024}') # amount of free space on SD card in bytes

    if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
        log_message "Updater: insufficient SD card space to back up files" "$BACKUP_LOG"
        display_msg -d 1500 -t "Insufficient space to back up files."
        exit
    fi

    log_message "Creating backup of user data - $BACKUP_LOCATION"
    display_msg -t "Backing up user data..."

    zip -r -@<<EOF "$BACKUP_LOCATION" > "$BACKUP_LOG" 2>&1
/mnt/UDISK/system.json
/mnt/SDCARD/Emus/.emu_setup/overrides/
/mnt/SDCARD/Emus/NDS/backup
/mnt/SDCARD/Emus/NDS/config
/mnt/SDCARD/Emus/NDS/savestates
/mnt/SDCARD/Emus/NDS/resources/settings.json
/mnt/SDCARD/RetroArch/retroarch.cfg
/mnt/SDCARD/RetroArch/.retroarch/config/
/mnt/SDCARD/RetroArch/.retroarch/overlay/
/mnt/SDCARD/System/etc/.post_new_install
/mnt/SDCARD/System/etc/quark.ini
/mnt/SDCARD/System/etc/ssh/
/mnt/SDCARD/System/etc/syncthing/
EOF

    if [ $? -eq 0 ]; then
        log_message "Updater: successfully backed up files" "$BACKUP_LOG"
        display_msg -d 1500 -t "Successfully backed up user data"
    else
        log_message "Updater: failed to back up files" "$BACKUP_LOG"
        display_msg -d 1500 -t "Failed to back up user data"
    fi
fi