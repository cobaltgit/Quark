#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

BTN_SOUND=$(get_setting "user" "btn-sound")

if [ "$BTN_SOUND" = "true" ]; then
    BTN_SOUND=false
    find /mnt/SDCARD/Themes -name 'click.wav' -type f -exec mv "{}" "{}.off" \;
    sed -i -e 's|\[ON\]|\[OFF\]|' -e 's|icon-on.png|icon-off.png|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Disabled button sound..."
else
    BTN_SOUND=true
    find /mnt/SDCARD/Themes -name 'click.wav.off' -type f -exec sh -c 'mv "$1" "${1%.wav.off}.wav"' _ {} \;
    sed -i -e 's|\[OFF\]|\[ON\]|' -e 's|icon-off.png|icon-on.png|' "$(dirname "$0")/config.json"
    display -d 1500 -t "Enabled button sound..."
fi

update_setting "user" "btn-sound" "$BTN_SOUND"
