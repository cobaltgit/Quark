#!/bin/sh

DUFS_LOGFILE="/mnt/SDCARD/System/log/dufs.log"

start_dufs_process() {
    if ! pgrep dufs; then
        /mnt/SDCARD/System/bin/dufs --allow-upload --allow-delete --allow-search --allow-archive --log-file "$DUFS_LOGFILE" "/mnt/SDCARD" &
    fi
}

stop_dufs_process() {
    if pgrep dufs; then
        killall -9 dufs
    fi
}