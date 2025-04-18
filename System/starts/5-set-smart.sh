#!/bin/sh
# Sets CPU to smart before entering MainUI.
# preload.sh on flash won't set the CPU governor to ondemand due to the function's write locking of CPU settings.

. /mnt/SDCARD/System/scripts/helpers.sh

set_cpuclock --mode smart
