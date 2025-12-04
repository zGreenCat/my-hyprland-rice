#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🌓 Theme Toggle - Dark/Light Mode Switcher
#  Cambia entre modo oscuro y claro para todo el sistema
# ════════════════════════════════════════════════════════════════════════

CONFIG_DIR="$HOME/.config"
THEME_FILE="$CONFIG_DIR/hypr/.theme-mode"

# Leer tema actual (default: dark)
if [ -f "$THEME_FILE" ]; then
    CURRENT_THEME=$(cat "$THEME_FILE")
else
    CURRENT_THEME="dark"
fi

# ════════════════════════════════════════════════════════════════════════
#  🔇 Modo silent (llamado desde el widget Python)
# ════════════════════════════════════════════════════════════════════════
if [ "$1" = "silent" ] && [ -n "$2" ]; then
    NEW_THEME="$2"
else
    # Rofi menu para seleccionar tema
    CHOICE=$(echo -e "🌙 Dark Mode\n☀️ Light Mode\n🔄 Toggle" | rofi -dmenu -i -p "Select Theme Mode" -theme-str 'window {width: 400px;} listview {lines: 3;}')

    case "$CHOICE" in
        "🌙 Dark Mode")
            NEW_THEME="dark"
            ;;
        "☀️ Light Mode")
            NEW_THEME="light"
            ;;
        "🔄 Toggle")
            if [ "$CURRENT_THEME" = "dark" ]; then
                NEW_THEME="light"
            else
                NEW_THEME="dark"
            fi
            ;;
        *)
            exit 0
            ;;
    esac
fi

# Guardar tema seleccionado (siempre guardar para actualizar timestamp)
echo "$NEW_THEME" > "$THEME_FILE"

# Si no cambió y no es modo silent, salir
if [ "$NEW_THEME" = "$CURRENT_THEME" ] && [ "$1" != "silent" ]; then
    exit 0
fi

# ════════════════════════════════════════════════════════════════════════
#  Aplicar tema a Matugen
# ════════════════════════════════════════════════════════════════════════
MATUGEN_CONFIG="$CONFIG_DIR/matugen/config.toml"
WALLPAPER=$(swww query | grep -oP 'image: \K.*')

if [ -n "$WALLPAPER" ]; then
    if [ "$NEW_THEME" = "light" ]; then
        # Modo claro
        matugen image "$WALLPAPER" -m light
    else
        # Modo oscuro
        matugen image "$WALLPAPER"
    fi
fi

# ════════════════════════════════════════════════════════════════════════
#  Aplicar tema a GTK
# ════════════════════════════════════════════════════════════════════════
if [ "$NEW_THEME" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
fi

# ════════════════════════════════════════════════════════════════════════
#  Recargar componentes
# ════════════════════════════════════════════════════════════════════════

# Recargar Hyprland
hyprctl reload &

# Recargar Waybar
pkill -SIGUSR2 waybar &

# Recargar Kitty
kill -SIGUSR1 $(pidof kitty) 2>/dev/null &

# Notificación
if [ "$NEW_THEME" = "light" ]; then
    notify-send -i weather-clear "Theme Changed" "☀️ Light mode activated" -t 3000
else
    notify-send -i weather-clear-night "Theme Changed" "🌙 Dark mode activated" -t 3000
fi

wait
