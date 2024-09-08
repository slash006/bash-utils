#!/bin/bash

BRIGHTNESS_LEVEL=1
IDLE_TIME=10000 
STATE_FILE="/var/tmp/keyboard_backlight_state.txt"

check_xprintidle_installed() {
    if ! command -v xprintidle &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y xprintidle
    fi
}

get_idle_time() {
    xprintidle
}

set_keyboard_backlight() {
    local level=$1
    current_level=$(cat "$STATE_FILE" 2>/dev/null) 
    if [ "$current_level" != "$level" ]; then
        echo "$level" > "$STATE_FILE"
        sudo -u $USER brightnessctl --device='asus::kbd_backlight' s "$level"
    fi
}

main() {
    check_xprintidle_installed

    if [ ! -f "$STATE_FILE" ]; then
        echo "unknown" > "$STATE_FILE"
    fi

    while true; do
        idle=$(get_idle_time)
        
        if [ "$idle" -ge "$IDLE_TIME" ]; then
            set_keyboard_backlight 0
        else
            set_keyboard_backlight "$BRIGHTNESS_LEVEL"
        fi
        
        sleep 0.2
    done
}

main
