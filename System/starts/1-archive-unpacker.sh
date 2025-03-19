#!/bin/sh

ARCHIVES_FOLDER="/mnt/SDCARD/System/archives"
ARCHIVE_UNPACK_LOG="/mnt/SDCARD/System/log/archive_unpack.log"

find "$ARCHIVES_FOLDER" -type f -iname "*.zip" | while read archive; do
    basename="$(basename "$archive")"
    echo "Unpacking archive $basename"
    if ! unzip -o -d / "$archive"; then
        echo "Failed to unpack archive $basename"
    else
        echo "Archive $basename unpacked successfully"
        rm "$archive"
    fi
done > "$ARCHIVE_UNPACK_LOG" 2>&1