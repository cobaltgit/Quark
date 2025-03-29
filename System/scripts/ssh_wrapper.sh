#!/bin/sh

cd /mnt/SDCARD

if [ "$SSH_ORIGINAL_COMMAND" = "/usr/libexec/sftp-server" ]; then
    [ -x "/mnt/SDCARD/System/bin/gesftpserver" ] && exec /mnt/SDCARD/System/bin/gesftpserver
elif [ -n "$SSH_ORIGINAL_COMMAND" ]; then
	exec $SSH_ORIGINAL_COMMAND
else
	exec /bin/sh
fi