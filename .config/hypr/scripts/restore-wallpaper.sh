#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🔄 restore-wallpaper.sh — Restaura el wallpaper activo en el arranque
#  Los colores del tema ya persisten en disco (colors.conf, etc.); aquí solo
#  se recupera la imagen. Orden de prioridad:
#    1. ~/.config/hypr/current_wallpaper (symlink al último wallpaper usado)
#    2. WALLPAPER del tema en .active-theme
#    3. Fallback: cat-dark.png
# ════════════════════════════════════════════════════════════════════════

SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
ACTIVE_FILE="$HOME/.config/hypr/.active-theme"
THEMES_DIR="$HOME/.config/hypr/themes"
FALLBACK="$HOME/Pictures/wallpapers/cat-dark.png"

# ─── Resolver wallpaper ──────────────────────────────────────────────────
WALL=""

if [ -L "$SYMLINK_PATH" ] && [ -f "$SYMLINK_PATH" ]; then
    WALL="$(readlink -f "$SYMLINK_PATH")"
fi

if [ -z "$WALL" ] && [ -f "$ACTIVE_FILE" ]; then
    ACTIVE_THEME="$(cat "$ACTIVE_FILE")"
    THEME_CONF="$THEMES_DIR/$ACTIVE_THEME/theme.conf"
    if [ -f "$THEME_CONF" ]; then
        WALLPAPER="$(grep -E '^WALLPAPER=' "$THEME_CONF" | head -1 | cut -d'=' -f2- | tr -d '"')"
        WALLPAPER="${WALLPAPER/#\$HOME/$HOME}"
        WALLPAPER="${WALLPAPER/#\~/$HOME}"
        [ -f "$WALLPAPER" ] && WALL="$WALLPAPER"
    fi
fi

[ -z "$WALL" ] && [ -f "$FALLBACK" ] && WALL="$FALLBACK"
[ -z "$WALL" ] && exit 0

# ─── Asegurar daemon y aplicar ───────────────────────────────────────────
if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon &
    sleep 0.5
fi

awww img "$WALL" --transition-type none

# Mantener el symlink apuntando a lo aplicado
ln -sf "$WALL" "$SYMLINK_PATH"
