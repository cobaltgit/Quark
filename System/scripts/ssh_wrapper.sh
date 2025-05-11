#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

cd /mnt/SDCARD

case "$SSH_ORIGINAL_COMMAND" in
	"/usr/libexec/sftp-server") exec gesftpserver ;;
	*) exec "${SSH_ORIGINAL_COMMAND:-/bin/sh}"
esac