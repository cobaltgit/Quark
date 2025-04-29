#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

ARCHIVES_FOLDER="/mnt/SDCARD/System/archives"
ARCHIVE_COUNT="$(ls -1 $ARCHIVES_FOLDER/*.zip | wc -l)"
ARCHIVE_UNPACK_LOG="/mnt/SDCARD/System/log/archive_unpack.log"

log_message "Unpacker: $ARCHIVE_COUNT archives found" "$ARCHIVE_UNPACK_LOG"

if [ "$ARCHIVE_COUNT" -eq 0 ]; then
    log_message "Unpacker: no archives to unpack" "$ARCHIVE_UNPACK_LOG"
    exit 0
fi

find "$ARCHIVES_FOLDER" -type f -iname "*.zip" | while read archive; do
    basename="$(basename "$archive")"
    log_message "Unpacker: unpacking archive $basename"
    if ! unzip -o -d / "$archive"; then
        log_message "Unpacker: failed to unpack archive $basename"
    else
        log_message "Unpacker: archive $basename unpacked successfully"
        rm -f "$archive"
    fi
done > "$ARCHIVE_UNPACK_LOG" 2>&1