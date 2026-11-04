#!/bin/bash
# Captura pantallazos de cada tema y los guarda como preview.png
# Uso: capture-preview.sh [nombre-tema]
#      Sin argumento: captura todos los temas

THEMES_DIR="$HOME/.config/hypr/themes"
APPLY="$HOME/.config/hypr/scripts/apply-theme.sh"
WAIT=4  # Segundos para que el tema se aplique antes de capturar

capture_one() {
    local folder="$1"
    local conf="$THEMES_DIR/$folder/theme.conf"
    local output="$THEMES_DIR/$folder/preview.png"

    if [ ! -f "$conf" ]; then
        echo "⚠ No existe: $conf"
        return 1
    fi

    local name
    name=$(grep "^THEME_NAME=" "$conf" | cut -d'"' -f2)
    echo "→ Aplicando: $name ($folder)"
    bash "$APPLY" "$folder" > /dev/null 2>&1

    echo "  Esperando ${WAIT}s..."
    sleep "$WAIT"

    echo "  Capturando..."
    grim "$output"
    echo "  Guardado: $output"
}

if [ -n "$1" ]; then
    capture_one "$1"
else
    active=$(cat "$HOME/.config/hypr/.active-theme" 2>/dev/null)
    for dir in "$THEMES_DIR"/*/; do
        folder=$(basename "$dir")
        capture_one "$folder"
    done
    # Restaurar tema activo
    if [ -n "$active" ]; then
        echo "→ Restaurando tema activo: $active"
        bash "$APPLY" "$active" > /dev/null 2>&1
    fi
    echo "✓ Previews capturados"
fi
