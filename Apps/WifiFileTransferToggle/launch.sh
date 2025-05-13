#!/bin/sh

set -x

. /mnt/SDCARD/System/scripts/helpers.sh
. /mnt/SDCARD/System/scripts/networkHelpers.sh

QUARK_CONFIG="/mnt/SDCARD/System/etc/quark.ini"
DUFS_ENABLED="$(get_setting "network" "dufs")"
DUFS_APP_CONFIG="/mnt/SDCARD/Apps/WifiFileTransferToggle/config.json"
IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

if $DUFS_ENABLED; then
    display -d 1000 -t "Disabling dufs..."
    DUFS_ENABLED=false
    echo -E "$(jq '.description = "Turned off"' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
    stop_dufs_process
else
    display -d 1000 -t "Enabling dufs..."
    DUFS_ENABLED=true
    if [ -z "$IP" ]; then
        DESCRIPTION="Not connected"
    else
        DESCRIPTION="IP: $IP:5000"
    fi 
    echo -E "$(jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
    start_dufs_process
fi

update_setting "network" "dufs" "$DUFS_ENABLED"

kill_display