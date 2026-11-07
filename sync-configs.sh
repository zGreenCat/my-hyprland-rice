#!/bin/bash
# 🔄 Script para sincronizar configs del sistema a tu repo

# Ruta autodetectada desde la ubicacion del script (igual que apply-configs.sh)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
copy_config "$CONFIG_DIR/hypr/hyprland.lua" "$REPO_DIR/.config/hypr/" "hyprland.lua"
copy_config "$CONFIG_DIR/hypr/colors.lua" "$REPO_DIR/.config/hypr/" "colors.lua"
copy_config "$CONFIG_DIR/hypr/hypridle.conf" "$REPO_DIR/.config/hypr/" "hypridle.conf"
copy_config "$CONFIG_DIR/hypr/hyprlock.conf" "$REPO_DIR/.config/hypr/" "hyprlock.conf"

# Copiar configs individuales (evita sobreescribir accidentalmente)
echo "📁 Hypr configs..."
for file in "$CONFIG_DIR/hypr/configs/"*; do
    [ -f "$file" ] && cp "$file" "$REPO_DIR/.config/hypr/configs/"
done

echo "📁 Hypr scripts..."
for file in "$CONFIG_DIR/hypr/scripts/"*; do
    [ -f "$file" ] && cp "$file" "$REPO_DIR/.config/hypr/scripts/"
done

# Waybar
echo "📁 Waybar..."
[ -d "$CONFIG_DIR/waybar" ] && cp -r "$CONFIG_DIR/waybar/"* "$REPO_DIR/.config/waybar/" 2>/dev/null

# Kitty
echo "📁 Kitty..."
[ -d "$CONFIG_DIR/kitty" ] && cp -r "$CONFIG_DIR/kitty/"* "$REPO_DIR/.config/kitty/" 2>/dev/null

# Rofi
echo "📁 Rofi..."
[ -d "$CONFIG_DIR/rofi" ] && cp -r "$CONFIG_DIR/rofi/"* "$REPO_DIR/.config/rofi/" 2>/dev/null

# SwayNC
echo "📁 SwayNC..."
[ -d "$CONFIG_DIR/swaync" ] && cp -r "$CONFIG_DIR/swaync/"* "$REPO_DIR/.config/swaync/" 2>/dev/null

# Wlogout
echo "📁 Wlogout..."
[ -d "$CONFIG_DIR/wlogout" ] && cp -r "$CONFIG_DIR/wlogout/"* "$REPO_DIR/.config/wlogout/" 2>/dev/null

# Servicios de usuario (systemd)
echo "📁 Systemd user..."
mkdir -p "$REPO_DIR/.config/systemd/user"
for unit in audio-al-pc.service; do
    copy_config "$HOME/.config/systemd/user/$unit" "$REPO_DIR/.config/systemd/user/" "$unit"
done

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
