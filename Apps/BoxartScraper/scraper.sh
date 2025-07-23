#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

SCRAPER_LOG="/mnt/SDCARD/System/log/scraper.log"
ROMS_DIR="/mnt/SDCARD/Roms"
SELECT_PRESSED=false
START_PRESSED=false

get_ra_alias() {
    case $1 in
        AMIGA) ra_name="Commodore - Amiga" ;;
        ATARI800) ra_name="Atari - 8-bit" ;;
        ATARI2600) ra_name="Atari - 2600" ;;
        ATARIST) ra_name="Atari - ST" ;;
        ARCADE | MAME2003PLUS | CPS1 | CPS2 | CPS3 | PGM) ra_name="MAME" ;;
        ARDUBOY) ra_name="Arduboy Inc - Arduboy" ;;
        COLECO) ra_name="Coleco - ColecoVision" ;;
        C64) ra_name="Commodore - 64" ;;
        CPC) ra_name="Amstrad - CPC" ;;
        DOOM) ra_name="DOOM" ;;
        DOS) ra_name="DOS" ;;
        CHAF) ra_name="Fairchild - Channel F" ;;
        FBNEO) ra_name="FBNeo - Arcade Games" ;; # gluon system
        FC) ra_name="Nintendo - Nintendo Entertainment System" ;;
        FDS) ra_name="Nintendo - Family Computer Disk System" ;;
        ATARI5200) ra_name="Atari - 5200" ;;
        GB) ra_name="Nintendo - Game Boy" ;;
        GBA) ra_name="Nintendo - Game Boy Advance" ;;
        GBC) ra_name="Nintendo - Game Boy Color" ;;
        GG) ra_name="Sega - Game Gear" ;;
        GW) ra_name="Handheld Electronic" ;;
        INTV) ra_name="Mattel - Intellivision" ;;
        LYNX) ra_name="Atari - Lynx" ;;
        MD) ra_name="Sega - Mega Drive - Genesis" ;;
        MS) ra_name="Sega - Master System - Mark III" ;;
        MSX) ra_name="Microsoft - MSX" ;;
        MSX2) ra_name="Microsoft - MSX2" ;;
        NDS) ra_name="Nintendo - Nintendo DS" ;; # gluon system
        NEOCD) ra_name="SNK - Neo Geo CD" ;;
        NEOGEO) ra_name="SNK - Neo Geo" ;;
        NGP) ra_name="SNK - Neo Geo Pocket" ;;
        NGPC) ra_name="SNK - Neo Geo Pocket Color" ;;
        PCE) ra_name="NEC - PC Engine - TurboGrafx 16" ;;
        PCECD) ra_name="NEC - PC Engine CD - TurboGrafx-CD" ;;
        POKEMINI) ra_name="Nintendo - Pokemon Mini" ;;
        PS) ra_name="Sony - PlayStation" ;;
        QUAKE) ra_name="Quake" ;;
        SEGACD) ra_name="Sega - Mega-CD - Sega CD" ;;
        SG1000) ra_name="Sega - SG-1000" ;;
        ATARI7800) ra_name="Atari - 7800" ;;
        SATELLAVIEW) ra_name="Nintendo - Satellaview" ;;
        SCUMMVM) ra_name="ScummVM" ;; # gluon system
        SFC) ra_name="Nintendo - Super Nintendo Entertainment System" ;;
        SGFX) ra_name="NEC - PC Engine SuperGrafx" ;;
        SUPERVISION) ra_name="Watara - Supervision" ;;
        SEGA32X) ra_name="Sega - 32X" ;;
        TIC80) ra_name="TIC-80" ;;
        VB) ra_name="Nintendo - Virtual Boy" ;;
        VIC20) ra_name="Commodore - VIC-20" ;;
        WOLF3D) ra_name="Wolfenstein 3D" ;;
        WS) ra_name="Bandai - WonderSwan" ;;
        WSC) ra_name="Bandai - WonderSwan Color" ;;
        X68000) ra_name="Sharp - X68000" ;;
        ZXS) ra_name="Sinclair - ZX Spectrum" ;;
        *) ra_name='' ;;
    esac
}

# modified from spruce's scraper
get_image_name() {
    local sys_name="$1"
    local rom_file_name="$2"
    local rom_without_ext

    if echo "$sys_name" | grep -qE "(ARCADE|FBNEO|MAME2003PLUS|NEOGEO|CPS1|CPS2|CPS3)"; then
        # These systems' roms in libretro are stored by their long-form name.
        rom_without_ext="${rom_file_name%.*}"
        awk -v rom="$rom_without_ext" -F'\t' '$1 == rom { gsub(/^"|"$/, "", $2); print $2 ".png" }' "db/ARCADE_games.txt"
        return
    else
        rom_without_ext="${rom_file_name%.*}"
    fi

    local image_list_file="db/${sys_name}_games.txt"

    # Check if the game list file exists
    if [ ! -f "$image_list_file" ]; then
        return
    fi
    
    # Try an exact match first, escaping brackets for grep
    image_name=$(grep -i "^$(echo "$rom_without_ext" | sed 's/\[/\\\[/g; s/\]/\\\]/g')\.png$" "$image_list_file")
    if [ -n "$image_name" ]; then
        echo "$image_name"
        return
    fi


    # Fuzzy match: remove anything in brackets, flip ampersands to underscores (libretro quirk), remove trailing whitespace
    search_term="$(echo "$rom_without_ext" | sed -e 's/&/_/g' -e 's/\[.*\]//g' -e 's/[[:blank:]]*$//g')"
    matches=$(grep -E "^$search_term( \(|\.)" "$image_list_file") 
    if [ -n "$matches" ]; then
        echo "$matches" | head -1
        return
    fi
    # As a final check, try without the region or anything in parens
    search_term=$(echo "$search_term" | sed -e 's/([^)]*)//g' -e 's/[[:blank:]]*$//g')
    matches=$(grep -E "^$search_term( \(|\.)" "$image_list_file") 

    if [ -n "$matches" ]; then
        if echo "$matches" | grep -q '(USA)' ; then
          echo "$matches" | grep '(USA)' | head -1
        else
          echo "$matches" | head -1
        fi
    fi
}

display -t "Starting scraper..."

if [ "$(awk '/wifi/ { gsub(/[,]/,"",$2); print $2}' "/mnt/UDISK/system.json")" -eq 0 ]; then
    log_message "Scraper: WiFi is disabled in system settings" "$SCRAPER_LOG"
    display -d 2000 -t "WiFi is disabled in system settings."
    exit 1
elif ! ping -c2 8.8.8.8 >/dev/null 2>&1; then
    log_message "Scraper: no Internet connection" "$SCRAPER_LOG"
    display -d 2000 -t "Unable to connect to the Internet."
    exit 1
elif ! ping -c 2 thumbnails.libretro.com > /dev/null 2>&1; then
    log_message "Scraper: couldn't reach libretro thumbnail service, falling back to GitHub" "$SCRAPER_LOG"
    if ! ping -c 2 github.com > /dev/null 2>&1; then
        log_message "Scraper: couldn't reach GitHub" "$SCRAPER_LOG"
        display -d 2000 -t "Unable to reach libretro thumbnails service."
        exit 1
    fi
fi

evtest /dev/input/event0 | while read line; do
    case "$line" in
        *"EV_KEY"*"KEY_RIGHTCTRL"*"value 1") SELECT_PRESSED=true ;;
        *"EV_KEY"*"KEY_RIGHTCTRL"*"value 0") SELECT_PRESSED=false ;;
        *"EV_KEY"*"KEY_ENTER"*"value 1") START_PRESSED=true ;;
        *"EV_KEY"*"KEY_ENTER"*"value 0") START_PRESSED=false ;;
    esac

    if [ "$SELECT_PRESSED" = "true" ] && [ "$START_PRESSED" = "true" ]; then
        log_message "Scraper: user requested exit" "$SCRAPER_LOG"
        display -d 2000 -t "Exiting scraper..."
        killall -9 scraper.sh # suicide
    fi
done &
EVTEST_LOOP_PID=$!

for SYSTEM in "$ROMS_DIR"/*/; do
    [ ! -d "$SYSTEM" ] && continue

    SYS_NAME="$(basename "$SYSTEM")"
    log_message "Scraper: scraping box art for $SYS_NAME" "$SCRAPER_LOG"

    get_ra_alias "$SYS_NAME"
    if [ -z "$ra_name" ]; then
        log_message "Scraper: remote system name not found, skipping $SYS_NAME" "$SCRAPER_LOG"
        continue
    fi

    ROM_EXTS="$(/mnt/SDCARD/System/bin/jq -r '.extlist' "/mnt/SDCARD/Emus/$SYS_NAME/config.json" | awk '{gsub(/\|/, " "); print $0}')"
    AMOUNT_GAMES="$(find "$SYSTEM" -type f -regex ".*\.\($(echo "$ROM_EXTS" | sed 's/ /\\\|/g')\)$" | wc -l)"
    SYS_LABEL="$(/mnt/SDCARD/System/bin/jq ".label" "/mnt/SDCARD/Emus/$SYS_NAME/config.json")"

    if [ -z "$ROM_EXTS" ] || [ "$AMOUNT_GAMES" -eq 0 ]; then
        log_message "Scraper: no supported extensions/games found for $SYS_NAME, skipping..." "$SCRAPER_LOG"
        continue
    fi

    display -t "Scraping $SYS_LABEL: $AMOUNT_GAMES games..."

    SKIP_COUNT=0
    SCRAPED_COUNT=0
    NOT_FOUND_COUNT=0

    for ROM_FILE in "$SYSTEM"*; do
        ROM_BASENAME="$(basename "$ROM_FILE")"

        # skip non-rom files
        if [ -d "$ROM_FILE" ] || [ "$ROM_BASENAME" = ".*" ] \
            || ! echo "$ROM_BASENAME" | grep -qE "\.($(echo "$ROM_EXTS" | sed -e "s/ /\|/g"))$"; then
            continue
        fi

        ROM_NAME="${ROM_BASENAME%.*}"
        IMAGE_PATH="${SYSTEM}Imgs/$ROM_NAME.png"

        mkdir -p "${SYSTEM}Imgs"

        if [ -f "$IMAGE_PATH" ]; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi
       
        REMOTE_IMAGE_NAME=$(get_image_name "$SYS_NAME" "$ROM_BASENAME")
        REMOTE_IMAGE_NAME_ALT="$(echo "$REMOTE_IMAGE_NAME" | sed 's| -|_|')" # alternate colon replacement

        if [ -z "$REMOTE_IMAGE_NAME" ]; then
            NOT_FOUND_COUNT=$((NOT_FOUND_COUNT + 1))
            continue
        fi

        BOXART_URL=$(echo "http://thumbnails.libretro.com/$ra_name/Named_Boxarts/$REMOTE_IMAGE_NAME" | sed 's/ /%20/g' | tr -d '\r' )
        BOXART_URL_ALT=$(echo "http://thumbnails.libretro.com/$ra_name/Named_Boxarts/$REMOTE_IMAGE_NAME_ALT" | sed 's/ /%20/g' | tr -d '\r' )
        FALLBACK_URL="$(echo "https://raw.githubusercontent.com/libretro-thumbnails/$(echo "$ra_name" | sed 's/ /_/g')/master/Named_Boxarts/$REMOTE_IMAGE_NAME" | sed 's/ /%20/g' | tr -d '\r')"
        FALLBACK_URL_ALT="$(echo "https://raw.githubusercontent.com/libretro-thumbnails/$(echo "$ra_name" | sed 's/ /_/g')/master/Named_Boxarts/$REMOTE_IMAGE_NAME_ALT" | sed 's/ /%20/g' | tr -d '\r')"
        log_message "BoxartScraper: Downloading $BOXART_URL" "$SCRAPER_LOG"
        if ! { curl -fgkso "$IMAGE_PATH" "$BOXART_URL" || curl -fgkso "$IMAGE_PATH" "$BOXART_URL_ALT"; }; then
            log_message "BoxartScraper: failed to scrape $BOXART_URL, falling back to libretro thumbnails GitHub repo." "$SCRAPER_LOG"
            rm -f "$IMAGE_PATH"
            if ! { curl -fgkso "$IMAGE_PATH" "$FALLBACK_URL" || curl -fgkso "$IMAGE_PATH" "$FALLBACK_URL_ALT"; }; then
                log_message "BoxartScraper: failed to scrape $FALLBACK_URL." "$SCRAPER_LOG"
                rm -f "$IMAGE_PATH"
            fi
        fi

        if [ -f "$IMAGE_PATH" ]; then
            SCRAPED_COUNT=$((SCRAPED_COUNT + 1))
        else
            NOT_FOUND_COUNT=$((NOT_FOUND_COUNT + 1))
        fi
    done
    log_message "Scraper: $SYS_NAME - Scraped: $SCRAPED_COUNT, Skipped: $SKIP_COUNT, Not found: $NOT_FOUND_COUNT" "$SCRAPER_LOG"
done

kill -9 $EVTEST_LOOP_PID
display -d 2000 -t "Scraping complete!"