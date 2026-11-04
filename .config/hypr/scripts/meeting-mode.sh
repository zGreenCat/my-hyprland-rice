#!/bin/bash
HEADLESS=$(hyprctl monitors | grep -o 'HEADLESS-[0-9]*' | head -1)
if [ -n "$HEADLESS" ]; then
    pkill -f "wl-mirror $HEADLESS" 2>/dev/null
    hyprctl dispatch moveworkspacetomonitor 8 eDP-1
    hyprctl output remove "$HEADLESS"
else
    hyprctl output create headless
    sleep 0.5
    HEADLESS=$(hyprctl monitors | grep -o 'HEADLESS-[0-9]*' | head -1)
    if [ -n "$HEADLESS" ]; then
        hyprctl keyword monitor "$HEADLESS",1920x1080@60,auto,1
        hyprctl dispatch moveworkspacetomonitor 8 "$HEADLESS"
        sleep 0.2
        wl-mirror "$HEADLESS" &
    fi
fi
