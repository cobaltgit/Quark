#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh
. /mnt/SDCARD/System/scripts/networkHelpers.sh

QUARK_CONFIG="/mnt/SDCARD/System/etc/quark.ini"
SYNCTHING_ENABLED="$(get_setting "network" "syncthing")"
SYNCTHING_APP_CONFIG="/mnt/SDCARD/Apps/Syncthing/config.json"
IP="$(ip addr show wlan0 | awk '/inet[^6]/ {split($2, a, "/"); print a[1]}')"

if $SYNCTHING_ENABLED; then
    display -d 1000 -t "Disabling Syncthing..."
    SYNCTHING_ENABLED=false
    echo -E "$(/mnt/SDCARD/System/bin/jq '.description = "Turned off"' "$SYNCTHING_APP_CONFIG")" > "$SYNCTHING_APP_CONFIG"
    stop_syncthing_process
else
    display -d 1000 -t "Enabling Syncthing..."
    SYNCTHING_ENABLED=true
    if [ -z "$IP" ]; then
        DESCRIPTION="Not connected"
    else
        DESCRIPTION="IP: $IP:8384"
    fi 
    echo -E "$(/mnt/SDCARD/System/bin/jq --arg DESCRIPTION "$DESCRIPTION" '.description = $DESCRIPTION' "$SYNCTHING_APP_CONFIG")" > "$SYNCTHING_APP_CONFIG"
    start_syncthing_process
fi

update_setting "network" "syncthing" "$SYNCTHING_ENABLED"

kill_display