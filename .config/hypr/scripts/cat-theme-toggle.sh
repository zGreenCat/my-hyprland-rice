#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🐈 Cat Theme Toggle - Dark/Light con transición circular
#  Alterna entre el tema activo y su COUNTERPART definido en theme.conf
# ════════════════════════════════════════════════════════════════════════

THEMES_DIR="$HOME/.config/hypr/themes"
SCRIPTS="$HOME/.config/hypr/scripts"
ACTIVE_FILE="$HOME/.config/hypr/.active-theme"

ACTIVE=$(cat "$ACTIVE_FILE" 2>/dev/null || echo "catppuccin-mocha-mauve")
THEME_CONF="$THEMES_DIR/$ACTIVE/theme.conf"

if [ ! -f "$THEME_CONF" ]; then
    notify-send "⚠️ Cat Toggle" "Tema activo '$ACTIVE' no encontrado" -t 3000
    exit 1
fi

COUNTERPART=""
while IFS='=' read -r key val; do
    key="${key// /}"
    if [ "$key" = "COUNTERPART" ]; then
        COUNTERPART="${val//\"/}"
        break
    fi
done < "$THEME_CONF"

if [ -z "$COUNTERPART" ] || [ ! -d "$THEMES_DIR/$COUNTERPART" ]; then
    notify-send "⚠️ Cat Toggle" "No hay contraparte para '$ACTIVE'" -t 3000
    exit 1
fi

"$SCRIPTS/apply-theme.sh" "$COUNTERPART"
