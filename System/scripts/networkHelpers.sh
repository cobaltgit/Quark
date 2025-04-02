#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

export SSL_CERT_FILE="/mnt/SDCARD/System/etc/ca-certificates.crt"

LOG_DIR="/mnt/SDCARD/System/log"
SYNCTHING_LOG_DIR="$LOG_DIR/syncthing"
SYNCTHING_CONF_DIR="/mnt/SDCARD/System/etc/syncthing"
DROPBEAR_KEY_DIR="/mnt/SDCARD/System/etc/ssh"

setup_syncthing() {
    [ ! -d "$SYNCTHING_LOG_DIR" ] && mkdir -p "$SYNCTHING_LOG_DIR"
    [ ! -d "$SYNCTHING_CONF_DIR" ] && mkdir -p "$SYNCTHING_CONF_DIR"
    if ! [ -f "$SYNCTHING_CONF_DIR/config.xml" ]; then
        display -t "Setting up Syncthing..."

        ifconfig lo down
        sleep 1
        ifconfig lo up
        sleep 1
        /mnt/SDCARD/System/bin/syncthing generate \
            --gui-user=quark \
            --gui-password=quark \
            --no-default-folder \
            --home="$SYNCTHING_CONF_DIR" > "$SYNCTHING_LOG_DIR/generate.log" 2>&1 &
        sleep 5

        if grep -q "<listenAddress>dynamic+https://relays.syncthing.net/endpoint</listenAddress>" "$SYNCTHING_CONF_DIR/config.xml"; then
            sed -i '/<listenAddress>dynamic+https:\/\/relays.syncthing.net\/endpoint<\/listenAddress>/d' "$SYNCTHING_CONF_DIR/config.xml"
            sed -i '/<listenAddress>quic:\/\/0.0.0.0:41383<\/listenAddress>/d' "$SYNCTHING_CONF_DIR/config.xml"
            sed -i 's|<listenAddress>tcp://0.0.0.0:41383</listenAddress>|<listenAddress>default</listenAddress>|' "$SYNCTHING_CONF_DIR/config.xml"
        fi

        killall syncthing

        sync
        sed -i "s|<address>127.0.0.1:8384</address>|<address>0.0.0.0:8384</address>|g" $SYNCTHING_CONF_DIR/config.xml
        sed -i 's|<urAccepted>0</urAccepted>|<urAccepted>-1</urAccepted>|' "$SYNCTHING_CONF_DIR/config.xml"
        sed -i 's/\(name="\)sun8i\(\"\)/\1Quark\2/' "$SYNCTHING_CONF_DIR/config.xml"

        kill_display
    fi
}

setup_dropbear() {
    display -t "Setting up SSH..."

    [ ! -d "$DROPBEAR_KEY_DIR" ] && mkdir -p "$DROPBEAR_KEY_DIR"
    [ ! -f "$DROPBEAR_KEY_DIR/dropbear_rsa_host_key" ] && /mnt/SDCARD/System/bin/dropbearmulti dropbearkey -t rsa -f "$DROPBEAR_KEY_DIR/dropbear_rsa_host_key"
    [ ! -f "$DROPBEAR_KEY_DIR/dropbear_ecdsa_host_key" ] && /mnt/SDCARD/System/bin/dropbearmulti dropbearkey -t ecdsa -f "$DROPBEAR_KEY_DIR/dropbear_ecdsa_host_key"
    [ ! -f "$DROPBEAR_KEY_DIR/dropbear_ed25519_host_key" ] && /mnt/SDCARD/System/bin/dropbearmulti dropbearkey -t ed25519 -f "$DROPBEAR_KEY_DIR/dropbear_ed25519_host_key"
    [ "$(awk -F ":" '/root/ {print $2}' "/etc/shadow")" = "!" ] && echo -e "quark\nquark" | passwd root # set default root password

    kill_display
}

start_syncthing_process() {
    setup_syncthing
    if ! pgrep syncthing >/dev/null 2>&1; then
        HOME="/mnt/SDCARD" /mnt/SDCARD/System/bin/syncthing serve \
            --no-restart \
            --no-upgrade \
            --home="$SYNCTHING_CONF_DIR" \
            > "$SYNCTHING_LOG_DIR/serve.log" 2>&1 &
    fi
}

start_dufs_process() {
    if ! pgrep dufs >/dev/null 2>&1; then
        nice -2 /mnt/SDCARD/System/bin/dufs \
            --auth quark:quark@/:rw \
            --allow-upload \
            --allow-delete \
            --allow-search \
            --allow-archive \
            --log-file "$LOG_DIR/dufs.log" \
            "/mnt/SDCARD" &
    fi
}

start_dropbear_process() {
    setup_dropbear
    if ! pgrep dropbearmulti >/dev/null 2>&1; then
        /mnt/SDCARD/System/bin/dropbearmulti dropbear \
            -r "$DROPBEAR_KEY_DIR/dropbear_rsa_host_key" \
            -r "$DROPBEAR_KEY_DIR/dropbear_ecdsa_host_key" \
            -r "$DROPBEAR_KEY_DIR/dropbear_ed25519_host_key" \
            -c "/mnt/SDCARD/System/scripts/ssh_wrapper.sh"
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

stop_dropbear_process() {
    if pgrep dropbearmulti >/dev/null 2>&1; then
        killall -9 dropbearmulti
    fi
}