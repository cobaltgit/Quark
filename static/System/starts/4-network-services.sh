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

    for SERVICE in DUFS SYNCTHING SSH; do
        eval "SERVICE_ENABLED=\$${SERVICE}_ENABLED"
        eval "SERVICE_CONFIG=\$${SERVICE}_APP_CONFIG"

        if [ "$SERVICE_ENABLED" != "true" ] && ! jq -e '.description == "Turned off"' "$SERVICE_CONFIG"; then
            echo -E "$(jq '.description = "Turned off"' "$SERVICE_CONFIG")" > "$SERVICE_CONFIG"
        fi
    done

    if ! { $DUFS_ENABLED || $SYNCTHING_ENABLED || $SSH_ENABLED; }; then # exit if wifi is disabled system-wide or all network services are disabled
        exit 0
    fi

    IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

    if [ -z "$IP" ] || ! ping -c 1 -W 3 1.1.1.1; then
        for SERVICE in DUFS SYNCTHING SSH; do
            eval "SERVICE_ENABLED=\$${SERVICE}_ENABLED"
            eval "SERVICE_CONFIG=\$${SERVICE}_APP_CONFIG"
            [ "$SERVICE_ENABLED" = "true" ] && \
                echo -E "$(jq '.description = "Not connected"' "$SERVICE_CONFIG")" > "$SERVICE_CONFIG"
        done
    fi

    while [ "$(awk -F ':' '/wifi/ {print $2}' "/mnt/UDISK/system.json" | sed 's/^[[:space:]]*//; s/[",]//g')" -eq 0 ] || \
        [ -z "$IP" ] || ! ping -c 1 -W 3 1.1.1.1; do # we wait for a network connection
        sleep 1
        IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"
    done

    if $DUFS_ENABLED; then
        DESCRIPTION="IP: $IP:5000"
        echo -E "$(jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$DUFS_APP_CONFIG")" > "$DUFS_APP_CONFIG"
        start_dufs_process
    fi

    if $SYNCTHING_ENABLED; then
        DESCRIPTION="IP: $IP:8384"
        echo -E "$(jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SYNCTHING_APP_CONFIG")" > "$SYNCTHING_APP_CONFIG"
        start_syncthing_process
    fi

    if $SSH_ENABLED; then
        DESCRIPTION="IP: $IP:22"
        echo -E "$(jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
        start_dropbear_process
    fi
} &
