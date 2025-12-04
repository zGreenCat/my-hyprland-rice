#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🐈 Cat Theme Toggle - Dark/Light con Wallpaper Circular Transition
#  Toggle entre tema oscuro (gato negro) y claro (gato naranjo)
#  con cambio de wallpaper usando swww con efecto circular
# ════════════════════════════════════════════════════════════════════════

CONFIG_DIR="$HOME/.config"
THEME_FILE="$CONFIG_DIR/hypr/.theme-mode"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# ════════════════════════════════════════════════════════════════════════
#  📁 CONFIGURACIÓN DE WALLPAPERS
#  TODO: Cambia estas rutas a tus wallpapers preferidos
# ════════════════════════════════════════════════════════════════════════
DARK_WALLPAPER="$WALLPAPER_DIR/cat-dark.png"      # Wallpaper oscuro
LIGHT_WALLPAPER="$WALLPAPER_DIR/cat-light.png"    # Wallpaper claro

# Si no existen los wallpapers específicos, usar el actual
if [ ! -f "$DARK_WALLPAPER" ]; then
    DARK_WALLPAPER=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
fi
if [ ! -f "$LIGHT_WALLPAPER" ]; then
    LIGHT_WALLPAPER=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
fi

# ════════════════════════════════════════════════════════════════════════
#  📊 LEER TEMA ACTUAL
# ════════════════════════════════════════════════════════════════════════
if [ -f "$THEME_FILE" ]; then
    CURRENT_THEME=$(cat "$THEME_FILE")
else
    CURRENT_THEME="dark"
    echo "$CURRENT_THEME" > "$THEME_FILE"
fi

# ════════════════════════════════════════════════════════════════════════
#  🔄 DETERMINAR NUEVO TEMA
# ════════════════════════════════════════════════════════════════════════
if [ "$1" = "silent" ] && [ -n "$2" ]; then
    NEW_THEME="$2"
else
    # Toggle automático
    if [ "$CURRENT_THEME" = "dark" ]; then
        NEW_THEME="light"
    else
        NEW_THEME="dark"
    fi
fi

# Guardar nuevo tema
echo "$NEW_THEME" > "$THEME_FILE"

# ════════════════════════════════════════════════════════════════════════
#  🖼️ CAMBIAR WALLPAPER CON TRANSICIÓN CIRCULAR (swww)
#  TODO: Ajusta estos parámetros según tu preferencia
# ════════════════════════════════════════════════════════════════════════

# Verificar si swww daemon está corriendo
if ! pgrep -x swww-daemon > /dev/null; then
    # Iniciar daemon si no está corriendo
    swww-daemon &
    sleep 1
fi

# Seleccionar wallpaper según tema
if [ "$NEW_THEME" = "light" ]; then
    WALLPAPER="$LIGHT_WALLPAPER"
else
    WALLPAPER="$DARK_WALLPAPER"
fi

# Aplicar wallpaper con transición circular
# Parámetros de transición:
# - grow: Tipo de transición (circular expanding)
# - 0.5,0.5: Posición del centro (50%, 50% = centro de pantalla)
# - 30: FPS de la animación
# - 1.2: Duración en segundos
# - bezier: Curva de easing para suavizar

swww img "$WALLPAPER" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-fps 60 \
    --transition-duration 1.2 \
    --transition-bezier 0.25,0.1,0.25,1.0 &

# ════════════════════════════════════════════════════════════════════════
#  🎨 APLICAR TEMA A MATUGEN (Generador de colores)
# ════════════════════════════════════════════════════════════════════════
if command -v matugen &> /dev/null && [ -n "$WALLPAPER" ]; then
    if [ "$NEW_THEME" = "light" ]; then
        matugen image "$WALLPAPER" -m light &
    else
        matugen image "$WALLPAPER" &
    fi
fi

# ════════════════════════════════════════════════════════════════════════
#  🖥️ APLICAR TEMA A GTK
#  TODO: Cambia los nombres de temas si usas otros
# ════════════════════════════════════════════════════════════════════════
if [ "$NEW_THEME" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' &
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' &
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' &
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' &
fi

# ════════════════════════════════════════════════════════════════════════
#  🔄 RECARGAR COMPONENTES DEL SISTEMA
# ════════════════════════════════════════════════════════════════════════

# Esperar a que swww termine la transición
sleep 1.3

# Recargar Hyprland (aplica colors.conf generado por matugen)
hyprctl reload &

# Recargar Waybar (aplica colors.css generado por matugen)
pkill -SIGUSR2 waybar &

# Recargar Kitty (aplica colors.conf generado por matugen)
kill -SIGUSR1 $(pidof kitty) 2>/dev/null &

# ════════════════════════════════════════════════════════════════════════
#  🔔 NOTIFICACIÓN
# ════════════════════════════════════════════════════════════════════════
if [ "$NEW_THEME" = "light" ]; then
    notify-send -i weather-clear "Theme Changed" "🐈 Light mode activated" -t 3000 &
else
    notify-send -i weather-clear-night "Theme Changed" "🐈‍⬛ Dark mode activated" -t 3000 &
fi

wait

# ════════════════════════════════════════════════════════════════════════
#  📝 NOTAS DE EXTENSIÓN
# ════════════════════════════════════════════════════════════════════════
# Para añadir más temas (ej. 3+ wallpapers):
# 1. Crear variable de estado con más valores (dark/light/sunset/etc)
# 2. Usar case statement en vez de if/else
# 3. Añadir más wallpapers a las variables de configuración
#
# Ejemplo:
# case "$NEW_THEME" in
#     dark)   WALLPAPER="$DARK_WALLPAPER" ;;
#     light)  WALLPAPER="$LIGHT_WALLPAPER" ;;
#     sunset) WALLPAPER="$SUNSET_WALLPAPER" ;;
# esac
# ════════════════════════════════════════════════════════════════════════
