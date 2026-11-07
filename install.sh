#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🌌 Space Theme Initializer
#  Configura el tema espacial morado en tu sistema
# ════════════════════════════════════════════════════════════════════════

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🌌 Instalando Space Hyprland Rice                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Función para hacer backup
backup_config() {
    local config=$1
    if [ -e "$CONFIG_DIR/$config" ]; then
        echo "📦 Haciendo backup de $config..."
        mv "$CONFIG_DIR/$config" "$CONFIG_DIR/${config}.backup-$(date +%Y%m%d-%H%M%S)"
    fi
}

# Función para copiar configs
copy_config() {
    local config=$1
    echo "📁 Copiando $config..."
    cp -r "$REPO_DIR/.config/$config" "$CONFIG_DIR/"
}

# Crear directorios necesarios
echo "📂 Creando directorios..."
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/.config

# Backup de configs existentes
echo ""
echo "🔒 Haciendo backup de configuraciones existentes..."
backup_config "hypr"
backup_config "waybar"
backup_config "kitty"
backup_config "rofi"
backup_config "swaync"
backup_config "wlogout"

# Copiar nuevas configs
echo ""
echo "📋 Instalando configuraciones..."
copy_config "hypr"
copy_config "waybar"
copy_config "kitty"
copy_config "rofi"
copy_config "swaync"
copy_config "wlogout"

# Copiar wallpapers
echo ""
echo "🖼️  Copiando wallpapers..."
cp -r "$REPO_DIR/wallpapers/"* ~/Pictures/wallpapers/ 2>/dev/null || true

# Hacer scripts ejecutables
echo ""
echo "🔧 Configurando scripts..."
chmod +x ~/.config/hypr/scripts/*.sh

# Copiar zshrc si existe
if [ -f "$REPO_DIR/.zshrc" ]; then
    echo ""
    read -p "¿Copiar .zshrc? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d-%H%M%S)
        cp "$REPO_DIR/.zshrc" ~/
        echo "✅ .zshrc copiado"
    fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✨ Instalación completada!                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Verificar dependencias:"
echo "   cat $REPO_DIR/DEPENDENCIES.md"
echo ""
echo "2. Recargar Hyprland:"
echo "   hyprctl reload"
echo ""
echo "3. O reiniciar sesión:"
echo "   Super + Shift + E → Logout"
echo ""
echo "4. Seleccionar un wallpaper:"
echo "   Super + W"
echo ""
echo "5. Los backups están en ~/.config/*.backup-*"
echo ""
echo "🌌 ¡Disfruta tu nuevo rice espacial!"
