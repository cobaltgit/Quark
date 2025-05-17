#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

ARCHIVES_FOLDER="/mnt/SDCARD/System/archives"
ARCHIVE_COUNT="$(ls -1 $ARCHIVES_FOLDER/*.zip $ARCHIVES_FOLDER/*.tar.zst $ARCHIVES_FOLDER/*.tar.gz | wc -l)"
ARCHIVE_UNPACK_LOG="/mnt/SDCARD/System/log/archive_unpack.log"

log_message "Unpacker: $ARCHIVE_COUNT archives found" "$ARCHIVE_UNPACK_LOG"

if [ "$ARCHIVE_COUNT" -eq 0 ]; then
    log_message "Unpacker: no archives to unpack" "$ARCHIVE_UNPACK_LOG"
    exit 0
fi

find "$ARCHIVES_FOLDER" -type f -iname "*.zip" -o -iname "*.tar.zst" | while read archive; do
    basename="$(basename "$archive")"
    log_message "Unpacker: unpacking archive $basename"

    LD_LIBRARY_PATH="/usr/trimui/lib" display -t "Unpacking archive $basename..."

    case "$archive" in
        *.zip) DECOMPRESS_COMMAND="unzip -o -d / \"$archive\"" ;;
        *.tar.gz) DECOMPRESS_COMMAND="tar xzvf \"$archive\" -C /" ;;
        *.tar.zst) DECOMPRESS_COMMAND="zstd -d --stdout \"$archive\" | tar xv -C /" ;;
    esac

    echo "Decompress command: $DECOMPRESS_COMMAND"

    if ! eval "$DECOMPRESS_COMMAND"; then
        log_message "Unpacker: failed to unpack archive $basename"
    else
        log_message "Unpacker: archive $basename unpacked successfully"
        rm -f "$archive"
    fi

    kill_display
done > "$ARCHIVE_UNPACK_LOG" 2>&1