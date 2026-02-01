#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd "$(dirname "$0")"

export HOME="/mnt/SDCARD"

./DinguxCommander
sync
