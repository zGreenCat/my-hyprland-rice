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
hyprctl hyprpaper preload "$SELECTED_PATH"

hyprctl monitors -j | jq -r '.[].name' 2>/dev/null | while read -r monitor; do
    hyprctl hyprpaper wallpaper "$monitor,$SELECTED_PATH"
done

hyprctl hyprpaper wallpaper ",$SELECTED_PATH"

# === UPDATE CONFIG FILE ===
cat > ~/.config/hypr/hyprpaper.conf << CONF
preload = $SELECTED_PATH
wallpaper = ,$SELECTED_PATH
splash = false
ipc = on
CONF

# === CREATE SYMLINK ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# === MATUGEN - Generate colors from wallpaper ===
if command -v matugen &> /dev/null; then
    # Generate pywal-compatible colors
    matugen image "$SELECTED_PATH" 2>/dev/null
    
    # Reload waybar to apply new colors
    sleep 0.3
    ~/.config/hypr/scripts/wbrestart.sh &
    
    # Reload Hyprland to apply border colors
    sleep 0.5
    hyprctl reload &
fi

notify-send "🎨 Wallpaper y tema cambiados" "$SELECTED_WALL" -t 2000
