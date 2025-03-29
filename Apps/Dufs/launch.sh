#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh
. /mnt/SDCARD/System/scripts/networkHelpers.sh

QUARK_CONFIG="/mnt/SDCARD/System/etc/quark.ini"
DUFS_ENABLED="$(get_setting "network" "dufs")"
DUFS_APP_CONFIG="/mnt/SDCARD/Apps/Dufs/config.json"
IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

if $DUFS_ENABLED; then
    DUFS_ENABLED=false
    echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
    stop_dufs_process
else
    DUFS_ENABLED=true
    if [ -z "$IP" ]; then
        DESCRIPTION="Not connected"
    else
        DESCRIPTION="IP: $IP:5000"
    fi 
    echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
    start_dufs_process
fi

update_setting "network" "dufs" "$DUFS_ENABLED"