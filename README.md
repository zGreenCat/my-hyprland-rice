# 🌌 Space Hyprland Rice

> *Un rice personalizado de Hyprland con temática espacial/lofi y generación dinámica de colores*

Rice minimalista y elegante inspirado en el cosmos, con animaciones suaves y colores que se adaptan automáticamente a tus wallpapers. Diseñado para productividad sin sacrificar estética.

## ✨ Características

- 🎨 **Colores dinámicos** - Matugen genera paletas automáticamente desde tus wallpapers
- 🌌 **Temática espacial** - Wallpapers del universo, planetas y estética lofi
- 💜 **Palette morada** - Base en tonos morados con transiciones suaves
- 🎭 **Animaciones espaciales** - Movimientos fluidos y elegantes
- 🔧 **Scripts útiles** - Picker de wallpapers, control de volumen/brillo, screenshots
- 📊 **Waybar personalizado** - Múltiples layouts y estilos intercambiables
- 🔔 **SwayNC** - Centro de notificaciones moderno
- 🔒 **Hyprlock** - Pantalla de bloqueo integrada

## 🖼️ Screenshots

> 📸 Próximamente - añadiendo screenshots del setup

## 📦 Instalación

### Requisitos previos

Ver archivo [DEPENDENCIES.md](DEPENDENCIES.md) para la lista completa de dependencias.

**Instalación rápida de dependencias:**
```bash
# Paquetes oficiales
sudo pacman -S --needed hyprland waybar rofi kitty swww swaync wlogout \
    hyprlock hypridle brightnessctl pamixer playerctl grim slurp swappy \
    polkit-gnome network-manager-applet blueman hyprpicker

# Paquetes de AUR
yay -S --needed matugen-bin
```

### Instalación del rice

```bash
# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/my-hyprland-rice.git
cd my-hyprland-rice

# 2. Hacer backup de tus configs actuales (importante!)
mkdir -p ~/.config-backup
cp -r ~/.config/hypr ~/.config-backup/
cp -r ~/.config/waybar ~/.config-backup/
# ... repetir para cada config que quieras respaldar

# 3. Copiar configuraciones
cp -r .config/* ~/.config/

# 4. Copiar wallpapers
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers/* ~/Pictures/wallpapers/

# 5. Recargar Hyprland
hyprctl reload
```

## ⌨️ Keybindings

### Básicos
| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abrir terminal (kitty) |
| `Super + D` | Lanzador de apps (rofi) |
| `Super + Q` | Cerrar ventana |
| `Super + E` | Explorador de archivos |
| `Super + L` | Bloquear pantalla |
| `Super + X` | Menú de salida (wlogout) |

### Navegación de ventanas
| Atajo | Acción |
|-------|--------|
| `Super + ←/→/↑/↓` | Mover foco entre ventanas |
| `Super + Ctrl + ←/→/↑/↓` | Mover ventana |
| `Super + Shift + ←/→/↑/↓` | Redimensionar ventana |
| `Super + V` / `Super + Space` | Toggle floating |
| `Super + F` | Fullscreen |

### Workspaces
| Atajo | Acción |
|-------|--------|
| `Super + 1-9` | Cambiar a workspace 1-9 |
| `Super + Shift + 1-9` | Mover ventana a workspace 1-9 |
| `Super + Mouse wheel` | Navegar entre workspaces |

### Utilidades
| Atajo | Acción |
|-------|--------|
| `Print` | Screenshot de área (con edición) |
| `Super + Print` | Screenshot completa |
| `Super + W` | Selector de wallpapers |
| `Super + C` | Color picker |
| `Super + N` | Toggle notificaciones |
| `Super + Shift + N` | Borrar notificaciones |
| `Super + R` | Reiniciar waybar |
| `Super + Ctrl + B` | Cambiar estilo waybar |
| `Super + Alt + B` | Cambiar layout waybar |

### Multimedia
| Atajo | Acción |
|-------|--------|
| `XF86AudioRaiseVolume` | Subir volumen |
| `XF86AudioLowerVolume` | Bajar volumen |
| `XF86AudioMute` | Mutear audio |
| `XF86MonBrightnessUp` | Subir brillo |
| `XF86MonBrightnessDown` | Bajar brillo |
| `XF86AudioPlay/Pause` | Play/Pause |
| `XF86AudioNext/Prev` | Siguiente/Anterior |

## 🎨 Personalización

### Cambiar colores base

Edita `~/.config/hypr/colors.conf` para ajustar la paleta morada base.

### Añadir wallpapers

```bash
# Copiar tus wallpapers espaciales
cp tus-wallpapers/* ~/Pictures/wallpapers/

# Usar el picker (Super + W) para seleccionar uno
# Matugen generará los colores automáticamente
```

### Cambiar estilos de waybar

```bash
# Durante la sesión
Super + Ctrl + B  # Menú de estilos

# Estilos disponibles:
# - islands: Módulos flotantes estilo isla
# - bintang default: Estilo compacto
# - full bar: Barra completa
```

## 🔧 Scripts Incluidos

- `wppicker.sh` - Selector de wallpapers con preview y generación de colores
- `volume.sh` - Control de volumen con notificaciones
- `brightness.sh` - Control de brillo con notificaciones
- `screenshot.sh` - Capturas de pantalla con selección de área
- `WaybarStyles.sh` - Cambiar estilos de waybar
- `WaybarLayout.sh` - Cambiar layouts de waybar
- `sync-configs.sh` - Sincronizar configs del sistema al repo

## 🛠️ Mantenimiento

### Sincronizar cambios del sistema al repo

```bash
# Después de hacer cambios en tus configs
cd ~/my-hyprland-rice
./sync-configs.sh

# Revisar cambios
git diff

# Commitear y pushear
git add .
git commit -m "Update: descripción de cambios"
git push
```

## 🙏 Créditos

- Inspirado en configuraciones de [JaKooLit](https://github.com/JaKooLit)
- Basado en el rice [arch-hyprland](https://github.com/binnewbs/arch-hyprland)
- Comunidad de [Hyprland](https://hyprland.org)

## 📝 Licencia

Este proyecto es de uso libre. Siéntete libre de usar, modificar y compartir.

---

⭐ Si te gusta este rice, dale una estrella al repo!
