# 🌌 Space Hyprland Rice - Dependencies

## 📦 Paquetes Esenciales

### Compositor y Base
```bash
sudo pacman -S hyprland waybar rofi kitty
```

### Gestión de Wallpapers y Colores
```bash
sudo pacman -S swww
yay -S matugen-bin  # Generador de colores desde wallpaper
```

### Notificaciones y Lockscreen
```bash
sudo pacman -S swaync wlogout hyprlock hypridle
```

### Utilidades de Sistema
```bash
sudo pacman -S brightnessctl pamixer playerctl
sudo pacman -S grim slurp swappy  # Screenshots
sudo pacman -S polkit-gnome       # Permisos
sudo pacman -S network-manager-applet blueman  # Systray
sudo pacman -S hyprpicker         # Color picker
```

### Terminal y Shell
```bash
sudo pacman -S zsh
yay -S zsh-autosuggestions zsh-syntax-highlighting
```

### Extras Opcionales
```bash
sudo pacman -S fastfetch cava     # Info del sistema y audio visualizer
sudo pacman -S nautilus           # File manager
sudo pacman -S firefox            # Browser
```

## 🎨 Fuentes e Iconos

```bash
# Fuentes Nerd para los iconos
sudo pacman -S ttf-jetbrains-mono-nerd ttf-font-awesome

# Iconos para GTK
sudo pacman -S papirus-icon-theme
```

## ✅ Verificar Instalación

```bash
# Verificar que todo esté instalado
which hyprland waybar rofi kitty matugen swww swaync hyprlock

# Si algo falta, te dirá command not found
```

## 🚀 Instalación Rápida (todo de una vez)

```bash
# Paquetes oficiales
sudo pacman -S --needed hyprland waybar rofi kitty swww swaync wlogout \
    hyprlock hypridle brightnessctl pamixer playerctl grim slurp swappy \
    polkit-gnome network-manager-applet blueman hyprpicker zsh \
    ttf-jetbrains-mono-nerd ttf-font-awesome papirus-icon-theme \
    fastfetch cava nautilus firefox

# Paquetes de AUR (necesitas yay)
yay -S --needed matugen-bin zsh-autosuggestions zsh-syntax-highlighting
```

## 📝 Notas

- **matugen**: Genera automáticamente colores desde tus wallpapers
- **swww**: Backend moderno para wallpapers (reemplaza hyprpaper)
- **swaync**: Centro de notificaciones más bonito que dunst
- **hyprpicker**: Para copiar colores de cualquier parte de la pantalla
- **swappy**: Editor de screenshots tipo paint

## 🔧 Post-Instalación

```bash
# Configurar zsh como shell por defecto
chsh -s $(which zsh)

# Instalar Oh My Zsh (opcional pero recomendado)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
