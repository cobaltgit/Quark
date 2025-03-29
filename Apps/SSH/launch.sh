#!/bin/sh

. /mnt/SDCARD/System/bin/helpers.sh
. /mnt/SDCARD/System/bin/networkHelpers.sh

QUARK_CONFIG="/mnt/SDCARD/System/etc/quark.ini"
SSH_ENABLED="$(get_setting "network" "ssh")"
SSH_APP_CONFIG="/mnt/SDCARD/Apps/SSH/config.json"
IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

if $SSH_ENABLED; then
    SSH_ENABLED=false
    echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
    stop_dropbear_process
else
    SSH_ENABLED=true
    if [ -z "$IP" ]; then
        DESCRIPTION="Not connected"
    else
        DESCRIPTION="IP: $IP:22"
    fi 
    echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
    start_dropbear_process
fi

update_setting "network" "ssh" "$SSH_ENABLED"