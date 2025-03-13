#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir

echo "=============================================="
echo "================== reboot  ==================="
echo "=============================================="

chmod 777 reboot_wait
./reboot_wait&
sleep 1
reboot
