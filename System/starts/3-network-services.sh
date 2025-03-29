#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh
. /mnt/SDCARD/System/scripts/networkHelpers.sh

{
    if [ "$(/mnt/SDCARD/System/bin/jq '.wifi' "/mnt/UDISK/system.json")" -eq 0 ]; then # exit if wifi is disabled system-wide
        exit 0
    fi

    IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"
    DUFS_APP_CONFIG="/mnt/SDCARD/Apps/Dufs/config.json"
    SYNCTHING_APP_CONFIG="/mnt/SDCARD/Apps/Syncthing/config.json"
    SSH_APP_CONFIG="/mnt/SDCARD/Apps/SSH/config.json"
    DUFS_ENABLED="$(get_setting "network" "dufs")"
    SYNCTHING_ENABLED="$(get_setting "network" "syncthing")"
    SSH_ENABLED="$(get_setting "network" "ssh")"

    if [ -z "$IP" ]; then
        if $DUFS_ENABLED; then
            echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Not connected"' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
        fi

        if $SYNCTHING_ENABLED; then
            echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Not connected"' "$SYNCTHING_APP_CONFIG")" > "$SYNCTHING_APP_CONFIG"
        fi

        if $SSH_ENABLED; then
            echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Not connected"' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
        fi
    fi

    while ! ( [ -n "$IP" ] && ping -c 1 -W 3 1.1.1.1 ); do # we wait for a network connection
        sleep 1
        IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"
    done

    if $DUFS_ENABLED; then
        DESCRIPTION="IP: $IP:5000"
        echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
        start_dufs_process
    fi

    if $SYNCTHING_ENABLED; then
        DESCRIPTION="IP: $IP:8384"
        echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SYNCTHING_APP_CONFIG")" > "$SYNCTHING_APP_CONFIG"
        start_syncthing_process
    fi

    if $SSH_ENABLED; then
        DESCRIPTION="IP: $IP:22"
        echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
        start_dropbear_process
    fi
} &