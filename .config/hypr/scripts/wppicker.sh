#!/bin/bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

cd "$WALLPAPER_DIR" || exit 1

# === SELECTION WITH ROFI (with image preview) ===
SELECTED_WALL=$(ls -t *.jpg *.png *.gif *.jpeg 2>/dev/null | while read -r img; do
    echo -en "$img\x00icon\x1f$WALLPAPER_DIR/$img\n"
done | rofi -dmenu -i -p "Selecciona wallpaper" -show-icons)

[ -z "$SELECTED_WALL" ] && exit 1
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === UNLOAD OLD WALLPAPERS ===
hyprctl hyprpaper listloaded 2>/dev/null | while read -r wp; do
    [ -n "$wp" ] && hyprctl hyprpaper unload "$wp" 2>/dev/null
done

# === SET WALLPAPER WITH HYPRPAPER ===
# Preload the new wallpaper
hyprctl hyprpaper preload "$SELECTED_PATH"

# Get all monitors and set wallpaper on each
hyprctl monitors -j | jq -r '.[].name' | while read -r monitor; do
    hyprctl hyprpaper wallpaper "$monitor,$SELECTED_PATH"
done

# Also set for default (no monitor specified)
hyprctl hyprpaper wallpaper ",$SELECTED_PATH"

# === UPDATE CONFIG FILE ===
cat > ~/.config/hypr/hyprpaper.conf << CONF
# Preload wallpapers
preload = $SELECTED_PATH

# Set wallpaper for all monitors
wallpaper = ,$SELECTED_PATH

# Splash screen
splash = false

# ipc
ipc = on
CONF

# === CREATE SYMLINK ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# === TODO: MATUGEN (descomentar cuando esté instalado) ===
# if command -v matugen &> /dev/null; then
#     matugen image "$SELECTED_PATH"
#     ~/.config/hypr/scripts/wbrestart.sh
# fi

notify-send "🎨 Wallpaper cambiado" "$SELECTED_WALL" -t 2000
