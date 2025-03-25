#!/bin/sh

. /mnt/SDCARD/System/bin/networkHelpers.sh

QUARK_CONFIG="/mnt/SDCARD/System/etc/quark.json"
DUFS_ENABLED="$(/mnt/SDCARD/System/bin/jq '.network.dufs' "$QUARK_CONFIG")"
DUFS_CONFIG="/mnt/SDCARD/Apps/WifiFileTransferToggle/config.json"
IP="$(ip addr show wlan0 | awk '/inet/ {print $2}' | cut -f1 -d '/')"

if $DUFS_ENABLED; then
    DUFS_ENABLED=false
    echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$DUFS_CONFIG")" > "$DUFS_CONFIG"
    stop_dufs_process
else
    DUFS_ENABLED=true
    if [ -z "$IP" ]; then
        DESCRIPTION="Not connected"
    else
        DESCRIPTION="IP: $IP:5000"
    fi 
    echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$DUFS_CONFIG")" > "$DUFS_CONFIG"
    start_dufs_process
fi

echo -E "$(/mnt/SDCARD/System/bin/jq ".network.dufs = $DUFS_ENABLED" "$QUARK_CONFIG")" > "$QUARK_CONFIG"