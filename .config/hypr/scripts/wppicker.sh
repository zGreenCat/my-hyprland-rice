#!/bin/bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

cd "$WALLPAPER_DIR" || exit 1

# === SELECTION WITH WOFI ===
SELECTED_WALL=$(ls -t *.jpg *.png *.gif *.jpeg 2>/dev/null | wofi --dmenu -p "Selecciona wallpaper")

[ -z "$SELECTED_WALL" ] && exit 1
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === SET WALLPAPER WITH HYPRPAPER ===
# Precargar el wallpaper
hyprctl hyprpaper preload "$SELECTED_PATH"

# Establecerlo en todos los monitores
for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl hyprpaper wallpaper "$monitor,$SELECTED_PATH"
done

# === CREATE SYMLINK ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# === TODO: MATUGEN (descomentar cuando esté instalado) ===
# if command -v matugen &> /dev/null; then
#     matugen image "$SELECTED_PATH"
# fi

notify-send "Wallpaper cambiado" "$SELECTED_WALL" -t 2000
