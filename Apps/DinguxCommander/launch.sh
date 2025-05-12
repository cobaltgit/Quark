#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd "$(dirname "$0")"

export HOME="/mnt/SDCARD"

if [ "$PLATFORM" != "tg2040" ]; then
    gptokeyb "DinguxCommander.$PLATFORM" -c "DinguxCommander.gptk" &
fi

"./DinguxCommander.$PLATFORM"
sync
killall -9 gptokeyb