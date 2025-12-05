#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  🚀 Script para aplicar configs del repo al sistema
#  Sincroniza cambios del repositorio a ~/.config/
# ═══════════════════════════════════════════════════════════════════

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🚀 Aplicando configuraciones del repo al sistema         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 Repositorio: $REPO_DIR"
echo "📁 Destino: $CONFIG_DIR"
echo ""

# Función para copiar con feedback
apply_config() {
    local source=$1
    local dest=$2
    local name=$3
    
    if [ -d "$source" ] || [ -f "$source" ]; then
        cp -r "$source" "$dest"
        echo "✅ $name aplicado"
    else
        echo "⚠️  $name no encontrado en el repo"
    fi
}

# ═══════════════════════════════════════════════════════════════════
#  COPIAR CONFIGURACIONES
# ═══════════════════════════════════════════════════════════════════

# Hyprland
echo "📁 Hyprland..."
apply_config "$REPO_DIR/.config/hypr" "$CONFIG_DIR/" "hypr"

# Waybar
echo "📁 Waybar..."
apply_config "$REPO_DIR/.config/waybar" "$CONFIG_DIR/" "waybar"

# Kitty
echo "📁 Kitty..."
apply_config "$REPO_DIR/.config/kitty" "$CONFIG_DIR/" "kitty"

# Rofi
echo "📁 Rofi..."
apply_config "$REPO_DIR/.config/rofi" "$CONFIG_DIR/" "rofi"

# Matugen
echo "📁 Matugen..."
apply_config "$REPO_DIR/.config/matugen" "$CONFIG_DIR/" "matugen"

# SwayNC
echo "📁 SwayNC..."
apply_config "$REPO_DIR/.config/swaync" "$CONFIG_DIR/" "swaync"

# Wlogout
echo "📁 Wlogout..."
apply_config "$REPO_DIR/.config/wlogout" "$CONFIG_DIR/" "wlogout"

# Otros configs opcionales
echo "📁 Configs adicionales..."
[ -d "$REPO_DIR/.config/btop" ] && apply_config "$REPO_DIR/.config/btop" "$CONFIG_DIR/" "btop"
[ -d "$REPO_DIR/.config/cava" ] && apply_config "$REPO_DIR/.config/cava" "$CONFIG_DIR/" "cava"

echo ""

# ═══════════════════════════════════════════════════════════════════
#  HACER SCRIPTS EJECUTABLES
# ═══════════════════════════════════════════════════════════════════

echo "🔧 Configurando permisos de scripts..."
if [ -d "$CONFIG_DIR/hypr/scripts" ]; then
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.py 2>/dev/null
    echo "✅ Scripts de Hyprland ejecutables"
fi

if [ -d "$CONFIG_DIR/waybar/scripts" ]; then
    chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null
    chmod +x "$CONFIG_DIR/waybar/scripts/"*.py 2>/dev/null
    echo "✅ Scripts de Waybar ejecutables"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
#  RECARGAR SERVICIOS
# ═══════════════════════════════════════════════════════════════════

echo "🔄 Recargando servicios..."

# Recargar Hyprland config
if command -v hyprctl &> /dev/null; then
    hyprctl reload 2>/dev/null && echo "✅ Hyprland recargado" || echo "⚠️  Hyprland no recargado (puede requerir reinicio de sesión)"
else
    echo "⚠️  hyprctl no encontrado - salta recarga de Hyprland"
fi

# Recargar Waybar
if pgrep -x waybar > /dev/null; then
    killall waybar 2>/dev/null
    sleep 0.5
    waybar &>/dev/null &
    echo "✅ Waybar reiniciado"
else
    echo "ℹ️  Waybar no está corriendo"
fi

# Recargar SwayNC si está corriendo
if pgrep -x swaync > /dev/null; then
    killall swaync 2>/dev/null
    sleep 0.5
    swaync &>/dev/null &
    echo "✅ SwayNC reiniciado"
else
    echo "ℹ️  SwayNC no está corriendo"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
#  RESUMEN
# ═══════════════════════════════════════════════════════════════════

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✨ Configuraciones aplicadas exitosamente!               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💡 Comandos útiles:"
echo "   Super + T          - Probar cat theme toggle"
echo "   Super + W          - Selector de wallpapers"
echo "   Super + R          - Reiniciar waybar manualmente"
echo ""
echo "   Si algo no funciona, reinicia la sesión:"
echo "   Super + Shift + E  - Cerrar sesión"
echo ""
