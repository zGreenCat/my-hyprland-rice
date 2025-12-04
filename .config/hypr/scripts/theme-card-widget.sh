#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🌓 Theme Card Widget - Ventana flotante con toggle animado
#  Abre una ventana GTK con el toggle visual de tema dark/light
# ════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$HOME/.config/hypr/scripts"
HTML_FILE="$SCRIPT_DIR/theme-card.html"
THEME_FILE="$HOME/.config/hypr/.theme-mode"

# Verificar si el HTML existe
if [ ! -f "$HTML_FILE" ]; then
    notify-send "Error" "Theme card HTML not found" -u critical
    exit 1
fi

# Obtener tema actual
CURRENT_THEME="dark"
if [ -f "$THEME_FILE" ]; then
    CURRENT_THEME=$(cat "$THEME_FILE")
fi

# ════════════════════════════════════════════════════════════════════════
#  🖼️ Abrir ventana flotante con el widget
# ════════════════════════════════════════════════════════════════════════

# Opción 1: Usar xdg-open con chromium/firefox en modo app
if command -v chromium &> /dev/null; then
    chromium \
        --app="file://$HTML_FILE" \
        --window-size=200,200 \
        --window-position=center \
        --class="theme-card-widget" \
        --new-window \
        &
    
    WIDGET_PID=$!
    
    # Esperar a que la ventana aparezca
    sleep 0.5
    
    # Aplicar reglas de Hyprland
    hyprctl dispatch focuswindow "class:theme-card-widget"
    
elif command -v firefox &> /dev/null; then
    firefox \
        --new-window "file://$HTML_FILE" \
        --class="theme-card-widget" \
        &
    
    WIDGET_PID=$!
    sleep 0.5
    hyprctl dispatch focuswindow "class:theme-card-widget"
    
else
    # Fallback: usar yad si está disponible
    if command -v yad &> /dev/null; then
        yad --html \
            --uri="file://$HTML_FILE" \
            --width=200 \
            --height=200 \
            --center \
            --undecorated \
            --skip-taskbar \
            --on-top \
            --title="Theme Toggle" \
            --class="theme-card-widget" \
            &
        WIDGET_PID=$!
    else
        notify-send "Error" "No supported browser found (chromium/firefox/yad)" -u critical
        exit 1
    fi
fi

# ════════════════════════════════════════════════════════════════════════
#  🔄 Monitorear clicks en el widget (opcional)
# ════════════════════════════════════════════════════════════════════════

# Nota: El HTML tiene un custom protocol handler (theme-toggle://)
# que podríamos interceptar, pero por ahora usaremos detección de archivo

# Loop para detectar cambios en el archivo de tema
LAST_THEME="$CURRENT_THEME"

while kill -0 $WIDGET_PID 2>/dev/null; do
    sleep 0.3
    
    if [ -f "$THEME_FILE" ]; then
        NEW_THEME=$(cat "$THEME_FILE")
        
        if [ "$NEW_THEME" != "$LAST_THEME" ]; then
            # El usuario hizo click en el widget
            $SCRIPT_DIR/theme-toggle.sh silent "$NEW_THEME"
            LAST_THEME="$NEW_THEME"
        fi
    fi
done
