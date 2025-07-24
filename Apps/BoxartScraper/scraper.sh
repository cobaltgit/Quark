#!/bin/sh

. /mnt/SDCARD/System/scripts/helpers.sh

export SSL_CERT_FILE="/mnt/SDCARD/System/etc/ca-certificates.crt"

SCRAPER_LOG="/mnt/SDCARD/System/log/scraper.log"
ROMS_DIR="/mnt/SDCARD/Roms"
SELECT_PRESSED=false
START_PRESSED=false
EXITING=false

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

get_image_name() {
    local sys_name="$1"
    local rom_file_name="$2"
    local rom_without_ext="${rom_file_name%.*}"

    case "$sys_name" in
        ARCADE|FBNEO|MAME2003PLUS|NEOGEO|CPS1|CPS2|CPS3|PGM)
            awk -v rom="$rom_without_ext" -F'\t' '$1 == rom { gsub(/^"|"$/, "", $2); print $2 ".png"; exit }' "db/ARCADE_games.txt"
            return
            ;;
    esac

    local image_list_file="db/${sys_name}_games.txt"
    [ ! -f "$image_list_file" ] && return

    # Try exact match first
    image_name=$(grep -i "^$(printf '%s' "$rom_without_ext" | sed 's/\[/\\[/g; s/\]/\\]/g')\.png$" "$image_list_file")
    if [ -n "$image_name" ]; then
        echo "$image_name"
        return
    fi

    # Fuzzy match: remove anything in brackets, flip ampersands to underscores (libretro quirk), remove trailing whitespace
    search_term="$(printf '%s' "$rom_without_ext" | sed -e 's/&/_/g' -e 's/\[.*\]//g' -e 's/[[:blank:]]*$//')"
    matches=$(grep -E "^$search_term( \\(|\\.)" "$image_list_file")
    if [ -n "$matches" ]; then
        echo "$matches" | head -1
        return
    fi

    # As a final check, try without the region or anything in parens
    search_term=$(printf '%s' "$search_term" | sed -e 's/([^)]*)//g' -e 's/[[:blank:]]*$//')
    matches=$(grep -E "^$search_term( \\(|\\.)" "$image_list_file")

    if [ -n "$matches" ]; then
        usa_match=$(echo "$matches" | grep '(USA)')
        if [ -n "$usa_match" ]; then
            echo "$usa_match" | head -1
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
        EXITING=true
        log_message "Scraper: user requested exit" "$SCRAPER_LOG"
        display -d 2000 -t "Exiting scraper..."
        killall -9 scraper.sh # suicide
    fi
done &
EVTEST_LOOP_PID=$!

for SYSTEM in "$ROMS_DIR"/*/; do
    [ ! -d "$SYSTEM" ] && continue

    SYS_NAME="$(basename "$SYSTEM")"

    if [ ! -f "db/${SYS_NAME}_games.txt" ]; then
        log_message "Scraper: gamelist for $SYS_NAME not found" "$SCRAPER_LOG"
        continue
    fi

    log_message "Scraper: scraping box art for $SYS_NAME" "$SCRAPER_LOG"

    get_ra_alias "$SYS_NAME"
    if [ -z "$ra_name" ]; then
        log_message "Scraper: remote system name not found, skipping $SYS_NAME" "$SCRAPER_LOG"
        continue
    fi

    config_file="/mnt/SDCARD/Emus/$SYS_NAME/config.json"
    if [ ! -f "$config_file" ]; then
        log_message "Scraper: config file not found for $SYS_NAME, skipping..." "$SCRAPER_LOG"
        continue
    fi
 
    ROM_EXTS="$(jq -r '.extlist' "$config_file" | tr '|' ' ')"
    SYS_LABEL="$(jq -r '.label' "$config_file")"

    if [ -z "$ROM_EXTS" ]; then
        log_message "Scraper: no supported extensions found for $SYS_NAME, skipping..." "$SCRAPER_LOG"
        continue
    fi

    mkdir -p "${SYSTEM}Imgs"

    rom_files=$(find "$SYSTEM" -maxdepth 1 -type f -regex ".*\\.\\($(echo "$ROM_EXTS" | sed 's/ /\\|/g')\\)\$")
    
    if [ -z "$rom_files" ]; then
        log_message "Scraper: no ROM files found for $SYS_NAME, skipping..." "$SCRAPER_LOG"
        continue
    fi

    AMOUNT_GAMES=$(echo "$rom_files" | wc -l)
    display -t "Scraping $SYS_LABEL: 0/$AMOUNT_GAMES (0%)"

    SKIP_COUNT=0
    SCRAPED_COUNT=0
    NOT_FOUND_COUNT=0
    CURRENT_COUNT=0
    LAST_UPDATE=0

    # Build URLs
    base_url="http://thumbnails.libretro.com/$ra_name/Named_Boxarts"
    github_base="https://raw.githubusercontent.com/libretro-thumbnails/$(echo "$ra_name" | sed 's/ /_/g')/master/Named_Boxarts"

    echo "$rom_files" | while IFS= read -r ROM_FILE; do

        CURRENT_COUNT=$((CURRENT_COUNT + 1))
        CURRENT_TIME=$(date +%s)
        if [ $((CURRENT_TIME - LAST_UPDATE)) -ge 5 ]; then
            PROGRESS=$((CURRENT_COUNT * 100 / AMOUNT_GAMES))
            if [ "$EXITING" != "false" ]; then # don't display if user requests exit
                display -t "Scraping $SYS_LABEL: $CURRENT_COUNT/$AMOUNT_GAMES ($PROGRESS%)"
            fi
            LAST_UPDATE=$CURRENT_TIME
        fi

        ROM_BASENAME="$(basename "$ROM_FILE")"
        ROM_NAME="${ROM_BASENAME%.*}"
        IMAGE_PATH="${SYSTEM}Imgs/$ROM_NAME.png"

        # Skip if image already exists
        if [ -f "$IMAGE_PATH" ]; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi
       
        REMOTE_IMAGE_NAME=$(get_image_name "$SYS_NAME" "$ROM_BASENAME")
        if [ -z "$REMOTE_IMAGE_NAME" ]; then
            NOT_FOUND_COUNT=$((NOT_FOUND_COUNT + 1))
            continue
        fi

        # URL encoding and cleanup
        REMOTE_IMAGE_NAME_CLEAN="$REMOTE_IMAGE_NAME"
        REMOTE_IMAGE_NAME_ALT=$(echo "$REMOTE_IMAGE_NAME_CLEAN" | sed 's| -|_|')
        
        BOXART_URL=$(printf '%s/%s' "$base_url" "$REMOTE_IMAGE_NAME_CLEAN" | sed 's/ /%20/g')
        BOXART_URL_ALT=$(printf '%s/%s' "$base_url" "$REMOTE_IMAGE_NAME_ALT" | sed 's/ /%20/g')  
        FALLBACK_URL=$(printf '%s/%s' "$github_base" "$REMOTE_IMAGE_NAME_CLEAN" | sed 's/ /%20/g')
        FALLBACK_URL_ALT=$(printf '%s/%s' "$github_base" "$REMOTE_IMAGE_NAME_ALT" | sed 's/ /%20/g')

        log_message "BoxartScraper: Downloading $BOXART_URL" "$SCRAPER_LOG"
        
        # Try primary URLs, then fallbacks
        if curl -fgso "$IMAGE_PATH" "$BOXART_URL" || curl -fgso "$IMAGE_PATH" "$BOXART_URL_ALT" || \
            curl -fgso "$IMAGE_PATH" "$FALLBACK_URL" || curl -fgso "$IMAGE_PATH" "$FALLBACK_URL_ALT"; then
            log_message "BoxartScraper: $SYS_NAME: scraped image for $ROM_BASENAME" "$SCRAPER_LOG"
            SCRAPED_COUNT=$((SCRAPED_COUNT + 1))
        else
            log_message "BoxartScraper: failed to scrape $ROM_BASENAME" "$SCRAPER_LOG"
            rm -f "$IMAGE_PATH"
            NOT_FOUND_COUNT=$((NOT_FOUND_COUNT + 1))
        fi
    done
    
    log_message "Scraper: $SYS_NAME - Scraped: $SCRAPED_COUNT, Skipped: $SKIP_COUNT, Not found: $NOT_FOUND_COUNT" "$SCRAPER_LOG"
done

kill -9 $EVTEST_LOOP_PID 2>/dev/null
display -d 2000 -t "Scraping complete!"