#!/bin/sh

. /mnt/SDCARD/System/bin/networkHelpers.sh

{
    if [ "$(/mnt/SDCARD/System/bin/jq '.wifi' "/mnt/UDISK/system.json")" -eq 0 ]; then # exit if wifi is disabled system-wide
        exit 0
    fi

    IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"
    DUFS_CONFIG="/mnt/SDCARD/Apps/WifiFileTransferToggle/config.json"
    DUFS_ENABLED="$(/mnt/SDCARD/System/bin/jq '.network.dufs' "/mnt/SDCARD/System/etc/quark.json")"

    if [ -z "$IP" ]; then
        if $DUFS_ENABLED; then
            echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Not connected"' "$DUFS_CONFIG")" > "$DUFS_CONFIG"
        fi
    fi

    while ! ( [ -n "$IP" ] && ping -c 1 -W 3 1.1.1.1 ); do # we wait for a network connection
        sleep 1
        IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"
    done

    if $DUFS_ENABLED; then
        DESCRIPTION="IP: $IP:5000"
        echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$DUFS_CONFIG")" > "$DUFS_CONFIG"
        start_dufs_process
    fi
} &