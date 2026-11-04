#!/bin/bash
VNC_PORT=5901
HEADLESS=$(hyprctl monitors | grep -o 'HEADLESS-[0-9]*' | head -1)
if [ -n "$HEADLESS" ]; then
    pkill -f "wl-mirror $HEADLESS" 2>/dev/null
    pkill -f "wayvnc.*-o $HEADLESS" 2>/dev/null
    ~/.config/hypr/scripts/audio-al-pc.sh stop
    hyprctl dispatch moveworkspacetomonitor 8 eDP-1
    hyprctl output remove "$HEADLESS"
    notify-send "Meeting mode" "Apagado: pantalla y audio cortados" 2>/dev/null
else
    hyprctl output create headless
    sleep 0.5
    HEADLESS=$(hyprctl monitors | grep -o 'HEADLESS-[0-9]*' | head -1)
    if [ -n "$HEADLESS" ]; then
        hyprctl keyword monitor "$HEADLESS",1920x1080@60,auto,1
        hyprctl dispatch moveworkspacetomonitor 8 "$HEADLESS"
        sleep 0.2
        wl-mirror "$HEADLESS" &
        wayvnc -o "$HEADLESS" "0.0.0.0:$VNC_PORT" &
        ~/.config/hypr/scripts/audio-al-pc.sh start
        LAN_IP=$(ip -4 addr show wlan0 | grep -oP 'inet \K[0-9.]+')
        notify-send "Meeting mode" "Pantalla: $LAN_IP:$VNC_PORT (VNC)\nAudio: enviando al PC" 2>/dev/null
    fi
fi
