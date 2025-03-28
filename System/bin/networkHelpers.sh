#!/bin/sh

LOG_DIR="/mnt/SDCARD/System/log"
SYNCTHING_LOG_DIR="$LOG_DIR/syncthing"
SYNCTHING_CONF_DIR="/mnt/SDCARD/System/etc/syncthing"

setup_syncthing() {
    [ ! -d "$SYNCTHING_LOG_DIR" ] && mkdir -p "$SYNCTHING_LOG_DIR"
    if ! [ -f "$SYNCTHING_CONF_DIR/config.xml" ]; then
        ifconfig lo down
        sleep 2
        ifconfig lo up
        sleep 2
        /mnt/SDCARD/System/bin/syncthing generate --no-default-folder --home="$SYNCTHING_CONF_DIR" > "$SYNCTHING_LOG_DIR/generate.log" 2>&1 &
        sleep 2


        if grep -q "<listenAddress>dynamic+https://relays.syncthing.net/endpoint</listenAddress>" "$SYNCTHING_CONF_DIR/config.xml"; then
            echo "Repairing syncthing config manually..."
            sed -i '/<listenAddress>dynamic+https:\/\/relays.syncthing.net\/endpoint<\/listenAddress>/d' "$SYNCTHING_CONF_DIR/config.xml"
            sed -i '/<listenAddress>quic:\/\/0.0.0.0:41383<\/listenAddress>/d' "$SYNCTHING_CONF_DIR/config.xml"
            sed -i 's|<listenAddress>tcp://0.0.0.0:41383</listenAddress>|<listenAddress>default</listenAddress>|' "$SYNCTHING_CONF_DIR/config.xml"

            if grep -q "<address>0.0.0.0:8384</address>" "$SYNCTHING_CONF_DIR/config.xml" && grep -q "<listenAddress>default</listenAddress>" "$SYNCTHING_CONF_DIR/config.xml"; then
                echo "Repair complete. GUI IP forced to 0.0.0.0"
            else
                echo "Failed to repair config. Remove directory '$SYNCTHING_CONF_DIR' and try again."
            fi
        fi

        pkill syncthing
    fi
    sync
    if [ $(grep -c "<address>0.0.0.0:8384</address>") -eq 0 ]; then
        sed -i "s|<address>127.0.0.1:8384</address>|<address>0.0.0.0:8384</address>|g" $SYNCTHING_DIR/config/config.xml
    fi
}

start_syncthing_process() {
    setup_syncthing
    if ! pgrep syncthing >/dev/null 2>&1; then
        /mnt/SDCARD/System/bin/syncthing serve --home="$SYNCTHING_CONF_DIR" > "$SYNCTHING_LOG_DIR/serve.log" 2>&1 &
    fi
}

start_dufs_process() {
    if ! pgrep dufs >/dev/null 2>&1; then
        nice -2 /mnt/SDCARD/System/bin/dufs \
            --allow-upload \
            --allow-delete \
            --allow-search \
            --allow-archive \
            --log-file "$LOG_DIR/dufs.log" \
            "/mnt/SDCARD" &
    fi
}

stop_syncthing_process() {
    if pgrep syncthing >/dev/null 2>&1; then
        killall -9 syncthing
    fi
}

stop_dufs_process() {
    if pgrep dufs >/dev/null 2>&1; then
        killall -9 dufs
    fi
}