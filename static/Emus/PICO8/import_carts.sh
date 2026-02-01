#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

BBS_PATH="/mnt/SDCARD/Emus/PICO8/.lexaloffle/pico-8/bbs"
ROM_PATH="/mnt/SDCARD/Roms/PICO8"
FAVE_PATH="/mnt/SDCARD/Emus/PICO8/.lexaloffle/pico-8/favourites.txt"

display -t "Importing carts from Splore..."

for cart in "$BBS_PATH"/*/*.p8.png ; do
	cartname="$(basename "$cart")"
	shortname="$(basename "$cart" .p8.png)"
	if [ -s "${cart}" ]; then
		cp -f "$cart" "$ROM_PATH/$cartname"		
		if grep -q "$shortname" "$FAVE_PATH"; then
			newname="$(awk -F '|' -v term="$shortname" '$2 ~ term {print $7}' $FAVE_PATH)"
			if [ -n "$newname" ]; then 
				mv -f "$ROM_PATH/$cartname" "$ROM_PATH/$newname.p8.png"
			fi
		fi
	fi
done

kill_display

rm -f "$ROM_PATH/PICO8_cache7.db"
