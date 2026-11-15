# 🌌 Space Hyprland Rice

> **Estado actual (2026-11):** Hyprland 0.57 con config en Lua; matugen, swww y swaync ya no se usan. El estado vigente del sistema, los snapshots y el procedimiento de actualización están en [`docs/sistema-mango.md`](docs/sistema-mango.md). Algunas secciones de abajo describen versiones anteriores.

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
- 🔒 **Bloqueo con video** - Pantalla de bloqueo estilo macOS con video por tema (hyprlock como respaldo)

## 🖼️ Screenshots

> 📸 Próximamente - añadiendo screenshots del setup

## 📦 Instalación

### Requisitos previos

**Verifica las dependencias completas en [DEPENDENCIES.md](DEPENDENCIES.md)**

**Instalación rápida de dependencias:**
```bash
# Paquetes oficiales
sudo pacman -S --needed hyprland waybar rofi kitty swww swaync wlogout \
    hyprlock hypridle brightnessctl pamixer playerctl grim slurp swappy \
    polkit-gnome network-manager-applet blueman hyprpicker zsh \
    ttf-jetbrains-mono-nerd ttf-font-awesome papirus-icon-theme

# Paquetes de AUR (necesitas yay instalado)
yay -S --needed matugen-bin
```

### 🚀 Instalación Automática

```bash
# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/my-hyprland-rice.git
cd my-hyprland-rice

# 2. Ejecutar instalador (hace backup automático)
./install.sh

# 3. Recargar Hyprland o reiniciar sesión
hyprctl reload
# O: Super + Shift + E → Logout
```

### 🔧 Instalación Manual

Si prefieres control total:

```bash
# 1. Backup manual de tus configs
mkdir -p ~/.config-backup
cp -r ~/.config/hypr ~/.config-backup/
cp -r ~/.config/waybar ~/.config-backup/
# ... repetir para cada config

# 2. Copiar configuraciones
cp -r .config/* ~/.config/

# 3. Copiar wallpapers
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers/* ~/Pictures/wallpapers/

# 4. Hacer scripts ejecutables
chmod +x ~/.config/hypr/scripts/*.sh

# 5. Recargar
hyprctl reload
```

## 🎨 Configuración Inicial

### 1. Seleccionar tu primer wallpaper

```bash
# Presiona Super + W para abrir el picker
# O ejecuta manualmente:
~/.config/hypr/scripts/wppicker.sh
```

Matugen generará automáticamente los colores para todo el sistema.

### 2. Descargar más wallpapers

Revisa [WALLPAPERS.md](WALLPAPERS.md) para una lista curada de wallpapers espaciales morados recomendados.

### 3. Ajustar colores base (opcional)

Si quieres una palette morada específica sin depender del wallpaper:

```bash
# Editar colores base
nano ~/.config/hypr/colors-base.conf

# Los colores se usan como fallback o base
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
| `Super + T` | 🪟 Toggle tema Dark/Light (ventana/escena ilustrada con flip 3D) |
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

## 🆕 Nuevas Features

### 🔒 Bloqueo con video
Pantalla de bloqueo propia (`hypr/lockscreen/`, GJS + `Gtk4SessionLock`) con un video en loop según el tema activo:
- En reposo solo muestra hora y fecha; el campo de contraseña aparece al escribir
- Cada tema tiene su diseño: `apilado` (everforest), `telemetria` (crimson-noir), `orbital` (charigod), `horizonte` (catppuccin)
- Video decodificado por VA-API en la iGPU (~5% CPU); la NVIDIA no despierta
- Al desbloquear, el reloj se va, el video frena y el bloqueo se funde con el escritorio (`misc.session_lock_xray` solo se enciende tras autenticar); waybar se relanza y entra con `popin` (regla de capa)
- Verifica con PAM (servicio `hyprlock`, solo `pam_authenticate`); tras 3 fallos hay espera creciente
- Si `lock.js` no logra bloquear o se cae, `scripts/lock.sh` lanza hyprlock
- **Keybind**: `Super + L` (llama `lock.sh` directo, funciona aunque hypridle no esté corriendo); hypridle bloquea a los 5 min
- Pantalla apagada: a los 5.5 min con batería, a los 20 min siempre

**Cómo se elige el tema:** `apply-theme.sh` escribe `lockscreen/theme.json` con `LOCK_LAYOUT`, `LOCK_VIDEO` y la paleta de `themes/<tema>/theme.conf`. Un tema sin `LOCK_VIDEO` usa su wallpaper fijo y el diseño `apilado`.

**Videos:** viven en `~/.local/share/lockscreen/<tema>.mp4` (no van al repo). Para preparar uno nuevo (1080p, tono del tema, loop sin corte):
```bash
~/.config/hypr/scripts/lock-video-prep.sh fuente.mp4 <tema> --tone 65 --stops C1,C2,C3,C4
```
El comando exacto de cada video está comentado en su `theme.conf`.

**Logs y tests:**
```bash
journalctl --user -t lockscreen
cd ~/.config/hypr/lockscreen && gjs -m test/config.test.js
```

### 🔌 Wlogout  
Menú de salida elegante con opciones:
- 🔒 Lock
- 🚪 Logout
- 😴 Suspend
- 💤 Hibernate
- 🔴 Shutdown
- 🔄 Reboot
- **Keybind**: `Super + X`

### 🖥️ Multi-Monitor
Controles para múltiples pantallas:
- `Super + Shift + H/L` - Mover ventana entre monitores
- `Super + Ctrl + Shift + ←/→` - Mover workspace completo
- `Super + Alt + ←/→` - Cambiar foco entre monitores
