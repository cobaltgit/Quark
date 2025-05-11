#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd /mnt/SDCARD

case "$SSH_ORIGINAL_COMMAND" in
	"/usr/libexec/gesftpserver") exec gesftpserver ;;
	*) exec "${SSH_ORIGINAL_COMMAND:-/bin/sh}"
esac