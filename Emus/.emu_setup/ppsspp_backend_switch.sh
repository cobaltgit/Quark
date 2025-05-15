#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

EMU="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emus/${EMU}/config.json"
OPT="/mnt/SDCARD/Emus/.emu_setup/opts/${EMU}.opt"

. "$OPT"

case "$VIDEO_BACKEND" in
    "opengl") NEW_BACKEND="vulkan" NEW_DISPLAY="Vulkan" ;;
    "vulkan") NEW_BACKEND="opengl" NEW_DISPLAY="OpenGL" ;;
esac

sed -i "s|\"Video Backend:.*\"|\"Video Backend: $NEW_DISPLAY\"|g" "$CONFIG"
sed -i "s|VIDEO_BACKEND=.*|VIDEO_BACKEND=\"$NEW_BACKEND\"|g" "$OPT"

display -d 1000 -t "Video backend for PPSSPP set to $NEW_DISPLAY."