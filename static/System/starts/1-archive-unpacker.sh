#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

ARCHIVES_FOLDER="/mnt/SDCARD/System/archives"
ARCHIVE_UNPACK_LOG="/mnt/SDCARD/System/log/archive_unpack.log"

find "$ARCHIVES_FOLDER" -type f -iname "*.zip" | while read -r archive; do
    basename="$(basename "$archive")"
    log_message "Unpacker: unpacking archive $basename"
    display -t "Unpacking $basename"
    if ! unzip -o -d / "$archive"; then
        log_message "Unpacker: failed to unpack archive $basename"
        display -d 1000 -t "Failed to unpack $basename"
    else
        log_message "Unpacker: archive $basename unpacked successfully"
        rm -f "$archive"
    fi
done > "$ARCHIVE_UNPACK_LOG" 2>&1

display -d 1000 -t "Archive unpacking complete"
