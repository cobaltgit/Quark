#!/bin/sh

cd /mnt/SDCARD

case "$SSH_ORIGINAL_COMMAND" in
	"/usr/libexec/sftp-server") exec "/mnt/SDCARD/System/bin/gesftpserver" ;;
	*) exec "${SSH_ORIGINAL_COMMAND:-/bin/sh}" ;;
esac