#!/bin/bash
# 🔄 Script para sincronizar configs del sistema a tu repo

REPO_DIR="/home/zgreencat/rice_repos/arch-hyprland/my-hyprland-rice"
CONFIG_DIR="$HOME/.config"

echo "🔄 Sincronizando configuraciones del sistema al repo..."
echo ""

# Función para copiar con feedback
copy_config() {
    local source=$1
    local dest=$2
    local name=$3
    
    if [ -d "$source" ] || [ -f "$source" ]; then
        cp -r "$source" "$dest"
        echo "✅ $name copiado"
    else
        echo "⚠️  $name no encontrado en el sistema"
    fi
}

# Hyprland
echo "📁 Hyprland..."
copy_config "$CONFIG_DIR/hypr/hyprland.conf" "$REPO_DIR/.config/hypr/" "hyprland.conf"
copy_config "$CONFIG_DIR/hypr/colors.conf" "$REPO_DIR/.config/hypr/" "colors.conf"
copy_config "$CONFIG_DIR/hypr/hypridle.conf" "$REPO_DIR/.config/hypr/" "hypridle.conf"
copy_config "$CONFIG_DIR/hypr/hyprlock.conf" "$REPO_DIR/.config/hypr/" "hyprlock.conf"
copy_config "$CONFIG_DIR/hypr/configs/"* "$REPO_DIR/.config/hypr/configs/" "configs/"
copy_config "$CONFIG_DIR/hypr/scripts/"* "$REPO_DIR/.config/hypr/scripts/" "scripts/"

# Waybar
echo "📁 Waybar..."
copy_config "$CONFIG_DIR/waybar/"* "$REPO_DIR/.config/waybar/" "waybar"

# Kitty
echo "📁 Kitty..."
copy_config "$CONFIG_DIR/kitty/"* "$REPO_DIR/.config/kitty/" "kitty"

# Rofi
echo "📁 Rofi..."
copy_config "$CONFIG_DIR/rofi/"* "$REPO_DIR/.config/rofi/" "rofi"

# Matugen
echo "📁 Matugen..."
copy_config "$CONFIG_DIR/matugen/"* "$REPO_DIR/.config/matugen/" "matugen"

# SwayNC
echo "📁 SwayNC..."
copy_config "$CONFIG_DIR/swaync/"* "$REPO_DIR/.config/swaync/" "swaync"

# Wlogout
echo "📁 Wlogout..."
copy_config "$CONFIG_DIR/wlogout/"* "$REPO_DIR/.config/wlogout/" "wlogout"

# Zshrc
echo "📁 Shell..."
copy_config "$HOME/.zshrc" "$REPO_DIR/" ".zshrc"

echo ""
echo "📊 Estado del repositorio:"
cd "$REPO_DIR"
git status --short

echo ""
echo "✨ Sincronización completada!"
echo ""
echo "💡 Siguiente paso:"
echo "   cd $REPO_DIR"
echo "   git diff          # Ver cambios"
echo "   git add ."
echo "   git commit -m 'Update: sincronización de configs'"
echo "   git push"
