#!/bin/sh
# Detects update packages and makes the updater app visible

UPDATER_APP_CONFIG="/mnt/SDCARD/Apps/QuarkUpdater/config.json"
UPDATE_PKG="$(ls -t /mnt/SDCARD/Quark_Update_*.zip | head -1)"

if [ -f "$UPDATE_PKG" ]; then
    sed -i 's/^{{*$/{/' "$UPDATER_APP_CONFIG" # make visible
else
    sed -i 's/^{*$/{{/' "$UPDATER_APP_CONFIG" # "self-destruct"
fi
