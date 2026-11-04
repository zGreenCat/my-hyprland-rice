#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🌓 Theme Toggle - Dark/Light via Rofi o silent
#  Uso: theme-toggle.sh [silent dark|light]
# ════════════════════════════════════════════════════════════════════════

THEMES_DIR="$HOME/.config/hypr/themes"
SCRIPTS="$HOME/.config/hypr/scripts"
ACTIVE_FILE="$HOME/.config/hypr/.active-theme"

ACTIVE=$(cat "$ACTIVE_FILE" 2>/dev/null || echo "catppuccin-mocha-mauve")
THEME_CONF="$THEMES_DIR/$ACTIVE/theme.conf"

[ -f "$THEME_CONF" ] && source "$THEME_CONF"

CURRENT_SCHEME="${COLOR_SCHEME:-dark}"

if [ "$1" = "silent" ] && [ -n "$2" ]; then
    REQUESTED="$2"
else
    CHOICE=$(echo -e "🌙 Dark Mode\n☀️ Light Mode\n🔄 Toggle" | \
        rofi -dmenu -i -p "Modo" -theme-str 'window {width: 400px;} listview {lines: 3;}')
    case "$CHOICE" in
        *Dark*)   REQUESTED="dark" ;;
        *Light*)  REQUESTED="light" ;;
        *Toggle*) [ "$CURRENT_SCHEME" = "dark" ] && REQUESTED="light" || REQUESTED="dark" ;;
        *)        exit 0 ;;
    esac
fi

# Si ya está en el modo pedido, no hacer nada
[ "$CURRENT_SCHEME" = "$REQUESTED" ] && exit 0

# Buscar el tema objetivo: si REQUESTED difiere, usar COUNTERPART
if [ "$REQUESTED" != "$CURRENT_SCHEME" ] && [ -n "$COUNTERPART" ] && \
   [ -d "$THEMES_DIR/$COUNTERPART" ]; then
    TARGET="$COUNTERPART"
else
    TARGET="$ACTIVE"
fi

"$SCRIPTS/apply-theme.sh" "$TARGET"
