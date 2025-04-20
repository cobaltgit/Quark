#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh
. /mnt/SDCARD/System/scripts/networkHelpers.sh

{
    DUFS_APP_CONFIG="/mnt/SDCARD/Apps/WifiFileTransferToggle/config.json"
    SYNCTHING_APP_CONFIG="/mnt/SDCARD/Apps/Syncthing/config.json"
    SSH_APP_CONFIG="/mnt/SDCARD/Apps/SSH/config.json"
    DUFS_ENABLED="$(get_setting "network" "dufs")"
    SYNCTHING_ENABLED="$(get_setting "network" "syncthing")"
    SSH_ENABLED="$(get_setting "network" "ssh")"

    if { ! $DUFS_ENABLED; } && [ "$(/mnt/SDCARD/System/bin/jq -r '.description' "$DUFS_APP_CONFIG")" != "Turned off" ]; then
        echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
    fi

    if { ! $SYNCTHING_ENABLED; } && [ "$(/mnt/SDCARD/System/bin/jq -r '.description' "$SYNCTHING_APP_CONFIG")" != "Turned off" ]; then
        echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$SYNCTHING_APP_CONFIG")" > "$SYNCTHING_APP_CONFIG"
    fi

    if { ! $SSH_ENABLED; } && [ "$(/mnt/SDCARD/System/bin/jq -r '.description' "$SSH_APP_CONFIG")" != "Turned off" ]; then
        echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
    fi

    if ! { $DUFS_ENABLED || $SYNCTHING_ENABLED || $SSH_ENABLED; }; then # exit if wifi is disabled system-wide or all network services are disabled
        exit 0
    fi

    IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

    if [ -z "$IP" ] || ! ping -c 1 -W 3 1.1.1.1; then
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

    while [ "$(awk -F ':' '/wifi/ {print $2}' "/mnt/UDISK/system.json" | sed 's/^[[:space:]]*//; s/[",]//g')" -eq 0 ] || \
        [ -z "$IP" ] || ! ping -c 1 -W 3 1.1.1.1; do # we wait for a network connection
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