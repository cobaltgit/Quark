#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh
. /mnt/SDCARD/System/scripts/networkHelpers.sh

QUARK_CONFIG="/mnt/SDCARD/System/etc/quark.ini"
SSH_ENABLED="$(get_setting "network" "ssh")"
SSH_APP_CONFIG="/mnt/SDCARD/Apps/SSH/config.json"
IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

if $SSH_ENABLED; then
    display -d 1000 -t "Disabling SSH..."
    SSH_ENABLED=false
    echo -E "$(jq '.description = "Turned off"' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
    stop_dropbear_process
else
    display -d 1000 -t "Enabling SSH..."
    SSH_ENABLED=true
    if [ -z "$IP" ]; then
        DESCRIPTION="Not connected"
    else
        DESCRIPTION="IP: $IP:22"
    fi 
    echo -E "$(jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SSH_APP_CONFIG")" > "$SSH_APP_CONFIG"
    start_dropbear_process
fi

update_setting "network" "ssh" "$SSH_ENABLED"

kill_display