#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🎨 Quick Theme Switcher
#  Cambia rápidamente entre variantes de tu tema espacial
# ════════════════════════════════════════════════════════════════════════

THEMES_DIR="$HOME/.config/hypr/themes"
CURRENT_THEME_FILE="$HOME/.cache/current-theme"

# Crear directorio de temas si no existe
mkdir -p "$THEMES_DIR"

# Temas disponibles
THEMES=(
    "deep-space:Espacio profundo (más oscuro)"
    "nebula:Nebulosa (morado medio)"
    "cosmic:Cósmico (más claro)"
    "lofi:Lofi Space (pastel)"
)

apply_theme() {
    local theme=$1
    
    case $theme in
        "deep-space")
            # Tema muy oscuro
            hyprctl keyword general:col.active_border "rgb(7b2cbf) rgb(5a189a) rgb(240046) 45deg"
            hyprctl keyword general:col.inactive_border "rgb(10002b)"
            hyprctl keyword decoration:active_opacity "0.95"
            hyprctl keyword decoration:inactive_opacity "0.80"
            hyprctl keyword decoration:dim_strength "0.08"
            ;;
        "nebula")
            # Tema morado medio (default)
            hyprctl keyword general:col.active_border "rgb(c77dff) rgb(7b2cbf) rgb(5a189a) 45deg"
            hyprctl keyword general:col.inactive_border "rgb(240046)"
            hyprctl keyword decoration:active_opacity "0.98"
            hyprctl keyword decoration:inactive_opacity "0.85"
            hyprctl keyword decoration:dim_strength "0.05"
            ;;
        "cosmic")
            # Tema más claro
            hyprctl keyword general:col.active_border "rgb(e0aaff) rgb(c77dff) rgb(9d4edd) 45deg"
            hyprctl keyword general:col.inactive_border "rgb(5a189a)"
            hyprctl keyword decoration:active_opacity "1.0"
            hyprctl keyword decoration:inactive_opacity "0.90"
            hyprctl keyword decoration:dim_strength "0.03"
            ;;
        "lofi")
            # Tema lofi pastel
            hyprctl keyword general:col.active_border "rgb(b19cd9) rgb(a480cf) rgb(8e7cc3) 45deg"
            hyprctl keyword general:col.inactive_border "rgb(4a4063)"
            hyprctl keyword decoration:active_opacity "0.96"
            hyprctl keyword decoration:inactive_opacity "0.88"
            hyprctl keyword decoration:dim_strength "0.04"
            ;;
    esac
    
    # Guardar tema actual
    echo "$theme" > "$CURRENT_THEME_FILE"
    
    # Notificar
    local theme_name=$(get_theme_name "$theme")
    notify-send -i ~/.config/swaync/icons/palette.png "🎨 Tema aplicado" \
        "$theme_name" -t 2000
}

get_theme_name() {
    local theme=$1
    for t in "${THEMES[@]}"; do
        if [[ $t == "$theme:"* ]]; then
            echo "${t#*:}"
            return
        fi
    done
}

show_menu() {
    local options=""
    for t in "${THEMES[@]}"; do
        local name="${t%%:*}"
        local desc="${t#*:}"
        options+="$desc\n"
    done
    
    # Mostrar menú con rofi
    local selected=$(echo -e "$options" | rofi -dmenu -i -p "Selecciona tema espacial")
    
    # Aplicar tema seleccionado
    for t in "${THEMES[@]}"; do
        local desc="${t#*:}"
        if [[ "$selected" == "$desc" ]]; then
            local theme="${t%%:*}"
            apply_theme "$theme"
            return
        fi
    done
}

# Mostrar menú
show_menu
