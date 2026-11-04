#!/bin/bash
set -u

if ! hyprctl reload; then
    notify-send "Recarga de Hyprland" "No se pudo recargar la configuración" -t 3000
    exit 1
fi

sleep 0.2
HEADLESS_OUTPUT=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' | head -n 1)
WALLPAPER="$HOME/.config/hypr/current_wallpaper"

if [ -n "$HEADLESS_OUTPUT" ]; then
    hyprctl keyword monitor "$HEADLESS_OUTPUT,1920x1080@60,auto,1"
    if [ -f "$WALLPAPER" ] && pgrep -x awww-daemon > /dev/null; then
        awww img "$WALLPAPER" --outputs "$HEADLESS_OUTPUT" --transition-type none
    fi
fi

if pgrep -x waybar > /dev/null; then
    pkill -SIGUSR2 waybar
else
    GDK_BACKEND=wayland waybar &
fi

ags quit 2>/dev/null
setsid ags run </dev/null >/dev/null 2>&1 &
