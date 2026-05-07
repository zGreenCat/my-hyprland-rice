# 🔍 Auditoría Completa — Space Hyprland Rice

> **Autor:** zGreenCat  
> **Sistema:** Arch Linux + Wayland  
> **Compositor:** Hyprland  
> **Fecha de Auditoría:** 12 de Marzo de 2026  
> **Repositorio:** `my-hyprland-rice`

---

## 📋 Tabla de Contenidos

1. [¿Qué es este proyecto?](#1-qué-es-este-proyecto)
2. [Arquitectura General](#2-arquitectura-general)
3. [Stack Tecnológico](#3-stack-tecnológico)
4. [Componentes Principales](#4-componentes-principales)
   - 4.1 [Hyprland — Compositor Wayland](#41-hyprland--compositor-wayland)
   - 4.2 [Waybar — Barra de Estado](#42-waybar--barra-de-estado)
   - 4.3 [Rofi — Lanzador de Aplicaciones](#43-rofi--lanzador-de-aplicaciones)
   - 4.4 [Kitty — Emulador de Terminal](#44-kitty--emulador-de-terminal)
   - 4.5 [swww — Gestor de Wallpapers](#45-swww--gestor-de-wallpapers)
   - 4.6 [Matugen — Sistema de Colores Dinámicos](#46-matugen--sistema-de-colores-dinámicos)
   - 4.7 [SwayNC — Centro de Notificaciones](#47-swaync--centro-de-notificaciones)
   - 4.8 [Hyprlock — Pantalla de Bloqueo](#48-hyprlock--pantalla-de-bloqueo)
   - 4.9 [Hypridle — Gestión de Inactividad](#49-hypridle--gestión-de-inactividad)
   - 4.10 [Wlogout — Menú de Salida](#410-wlogout--menú-de-salida)
5. [Feature Estrella: Cat Theme Toggle](#5-feature-estrella-cat-theme-toggle)
6. [Sistema de Colores y Paletas](#6-sistema-de-colores-y-paletas)
7. [Scripts Personalizados](#7-scripts-personalizados)
8. [Keybindings Completos](#8-keybindings-completos)
9. [Animaciones y Efectos Visuales](#9-animaciones-y-efectos-visuales)
10. [Gestión de Wallpapers](#10-gestión-de-wallpapers)
11. [Estructura de Archivos del Repo](#11-estructura-de-archivos-del-repo)
12. [Dependencias Completas](#12-dependencias-completas)
13. [Flujos de Trabajo y Mantenimiento](#13-flujos-de-trabajo-y-mantenimiento)
14. [Personalización Avanzada](#14-personalización-avanzada)
15. [Historial de Versiones](#15-historial-de-versiones)
16. [Problemas Conocidos y TODOs](#16-problemas-conocidos-y-todos)
17. [Evaluación del Proyecto](#17-evaluación-del-proyecto)

---

## 1. ¿Qué es este proyecto?

**Space Hyprland Rice** es una configuración completa y minimalista del entorno de escritorio de **Arch Linux con Wayland**, centrada en el compositor de ventanas **Hyprland**. El término "rice" (del slang de UNIX) refiere al arte de personalizar un entorno Linux hasta el máximo nivel estético y funcional.

### Filosofía del Proyecto

| Principio | Descripción |
|-----------|-------------|
| **Estética espacial/lofi** | Paleta base morada oscura inspirada en el cosmos y el arte lofi |
| **Colores dinámicos** | El sistema de color completo se genera automáticamente desde el wallpaper activo |
| **Modularidad** | Configuraciones separadas por función para fácil mantenimiento |
| **Productividad + Belleza** | Balance entre rendimiento real y efectos visuales de alta calidad |
| **Documentación** | Cada feature está documentada con guías de uso y personalización |

### Contexto de Sistema

```
OS:         Arch Linux (rolling release)
Display:    Wayland (no X11)
Compositor: Hyprland (tiling/floating WM)
Shell:      Zsh (con Oh My Zsh)
Terminal:   Kitty
Bar:        Waybar
Launcher:   Rofi
Notifs:     SwayNC
Lock:       Hyprlock
Idle:       Hypridle
Wallpaper:  swww
Colors:     Matugen (generación dinámica desde wallpaper)
```

---

## 2. Arquitectura General

El proyecto sigue una arquitectura en capas donde cada componente tiene responsabilidades bien definidas:

```
┌──────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                       │
│  Waybar (barra)  │  Rofi (launcher)  │  Kitty (terminal)    │
│  SwayNC (notifs) │  Wlogout (sesión) │  Hyprlock (lock)     │
├──────────────────────────────────────────────────────────────┤
│                 CAPA DE COMPOSITOR (Hyprland)                 │
│  Tiling  │  Floating  │  Workspaces  │  Keybindings          │
│  Reglas de ventanas   │  Animaciones │  Multi-monitor        │
├──────────────────────────────────────────────────────────────┤
│                  CAPA DE THEMING                              │
│  Matugen (color gen)  │  swww (wallpaper)  │  GTK Theme      │
│  Colores dinámicos    │  Templates         │  Recargas auto   │
├──────────────────────────────────────────────────────────────┤
│                  CAPA DE SCRIPTS                              │
│  wppicker.sh  │  cat-theme-toggle.sh  │  volume.sh           │
│  brightness.sh│  screenshot.sh        │  WaybarStyles.sh     │
│  sync-configs.sh      │  wallpaper-rotation.sh               │
└──────────────────────────────────────────────────────────────┘
```

### Flujo de Datos del Sistema de Color

```
Wallpaper seleccionado (jpg/png)
         │
         ▼
   matugen image $WALLPAPER
         │
         ▼
  Paleta de colores generada
  (JSON/variables CSS/conf)
         │
    ┌────┴────────────────────────────────────┐
    ▼         ▼          ▼          ▼         ▼
  Hyprland  Waybar    Kitty      Rofi     SwayNC
  colors.conf style.css kitty.conf theme    config
         │
         ▼
  Post-hook: hyprctl reload + pkill waybar
```

---

## 3. Stack Tecnológico

### Nivel 1 — Core del Sistema

| Tecnología | Versión/Paquete | Rol |
|------------|-----------------|-----|
| Arch Linux | rolling | Sistema operativo base |
| Wayland | protocolo | Display server (no X11) |
| Hyprland | `hyprland` (pacman) | Compositor de ventanas tiling |
| Zsh | `zsh` | Shell principal |

### Nivel 2 — Entorno Visual

| Tecnología | Paquete | Rol |
|------------|---------|-----|
| Waybar | `waybar` | Barra de estado superior |
| Kitty | `kitty` | Terminal GPU-accelerated |
| Rofi | `rofi` | App launcher y menús |
| SwayNC | `swaync` | Centro de notificaciones |
| Wlogout | `wlogout` | Menú de cierre de sesión |
| Hyprlock | `hyprlock` | Pantalla de bloqueo |
| Hypridle | `hypridle` | Daemon de inactividad |

### Nivel 3 — Theming

| Tecnología | Paquete | Rol |
|------------|---------|-----|
| swww | `swww` | Gestor de wallpapers (reemplaza hyprpaper) |
| Matugen | `matugen-bin` (AUR) | Generación de paletas desde wallpaper |
| Papirus | `papirus-icon-theme` | Iconos para GTK/Waybar |
| JetBrains Mono Nerd | `ttf-jetbrains-mono-nerd` | Fuente con iconos |
| Font Awesome | `ttf-font-awesome` | Iconos adicionales |

### Nivel 4 — Utilidades de Sistema

| Tecnología | Paquete | Rol |
|------------|---------|-----|
| brightnessctl | `brightnessctl` | Control de brillo de pantalla |
| pamixer | `pamixer` | Control de volumen PulseAudio |
| playerctl | `playerctl` | Control de reproductores multimedia |
| grim | `grim` | Captura de pantalla (Wayland) |
| slurp | `slurp` | Selección de área en pantalla |
| swappy | `swappy` | Editor de screenshots |
| hyprpicker | `hyprpicker` | Color picker de pantalla |
| polkit-gnome | `polkit-gnome` | Agente de permisos |
| network-manager-applet | `network-manager-applet` | Tray de red |
| blueman | `blueman` | Gestión de Bluetooth |

### Nivel 5 — Extras/Opcionales

| Tecnología | Paquete | Rol |
|------------|---------|-----|
| fastfetch | `fastfetch` | Info del sistema (neofetch moderno) |
| cava | `cava` | Visualizador de audio |
| nautilus | `nautilus` | Explorador de archivos |

### Nivel 6 — Widget Especial (Cat Theme Toggle)

| Tecnología | Paquete | Rol |
|------------|---------|-----|
| Python3 + GTK3 | `python-gobject`, `gtk3` | Launcher del widget |
| WebKit2 | `webkit2gtk` | Renderizado de HTML/CSS en ventana GTK |
| HTML5/CSS3 | N/A | UI del toggle con animaciones 3D |

---

## 4. Componentes Principales

### 4.1 Hyprland — Compositor Wayland

**Hyprland** es el corazón del sistema. Es un compositor Wayland de alto rendimiento que soporta tiling dinámico, floating, y efectos visuales avanzados.

#### Estructura de Configuración

Las configuraciones de Hyprland están organizadas de forma modular en `~/.config/hypr/`:

```
~/.config/hypr/
├── hyprland.conf          # Config principal (hace source de los demás)
├── colors.conf            # Colores actuales (generados por Matugen)
├── colors-base.conf       # Paleta morada base (fallback manual)
├── hypridle.conf          # Config del daemon de inactividad
├── hyprlock.conf          # Config de la pantalla de bloqueo
├── .theme-mode            # Estado actual del tema (dark/light)
├── configs/
│   ├── keybinds.conf      # Todos los atajos de teclado
│   ├── looknfeel.conf     # Aspecto visual: gaps, blur, sombras, bordes
│   ├── UserAnimations.conf# Animaciones personalizadas y bezier curves
│   ├── windowrules.conf   # Reglas por aplicación/clase
│   ├── tags.conf          # Workspaces y sus propiedades
│   └── monitors.conf      # Config de pantallas
└── scripts/
    ├── wppicker.sh         # Selector de wallpapers con preview
    ├── volume.sh           # Control de volumen con notificaciones
    ├── brightness.sh       # Control de brillo con notificaciones
    ├── screenshot.sh       # Captura de pantalla
    ├── WaybarStyles.sh     # Cambiar estilos de la barra
    ├── WaybarLayout.sh     # Cambiar layout de la barra
    ├── wallpaper-rotation.sh # Rotación automática de wallpapers
    ├── theme-switcher.sh   # Cambiador de 4 variantes de tema
    ├── cat-theme-toggle.sh # Toggle Dark/Light Mode
    └── cat-theme-widget.py # Launcher del widget GTK+WebKit
```

#### Configuración de Apariencia (`looknfeel.conf`)

```conf
general {
    gaps_in = 8        # Espacio entre ventanas (px)
    gaps_out = 16      # Espacio en bordes de pantalla (px)
    border_size = 3    # Grosor del borde de ventanas

    # Gradiente morado de 3 tonos para ventanas activas
    col.active_border = rgb(c77dff) rgb(7b2cbf) rgb(5a189a) 45deg
    col.inactive_border = rgba(595959aa)
}

decoration {
    rounding = 12           # Radio de esquinas redondeadas
    active_opacity = 0.98   # Opacidad ventana activa
    inactive_opacity = 0.85 # Opacidad ventanas inactivas
    fullscreen_opacity = 1.0

    drop_shadow = true
    shadow_range = 15
    shadow_render_power = 3
    col.shadow = rgba(5a189a88)  # Sombra morada

    dim_inactive = true
    dim_strength = 0.1

    blur {
        enabled = true
        size = 8        # Tamaño del blur gaussiano
        passes = 3      # Calidad del blur
        vibrancy = 0.2  # Intensidad de color en blur
        contrast = 1.1
        brightness = 1.0
    }
}
```

#### Multi-Monitor

```
Super + Shift + H/L      → Mover ventana entre monitores
Super + Ctrl + Shift + ←/→ → Mover workspace completo
Super + Alt + ←/→        → Cambiar foco entre monitores
```

---

### 4.2 Waybar — Barra de Estado

**Waybar** es la barra de información superior. Tiene un sistema de layouts y estilos intercambiables en caliente.

#### Sistema de Layouts (5 opciones)

Los layouts definen **qué módulos** aparecen y **dónde**:

```
~/.config/waybar/
├── config                  # Archivo de config activo (symlink o directo)
├── layouts/
│   ├── layout-minimal.json
│   ├── layout-default.json
│   ├── layout-full.json
│   ├── layout-gaming.json
│   └── layout-minimal-right.json
├── style/
│   ├── style-islands.css   # Módulos flotantes tipo "isla"
│   ├── style-bintang.css   # Estilo compacto
│   ├── style-full.css      # Barra completa tradicional
│   └── style-default.css
└── ModulesCustom           # Módulos personalizados (JSON)
```

#### Módulos Disponibles

| Módulo | Descripción |
|--------|-------------|
| `hyprland/workspaces` | Indicadores de workspaces activos |
| `clock` | Reloj con formato personalizable |
| `pulseaudio` | Volumen con control de scroll |
| `network` | Estado de red Wi-Fi/Ethernet |
| `battery` | Estado de batería con iconos |
| `custom/menu` | Botón de lanzador |
| `custom/swaync` | Botón de notificaciones con badge |
| `custom/cat-theme` | Botón de toggle Dark/Light (configurable) |
| `cpu` | Uso de CPU en tiempo real |
| `memory` | Uso de RAM |
| `temperature` | Temperatura del sistema |
| `backlight` | Control de brillo |
| `tray` | Bandeja del sistema |

#### Cambiar Estilos en Caliente

```bash
# Con keybind:
Super + Ctrl + B  # Abre menú de estilos

# O manualmente:
ln -sf ~/.config/waybar/style/islands.css ~/.config/waybar/style.css
pkill -SIGUSR2 waybar  # Recarga sin reiniciar

# O con keybind de reinicio completo:
Super + R  # Ejecuta wbrestart.sh
```

---

### 4.3 Rofi — Lanzador de Aplicaciones

**Rofi** actúa como lanzador de aplicaciones, selector de ventanas y menú de utilidades. Los colores son generados dinámicamente por Matugen.

```bash
Super + D    # Abrir Rofi app launcher
```

#### Configuración

La config de Rofi en `~/.config/rofi/` incluye:
- Tema sincronizado con Matugen
- Modo dmenu para scripts personalizados
- Modo window para cambio rápido entre ventanas abiertas

---

### 4.4 Kitty — Emulador de Terminal

**Kitty** es el terminal principal. Usa aceleración GPU y soporta temas de color dinámicos.

```bash
Super + Return    # Abrir terminal
```

**Features activos:**
- Colores sincronizados con Matugen (paleta morada dinámica)
- Fuente: JetBrains Mono Nerd
- Transparencia variable (opacidad configurable por `windowrulev2`)
- Soporte de ligaduras de fuente

#### Regla de Opacidad en `windowrules.conf`

```conf
# Terminal más transparente (80% activa, 70% inactiva)
windowrulev2 = opacity 0.80 0.70, class:^(kitty)$
```

---

### 4.5 swww — Gestor de Wallpapers

**swww** reemplaza a `hyprpaper` como backend de wallpapers. Su ventaja principal es el soporte de **transiciones animadas** al cambiar de fondo.

```bash
# Iniciar daemon (en hyprland.conf)
exec-once = swww-daemon

# Cambiar wallpaper con transición circular
swww img ruta/wallpaper.jpg \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-fps 60 \
    --transition-duration 1.2
```

#### Tipos de Transición Disponibles

| Tipo | Efecto |
|------|--------|
| `grow` | Expansión circular desde el centro ⭕ |
| `fade` | Crossfade simple |
| `wipe` | Cortina direccional |
| `wave` | Efecto de onda |
| `outer` | Desde bordes hacia el centro |

---

### 4.6 Matugen — Sistema de Colores Dinámicos

**Matugen** es el componente más importante del sistema de theming. Analiza el wallpaper activo y genera una paleta de colores armónica que se aplica a todo el sistema.

#### Cómo Funciona

```
1. Usuario selecciona wallpaper (Super + W o wppicker.sh)
         │
         ▼
2. matugen image ~/Pictures/wallpapers/foto.jpg
         │
         ▼
3. Matugen analiza los colores dominantes del wallpaper
   y genera paletas de Material Design (dark + light)
         │
         ▼
4. Los templates en ~/.config/matugen/templates/ se procesan:
   - colors.conf    → ~/.config/hypr/colors.conf
   - style.css      → ~/.config/waybar/colors.css
   - kitty.conf     → ~/.config/kitty/colors.conf
   - rofi.rasi      → ~/.config/rofi/colors.rasi
   - swaync.css     → ~/.config/swaync/style.css
   - wlogout.css    → ~/.config/wlogout/style.css
   - hyprlock.conf  → ~/.config/hypr/hyprlock-colors.conf
   - gtk.css        → ~/.config/gtk-3.0/colors.css
         │
         ▼
5. Post-hooks ejecutan:
   - hyprctl reload           (recarga Hyprland)
   - pkill -SIGUSR2 waybar    (recarga Waybar en caliente)
   - kill + restart kitty     (aplica colores al terminal)
```

#### Configuración de Matugen (`~/.config/matugen/config.toml`)

```toml
[config]
reload_apps = true        # Recargar apps automáticamente
set_wallpaper = false     # swww maneja el wallpaper, no matugen

[config.reload_apps_config]
hyprland = true
waybar = true
kitty = true
```

---

### 4.7 SwayNC — Centro de Notificaciones

**SwayNC** (Sway Notification Center) es el daemon de notificaciones con panel lateral.

```bash
Super + N          # Toggle del panel de notificaciones
Super + Shift + N  # Borrar todas las notificaciones
```

#### Configuración (`~/.config/swaync/config.json`)

```json
{
    "positionX": "right",
    "positionY": "top",
    "width": 400,
    "height": 600,
    "layer": "overlay",
    "control-center-margin-top": 10,
    "control-center-margin-bottom": 10,
    "control-center-margin-right": 10
}
```

Los colores del panel se generan dinámicamente por Matugen.

---

### 4.8 Hyprlock — Pantalla de Bloqueo

**Hyprlock** es el locker nativo de Hyprland con soporte de animaciones y renderizado Wayland-native.

```bash
Super + L    # Bloquear pantalla
```

#### Características Visuales

- Wallpaper actual con efecto blur gaussiano
- Reloj grande en color morado espacial
- Fecha y nombre de usuario
- Indicador de batería
- Integración con el tema de color activo (Matugen genera los colores)

---

### 4.9 Hypridle — Gestión de Inactividad

**Hypridle** es el daemon que gestiona las acciones automáticas cuando el sistema está inactivo.

#### Configuración (`~/.config/hypr/hypridle.conf`)

```conf
general {
    lock_cmd = hyprlock             # Comando para bloquear
    before_sleep_cmd = hyprlock     # Bloquear antes de suspender
}

listener {
    timeout = 300       # 5 minutos → apagar pantalla
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 600       # 10 minutos → bloquear
    on-timeout = hyprlock
}

listener {
    timeout = 1800      # 30 minutos → suspender
    on-timeout = systemctl suspend
}
```

---

### 4.10 Wlogout — Menú de Salida

**Wlogout** es el menú de cierre de sesión con diseño espacial morado.

```bash
Super + X    # Abrir menú de sesión
```

#### Opciones Disponibles

| Botón | Acción |
|-------|--------|
| 🔒 Lock | Bloquear pantalla |
| 🚪 Logout | Cerrar sesión |
| 😴 Suspend | Suspender sistema |
| 💤 Hibernate | Hibernar |
| 🔴 Shutdown | Apagar |
| 🔄 Reboot | Reiniciar |

Los colores del menú se sincronizan con Matugen.

---

## 5. Feature Estrella: Cat Theme Toggle

La funcionalidad más única y elaborada del rice. Permite cambiar entre **modo oscuro y modo claro** con una ventana ilustrada animada con gatos y flip 3D.

### 5.1 Concepto Visual

No es un simple switch. Es una **tarjeta/ventana ilustrada** que muestra escenas completas:

```
╔═════════════════════╗        ╔═════════════════════╗
║  ⭐    🌙    ⭐     ║  flip  ║       ☀️           ║
║                     ║  3D   ║                     ║
║──────────────────── ║ ════> ║────────────────────  ║
║                     ║       ║                     ║
║   ⛰️  ⛰️  ⛰️        ║       ║    🌸  🌼           ║
║       🐈‍⬛           ║       ║       🐈            ║
╚═════════════════════╝        ╚═════════════════════╝
     Dark Mode                      Light Mode
     (Gato Negro)                   (Gato Naranja)
```

### 5.2 Arquitectura del Toggle

```
Super + T
    │
    ├── cat-theme-widget.py     (Python GTK3 + WebKit2)
    │       Crea ventana GTK 280x420px
    │       Carga cat-theme-toggle.html via WebKit2
    │       La ventana se cierra en 2 segundos
    │
    └── cat-theme-toggle.sh     (Bash)
            Lee ~/.config/hypr/.theme-mode
            Cambia dark ↔ light
            Cambia wallpaper con swww (transición grow)
            Ejecuta matugen para generar nuevos colores
            Actualiza GTK theme
            Recarga Hyprland + Waybar + Kitty
```

### 5.3 Stack Técnico del Widget

| Capa | Tecnología | Descripción |
|------|------------|-------------|
| Launcher | Python3 + GTK3 | 91 líneas. Crea la ventana nativa de Wayland |
| Rendering | WebKit2 (webkit2gtk) | Renderiza HTML/CSS dentro de la ventana GTK |
| UI | HTML5 + CSS3 puro | 710+ líneas. Escenas, animaciones, flip 3D |

#### Evolución del Widget

**v1 — Cairo (descartado)**
- 360 líneas de Python con dibujado manual
- Gatos: círculos simples simulados
- No reutilizaba el CSS original

**v2 — Mini-gatos CSS (intermedio)**  
- HTML/CSS con mini-gatos de 20x35px
- Diseño tipo pill switch horizontal (180x80px)
- Gatos desaturados al estar inactivos

**v3 — Ventana/Escena Ilustrada (actual) ✅**
- Gatos tamaño original (50x140px del `style.css`)
- Escenas completas con contexto visual
- Flip 3D con `rotateY(180deg)` y `preserve-3d`
- Widget de 280x420px

### 5.4 CSS del Gato — Reutilización de `style.css`

El archivo `style.css` en la raíz del repositorio es el **CSS original** de donde se obtiene el diseño del gato. Fue reutilizado directamente en el toggle:

#### Anatomía del Gato CSS

```css
/* Cuerpo principal del gato */
.kitty {
    background-color: #2d2623;  /* Marrón oscuro */
    height: 140px;
    width: 50px;
    border-radius: 40px 40px 0 0;  /* Cabeza redondeada */
    position: absolute;
    bottom: -15px;
    left: 95px;
}

/* Torso (elemento :before) */
.kitty:before {
    content: "";
    background-color: #2d2623;
    height: 80px;
    width: 40px;
    border-radius: 0 80px 80px 0;  /* Panza redondeada */
    bottom: 0;
    left: 43px;
}

/* Cola animada (elemento :after) */
.kitty:after {
    content: "";
    background-color: #2d2623;
    height: 80px;
    width: 10px;
    border-radius: 5px;
    transform: rotate(-15deg);
    animation: tail 4s infinite;  /* Movimiento de cola */
}

/* Animación de la cola */
@keyframes tail {
    50% { transform: rotate(10deg); }
}

/* Oreja */
.ear {
    border-bottom: 40px solid #2d2623;
    border-right: 33px solid transparent;
}
```

#### Elementos del CSS Original Reutilizados

| Elemento | Descripción | Destino en Toggle |
|----------|-------------|-------------------|
| `.kitty` | Cuerpo del gato | `.kitty` (mismo nombre) |
| `.kitty:before` | Torso redondeado | Preservado |
| `.kitty:after` | Cola animada | Preservado |
| `@keyframes tail` | Animación de cola | `@keyframes tail-wag` |
| `.ear` | Oreja triangular | Preservado |
| `.moon` | Luna creciente con sombra CSS | Preservado |
| `.star` | Estrellas con box-shadow múltiple | Preservado |
| `@keyframes twinkle` | Parpadeo de estrellas | Preservado |
| `.mountain-1/2` | Montañas con CSS borders | Simplificado |
| `.window` | Marco de ventana de madera | `.window-frame` |

#### Diferencias: Gato Negro vs Gato Naranja

| Propiedad | Gato Negro (Dark) | Gato Naranja (Light) |
|-----------|-------------------|----------------------|
| Color cuerpo | `#2d2623` (original) | `#ff8c42` (nuevo) |
| Color ojos | `#ffd700` (amarillo/dorado) | `#4a9eff` (azul celeste) |
| Glow de ojos | `box-shadow: 0 0 6px #ffd700` | `box-shadow: 0 0 6px #4a9eff` |
| Orejas | Color del cuerpo | Color del cuerpo |
| Cola | `#2d2623` | `#ff8c42` |

### 5.5 Animación Flip 3D — CSS Clave

```css
/* Contenedor padre: perspectiva 3D */
.theme-toggle {
    perspective: 1200px;
}

/* Contenedor de escenas: activa 3D space */
.scenes-container {
    transform-style: preserve-3d;
    transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Al activar light mode: girar la tarjeta */
body.light .scenes-container {
    transform: rotateY(180deg);
}

/* Cada escena oculta su cara trasera */
.scene {
    backface-visibility: hidden;
}

/* La escena light está pre-girada 180° */
.scene--light {
    transform: rotateY(180deg);
}
```

#### Línea del Tiempo de la Animación

```
t=0.0s   t=0.2s   t=0.4s   t=0.6s   t=0.8s
  🌙        ║        ║        ║        ☀️
 Visible   70°      90°     110°    Visible
 (Dark)   Girando  Borde   Girando  (Light)
```

### 5.6 Integración del Toggle con el Sistema

Cuando se activa `Super + T`:

```bash
# cat-theme-toggle.sh (simplificado)

THEME_FILE="$HOME/.config/hypr/.theme-mode"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
DARK_WALLPAPER="$WALLPAPER_DIR/cat-dark.png"
LIGHT_WALLPAPER="$WALLPAPER_DIR/cat-light.png"

# Leer estado actual
CURRENT=$(cat "$THEME_FILE" 2>/dev/null || echo "dark")

if [ "$CURRENT" = "dark" ]; then
    NEW_THEME="light"
    WALLPAPER="$LIGHT_WALLPAPER"
else
    NEW_THEME="dark"
    WALLPAPER="$DARK_WALLPAPER"
fi

# Guardar nuevo estado
echo "$NEW_THEME" > "$THEME_FILE"

# Cambiar wallpaper con transición circular
swww img "$WALLPAPER" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-fps 60 \
    --transition-duration 1.2 \
    --transition-bezier 0.25,0.1,0.25,1.0

# Aplicar colores con Matugen
matugen image "$WALLPAPER"

# GTK theme
gsettings set org.gnome.desktop.interface color-scheme "prefer-$NEW_THEME"

# Recargar
hyprctl reload
pkill -SIGUSR2 waybar
```

### 5.7 Reglas de Ventana para el Widget

```conf
# windowrules.conf
windowrule = float, title:^(Cat Theme Toggle)$
windowrule = center, title:^(Cat Theme Toggle)$
windowrule = size 280 420, title:^(Cat Theme Toggle)$
windowrule = animation slide, title:^(Cat Theme Toggle)$
windowrule = opacity 0.98, title:^(Cat Theme Toggle)$
windowrule = noblur, title:^(Cat Theme Toggle)$
```

---

## 6. Sistema de Colores y Paletas

### 6.1 Paleta Base Morada

El rice tiene una paleta de fallback definida en `colors-base.conf`:

```conf
# Palette: Deep Space Purple
$primary    = rgb(9d4edd)   # Morado vibrante — bordes activos, highlights
$secondary  = rgb(7b2cbf)   # Morado oscuro — elementos secundarios
$accent     = rgb(c77dff)   # Morado claro — acentos y detalles
$background = rgb(10002b)   # Casi negro morado — fondos base
$foreground = rgb(e0aaff)   # Lavanda — texto sobre fondo oscuro
```

### 6.2 Las 4 Variantes de Tema (`theme-switcher.sh`)

| Nombre | Descripción | Hex Base |
|--------|-------------|----------|
| **Deep Space** | Morado muy oscuro, casi negro | `#10002b` |
| **Nebula** | Morado medio, vibrante | `#9d4edd` |
| **Cosmic** | Morado claro, luminoso | `#c77dff` |
| **Lofi** | Tonos pastel morados, suaves | `#b19cd9` |

### 6.3 Paletas de Wallpapers Optimizadas

Wallpapers que generan las mejores paletas con Matugen:

| Palette | Primary | Secondary | Accent | Background |
|---------|---------|-----------|--------|------------|
| **Deep Space Purple** | `#9d4edd` | `#7b2cbf` | `#c77dff` | `#10002b` |
| **Nebula Violet** | `#b19cd9` | `#6a4c93` | `#dda15e` | `#1a1423` |
| **Cosmic Lavender** | `#a480cf` | `#5e3a7d` | `#e8b4f0` | `#1f1235` |
| **Lavender Dream** | `#b19cd9` | `#a480cf` | `#e8b4f0` | `#1f1235` |
| **Neon Purple** | `#bf00ff` | `#8000ff` | `#ff00ff` | `#0d0015` |

### 6.4 Configuración de Bordes con Gradiente

```conf
# looknfeel.conf — Gradientes disponibles:

# Borde sólido
col.active_border = rgb(9d4edd)

# Gradiente 2 colores
col.active_border = rgb(c77dff) rgb(7b2cbf) 45deg

# Gradiente 3 colores (configuración actual)
col.active_border = rgb(c77dff) rgb(7b2cbf) rgb(5a189a) 45deg

# Gradiente 4 colores (más vistoso)
col.active_border = rgb(e0aaff) rgb(c77dff) rgb(7b2cbf) rgb(5a189a) 45deg
```

---

## 7. Scripts Personalizados

### 7.1 `wppicker.sh` — Selector de Wallpapers

**Función:** Abre un selector de wallpapers con preview visual. Al seleccionar uno, lo aplica con `swww` y regenera todos los colores del sistema con `matugen`.

```bash
# Activar:
Super + W
# O directamente:
~/.config/hypr/scripts/wppicker.sh
```

**Flujo:**
1. Lista los wallpapers de `~/Pictures/wallpapers/`
2. Muestra preview en Rofi o selector visual
3. Aplica wallpaper con `swww img` (transición fade/grow)
4. Ejecuta `matugen image <wallpaper>`
5. Recarga todos los componentes

---

### 7.2 `wallpaper-rotation.sh` — Rotación Automática

**Función:** Cambia el wallpaper automáticamente cada intervalo definido, eligiendo al azar de la colección.

```bash
# Se inicia automáticamente con:
exec-once = ~/.config/hypr/scripts/wallpaper-rotation.sh

# Lógica interna:
while true; do
    RANDOM_WALL=$(ls ~/Pictures/wallpapers/*.{jpg,png} | shuf -n1)
    matugen image "$RANDOM_WALL"
    sleep 3600  # Cada hora
done
```

---

### 7.3 `theme-switcher.sh` — 4 Variantes de Tema

**Función:** Permite cambiar entre las 4 paletas moradas predefinidas (Deep Space, Nebula, Cosmic, Lofi) sin depender de un wallpaper específico.

---

### 7.4 `volume.sh` — Control de Volumen

**Función:** Ajusta el volumen con `pamixer` y envía notificación visual con el nivel actual.

```bash
# Internamente:
pamixer --increase 5
notify-send "Volume: $(pamixer --get-volume)%"
```

---

### 7.5 `brightness.sh` — Control de Brillo

**Función:** Ajusta el brillo de la pantalla con `brightnessctl` y envía notificación.

---

### 7.6 `screenshot.sh` — Capturas de Pantalla

**Función:** Gestiona las capturas de pantalla con `grim` + `slurp` + `swappy`.

| Modo | Comando |
|------|---------|
| Área seleccionable | `Print` → `slurp` → `grim` → `swappy` (editor) |
| Pantalla completa | `Super + Print` → `grim` directo |

---

### 7.7 `WaybarStyles.sh` + `WaybarLayout.sh`

**Función:** Cambian el estilo visual y el layout de módulos de Waybar respectivamente.

```bash
Super + Ctrl + B   # Cambiar estilo (islands, bintang, full...)
Super + Alt + B    # Cambiar layout (minimal, default, full...)
```

---

### 7.8 `sync-configs.sh` — Sincronización al Repo

**Función:** Copia todas las configs actuales del sistema al repositorio para poder commitearlas.

```bash
# Ubicado en la raíz del repo:
./sync-configs.sh

# Copia desde:
~/.config/hypr/          → .config/hypr/
~/.config/waybar/        → .config/waybar/
~/.config/kitty/         → .config/kitty/
~/.config/rofi/          → .config/rofi/
~/.config/matugen/       → .config/matugen/
~/.config/swaync/        → .config/swaync/
~/.config/wlogout/       → .config/wlogout/
~/.zshrc                 → .zshrc

# Luego muestra:
git status --short
```

> ⚠️ **Nota importante:** El `REPO_DIR` en `sync-configs.sh` está hardcodeado como `/home/zgreencat/rice_repos/arch-hyprland/my-hyprland-rice`. Si clonas el repo en otra ubicación, debes actualizar esta variable.

---

### 7.9 `install.sh` — Instalador Automático

**Función:** Instala todas las configuraciones en el sistema con backup automático.

```bash
./install.sh
# Hace backup de: hypr, waybar, kitty, rofi, matugen, swaync, wlogout
# Copia nuevas configs desde el repo
# Hace ejecutables los scripts
# Pregunta si copiar .zshrc
```

---

## 8. Keybindings Completos

### 8.1 Aplicaciones y Sesión

| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abrir terminal (Kitty) |
| `Super + D` | Lanzador de apps (Rofi) |
| `Super + E` | Explorador de archivos |
| `Super + L` | Bloquear pantalla (Hyprlock) |
| `Super + X` | Menú de salida (Wlogout) |
| `Super + Q` | Cerrar ventana activa |

### 8.2 Gestión de Ventanas

| Atajo | Acción |
|-------|--------|
| `Super + ←/→/↑/↓` | Mover foco entre ventanas |
| `Super + Ctrl + ←/→/↑/↓` | Mover ventana en el layout |
| `Super + Shift + ←/→/↑/↓` | Redimensionar ventana |
| `Super + V` / `Super + Space` | Toggle floating/tiling |
| `Super + F` | Fullscreen |

### 8.3 Workspaces

| Atajo | Acción |
|-------|--------|
| `Super + 1-9` | Ir a workspace 1-9 |
| `Super + Shift + 1-9` | Mover ventana a workspace 1-9 |
| `Super + Mouse wheel` | Navegar entre workspaces |

### 8.4 Multi-Monitor

| Atajo | Acción |
|-------|--------|
| `Super + Shift + H/L` | Mover ventana al otro monitor |
| `Super + Ctrl + Shift + ←/→` | Mover workspace completo |
| `Super + Alt + ←/→` | Cambiar foco entre monitores |

### 8.5 Utilidades y Theming

| Atajo | Acción |
|-------|--------|
| `Print` | Screenshot de área (con edición en swappy) |
| `Super + Print` | Screenshot pantalla completa |
| `Super + W` | Selector de wallpapers |
| `Super + T` | Toggle Dark/Light Mode (Cat Theme Toggle) |
| `Super + C` | Color picker (hyprpicker) |
| `Super + N` | Toggle notificaciones (SwayNC) |
| `Super + Shift + N` | Borrar todas las notificaciones |
| `Super + R` | Reiniciar Waybar |
| `Super + Ctrl + B` | Cambiar estilo Waybar |
| `Super + Alt + B` | Cambiar layout Waybar |

### 8.6 Multimedia

| Atajo | Acción |
|-------|--------|
| `XF86AudioRaiseVolume` | Subir volumen 5% |
| `XF86AudioLowerVolume` | Bajar volumen 5% |
| `XF86AudioMute` | Mutear/desmutear |
| `XF86MonBrightnessUp` | Subir brillo |
| `XF86MonBrightnessDown` | Bajar brillo |
| `XF86AudioPlay/Pause` | Reproducir/Pausar |
| `XF86AudioNext` | Siguiente pista |
| `XF86AudioPrev` | Pista anterior |

---

## 9. Animaciones y Efectos Visuales

### 9.1 Bezier Curves Personalizadas

Se definen 7 curvas de animación en `UserAnimations.conf`:

```conf
bezier = spaceIn,     0.05, 0.9, 0.1, 1.05    # Entrada elástica
bezier = spaceOut,    0.9, 0.05, 1, 0.9        # Salida suave
bezier = space,       0.46, 0.03, 0.52, 0.96   # General
bezier = spaceSmooth, 0.25, 0.1, 0.25, 1       # Suave estándar
bezier = spaceBounce, 0.68, -0.55, 0.265, 1.55 # Con rebote
bezier = spaceFloat,  0.33, 1, 0.68, 1         # Flotante
bezier = spaceFade,   0.76, 0, 0.24, 1         # Fade preciso
```

### 9.2 Animaciones del Compositor

```conf
animations {
    enabled = true

    # Ventanas
    animation = windowsIn,  1, 7, spaceIn,   popin 90%  # Apertura
    animation = windowsOut, 1, 5, spaceOut,  popin 90%  # Cierre
    animation = windowsMove,1, 5, spaceSmooth            # Mover

    # Fade
    animation = fadeIn,   1, 5, spaceFade                # Aparecer
    animation = fadeOut,  1, 5, spaceFade                # Desaparecer
    animation = fadeSwitch, 1, 5, spaceFade              # Switch de workspace

    # Workspaces
    animation = workspaces, 1, 8, space, slide           # Slide suave
    animation = specialWorkspace, 1, 6, spaceFloat, slide
}
```

### 9.3 Efectos de Profundidad

| Efecto | Config | Descripción |
|--------|--------|-------------|
| **Blur** | `size=8, passes=3` | Desenfoque gaussiano de alta calidad |
| **Vibrancy** | `vibrancy=0.2` | El blur preserva saturación del color |
| **Sombras** | `range=15, power=3` | Sombras suaves con tono morado |
| **Dim** | `strength=0.1` | Ventanas inactivas ligeramente oscurecidas |
| **Rounding** | `rounding=12` | Esquinas redondeadas en todas las ventanas |

### 9.4 Configuración de Opacidad

```conf
# Por tipo de ventana:
active_opacity = 0.98       # Ventana activa: casi opaca
inactive_opacity = 0.85     # Ventanas inactivas: semi-transparentes
fullscreen_opacity = 1.0    # Fullscreen: completamente opacas

# Por aplicación (windowrules.conf):
windowrulev2 = opacity 0.80 0.70, class:^(kitty)$      # Terminal
windowrulev2 = opacity 0.98 0.95, class:^(firefox)$    # Navegador
windowrulev2 = opacity 0.90 0.85, class:^(code)$       # VSCode
windowrulev2 = opacity 0.85 0.75, class:^(discord)$    # Discord
```

---

## 10. Gestión de Wallpapers

### 10.1 Colección Recomendada (por tipo)

| Categoría | Descripción |
|-----------|-------------|
| **Nebulosas** | Horsehead, Carina, Pillars of Creation en morado |
| **Planetas** | Saturno con anillos violeta, planetas ficticios lofi |
| **Lofi Space** | Arte ilustrado estilo lofi con temática espacial |
| **Abstracto** | Gradientes morados minimalistas, geométricos |
| **Synthwave** | Estética retro-futurista con colores neón morado |

### 10.2 Fuentes de Wallpapers

| Fuente | URL/Búsqueda |
|--------|-------------|
| **Unsplash** | `unsplash.com/s/photos/purple-nebula` |
| **Wallhaven** | Tags: `purple+space`, `violet+galaxy`, `nebula+purple` |
| **NASA** | `webbtelescope.org` (dominio público) |
| **Pinterest** | "Purple space wallpaper aesthetic" |
| **AI Generados** | Stable Diffusion/Midjourney con prompts de nebulosa morada |

### 10.3 Criterios de Selección

Para que Matugen genere las mejores paletas, el wallpaper debe:

- ✅ **Color dominante morado/violeta** (60%+ de la imagen)
- ✅ **Buen contraste** para que los iconos sean legibles
- ✅ **Resolución mínima:** 1920x1080
- ✅ **Complejidad moderada:** relajante, no demasiado "busy"
- ✅ **Sin compresión excesiva:** JPG a alta calidad o PNG

### 10.4 Organización de Wallpapers

```
~/Pictures/wallpapers/
├── cat-dark.png        # Wallpaper para modo oscuro (Cat Toggle)
├── cat-light.png       # Wallpaper para modo claro (Cat Toggle)
├── space/              # Organización por categorías
│   ├── nebulas/
│   ├── planets/
│   └── abstract/
└── lofi/
```

---

## 11. Estructura de Archivos del Repo

```
my-hyprland-rice/
│
├── 📄 README.md                  # Documentación principal
├── 📄 AUDITORIA.md               # Este archivo — auditoría completa
├── 📄 DEPENDENCIES.md            # Lista de todas las dependencias
├── 📄 CUSTOMIZATION.md           # Guía detallada de personalización
├── 📄 QUICKSTART.md              # Guía de inicio rápido
├── 📄 WALLPAPERS.md              # Colección curada de wallpapers
├── 📄 CHANGELOG.md               # Historial de cambios
│
├── 📄 CAT_THEME_TOGGLE.md        # Doc del sistema de toggle
├── 📄 CSS_CAT_ADAPTATION.md      # Mapeo CSS original → toggle
├── 📄 IMPLEMENTATION_SUMMARY.md  # Resumen técnico de implementación
├── 📄 REDESIGN_SUMMARY.md        # Evolución del diseño del toggle
├── 📄 WINDOW_SCENE_DESIGN.md     # Diseño detallado de las escenas
│
├── 🎨 style.css                  # CSS original del gato (base de diseño)
├── 🌐 index.html                 # Preview HTML del rice (referencia)
│
├── 🔧 install.sh                 # Instalador automático con backup
├── 🔧 sync-configs.sh            # Sincronizador sistema → repo
├── 🔧 apply-configs.sh           # Aplicador de configs
│
├── 📸 screenshots/
│   └── README.md                 # (Pendiente: añadir screenshots)
│
└── .config/                      # Todas las configuraciones del sistema
    ├── hypr/
    │   ├── hyprland.conf
    │   ├── colors.conf
    │   ├── colors-base.conf
    │   ├── hypridle.conf
    │   ├── hyprlock.conf
    │   ├── .theme-mode
    │   ├── configs/
    │   │   ├── keybinds.conf
    │   │   ├── looknfeel.conf
    │   │   ├── UserAnimations.conf
    │   │   ├── windowrules.conf
    │   │   ├── tags.conf
    │   │   └── monitors.conf
    │   └── scripts/
    │       ├── wppicker.sh
    │       ├── volume.sh
    │       ├── brightness.sh
    │       ├── screenshot.sh
    │       ├── WaybarStyles.sh
    │       ├── WaybarLayout.sh
    │       ├── wallpaper-rotation.sh
    │       ├── theme-switcher.sh
    │       ├── cat-theme-toggle.sh
    │       ├── cat-theme-widget.py
    │       └── cat-theme-toggle.html
    ├── waybar/
    │   ├── config
    │   ├── style.css
    │   ├── layouts/
    │   ├── style/
    │   └── ModulesCustom
    ├── kitty/
    ├── rofi/
    ├── matugen/
    │   ├── config.toml
    │   └── templates/
    ├── swaync/
    │   ├── config.json
    │   └── style.css
    └── wlogout/
```

---

## 12. Dependencias Completas

### 12.1 Paquetes Oficiales (pacman)

```bash
sudo pacman -S --needed \
    # Core
    hyprland waybar rofi kitty \
    # Wallpaper y colores
    swww \
    # Notificaciones y lockscreen
    swaync wlogout hyprlock hypridle \
    # Control de hardware
    brightnessctl pamixer playerctl \
    # Screenshots
    grim slurp swappy \
    # Sistema
    polkit-gnome \
    # Systray
    network-manager-applet blueman \
    # Color picker
    hyprpicker \
    # Shell
    zsh \
    # Fuentes
    ttf-jetbrains-mono-nerd ttf-font-awesome \
    # Iconos
    papirus-icon-theme \
    # Extras
    fastfetch cava nautilus \
    # Widget GTK
    python-gobject gtk3 webkit2gtk
```

### 12.2 Paquetes AUR (yay)

```bash
yay -S --needed \
    matugen-bin \                    # Generador de colores (CRÍTICO)
    zsh-autosuggestions \            # Sugerencias en zsh
    zsh-syntax-highlighting          # Highlighting en zsh
```

### 12.3 Post-Instalación

```bash
# Configurar Zsh como shell predeterminado
chsh -s $(which zsh)

# Instalar Oh My Zsh (opcional pero recomendado)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Iniciar swww daemon
swww-daemon &

# Verificar instalación
which hyprland waybar rofi kitty matugen swww swaync hyprlock
```

---

## 13. Flujos de Trabajo y Mantenimiento

### 13.1 Flujo de Trabajo Diario

```
Inicio de sesión → Hyprland carga
      │
      ├── exec-once = swww-daemon
      ├── exec-once = waybar
      ├── exec-once = swaync-service
      ├── exec-once = hypridle
      ├── exec-once = polkit-gnome-authentication-agent
      ├── exec-once = nm-applet --indicator
      └── exec-once = blueman-applet
```

### 13.2 Flujo de Personalización de Colores

```
1. Super + W → wppicker.sh
2. Seleccionar wallpaper
3. swww aplica el wallpaper con transición
4. matugen genera paleta automáticamente
5. Todos los componentes se recargan (hooks)
6. Sistema completo actualizado
```

### 13.3 Flujo de Sincronización al Repo

```bash
# Hacer cambios en ~/.config/hypr/, ~/.config/waybar/, etc.
# Luego sincronizar:

cd /home/zgreencat/AntigravityWorkspace/my-hyprland-rice
./sync-configs.sh

# Revisar qué cambió:
git diff

# Commitear:
git add .
git commit -m "feat: Descripción del cambio"
git push
```

### 13.4 Workflow de Screenshots

```bash
# Screenshot para el repo:
grim -g "$(slurp)" ~/my-hyprland-rice/screenshots/mi-setup.png

git add screenshots/
git commit -m "docs: Añadir screenshot del setup"
git push
```

---

## 14. Personalización Avanzada

### 14.1 Gaps y Bordes — Presets

| Preset | gaps_in | gaps_out | border_size | Uso |
|--------|---------|----------|-------------|-----|
| Minimalista | 4 | 8 | 2 | Máximo espacio útil |
| **Equilibrado (actual)** | **8** | **16** | **3** | Balance estética/espacio |
| Espacioso | 12 | 24 | 4 | Estética máxima |
| Ultra espacioso | 16 | 32 | 4 | Para screenshots |

### 14.2 Blur — Presets de Rendimiento

| Preset | size | passes | CPU | Calidad |
|--------|------|--------|-----|---------|
| Bajo | 4 | 1 | ~1% | Básica |
| Medio | 6 | 2 | ~3% | Buena |
| **Alto (actual)** | **8** | **3** | **~5%** | **Muy buena** |
| Ultra | 12 | 4 | ~10% | Máxima |

### 14.3 Ajuste de Workspaces en `tags.conf`

```conf
# Workspaces nombrados con iconos Nerd Font:
workspace = 1, name:  # Terminal
workspace = 2, name:  # Navegador
workspace = 3, name:  # Editor de código
workspace = 4, name:  # Multimedia
workspace = 5, name:  # Comunicación

# Workspaces persistentes (siempre visibles en Waybar):
workspace = 1, persistent:true
workspace = 2, persistent:true
```

### 14.4 Reglas de Ventana Avanzadas

```conf
# windowrules.conf

# Aplicaciones flotantes por defecto:
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, title:^(Confirm Exit)$

# Posicionamiento específico:
windowrulev2 = move 100 100, class:^(kitty)$, title:^(float_term)$
windowrulev2 = size 800 500, class:^(kitty)$, title:^(float_term)$

# Opacidad por app:
windowrulev2 = opacity 0.80 0.70, class:^(kitty)$
windowrulev2 = opacity 0.98 0.95, class:^(firefox)$
windowrulev2 = opacity 0.90 0.85, class:^(code)$

# Widget del toggle:
windowrule = float, title:^(Cat Theme Toggle)$
windowrule = center, title:^(Cat Theme Toggle)$
windowrule = size 280 420, title:^(Cat Theme Toggle)$
```

### 14.5 Personalización del Cat Theme Toggle

#### Cambiar velocidades de animación

```css
/* En cat-theme-toggle.html */
.scenes-container {
    transition: transform 0.8s; /* flip → 0.5s rápido, 1.2s lento */
}
animation: tail-wag 4s;  /* cola → 3s rápido, 6s lento */
animation: twinkle 2s;   /* estrellas → 1s rápido, 4s lento */
```

#### Cambiar colores de las escenas

```css
/* Cielo nocturno */
.scene--dark {
    background: linear-gradient(180deg, #0a0e27 0%, #1a1f3a 50%, #29467a 100%);
}
/* Cielo diurno */
.scene--light {
    background: linear-gradient(180deg, #87ceeb 0%, #ffd89b 40%, #ffa751 100%);
}
```

#### Añadir sincronización automática por hora del día

```bash
# En cat-theme-toggle.sh:
HOUR=$(date +%H)
if [ $HOUR -ge 6 ] && [ $HOUR -lt 18 ]; then
    DEFAULT_THEME="light"
else
    DEFAULT_THEME="dark"
fi
```

---

## 15. Historial de Versiones

### v1.0.0 — 2025-12-01 (Release Inicial)

- ✅ Configuración modular de Hyprland con source de archivos
- ✅ Tema espacial morado completo
- ✅ 7 bezier curves personalizadas para animaciones
- ✅ Integración completa con Matugen (8 templates)
- ✅ Waybar con 5 layouts y 4 estilos
- ✅ Scripts: wppicker, volume, brightness, screenshot, WaybarStyles
- ✅ SwayNC, Wlogout, Rofi, Kitty, Hyprlock, Hypridle configurados
- ✅ Documentación completa (README, DEPENDENCIES, QUICKSTART, WALLPAPERS)
- ✅ `install.sh` con backup automático
- ✅ `sync-configs.sh` para mantenimiento del repo

### v1.1.0 — Post 2025-12-01 (Cat Theme Toggle — Mini-gatos)

- ✅ Widget GTK+WebKit2 para toggle de tema
- ✅ Mini-gatos CSS de 20x35px adaptados de `style.css`
- ✅ Diseño pill switch horizontal (180x80px)
- ✅ CSS_CAT_ADAPTATION.md documentando la adaptación

### v1.2.0 — Post 2025-12-01 (Ventana/Escena Ilustrada)

- ✅ Rediseño completo del widget: pill → ventana ilustrada
- ✅ Gatos a tamaño original (50x140px)
- ✅ Escena nocturna: cielo azul, estrellas, luna, montañas, gato negro
- ✅ Escena diurna: cielo naranja, sol, césped, flores, gato naranja
- ✅ Flip 3D con CSS `preserve-3d` + `backface-visibility: hidden`
- ✅ Widget ampliado a 280x420px
- ✅ WINDOW_SCENE_DESIGN.md + REDESIGN_SUMMARY.md

### [Unreleased] — Pendiente

- [ ] Screenshots en alta calidad del setup completo
- [ ] Video demo del rice
- [ ] Integración con Spotify (spicetify theme morado)
- [ ] Tema custom para Discord (vesktop)
- [ ] Más wallpapers espaciales en el repo

---

## 16. Problemas Conocidos y TODOs

### 16.1 Problemas Conocidos

| Problema | Impacto | Solución |
|----------|---------|----------|
| `sync-configs.sh` tiene `REPO_DIR` hardcodeado | 🟡 Medio | Cambiar a variable dinámica con `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)` |
| Screenshots en `screenshots/` está vacío | 🟡 Medio | Añadir capturas reales del setup |
| `cat-dark.png` y `cat-light.png` deben existir manualmente | 🟡 Medio | Documentar/automatizar creación de symlinks |
| `README.md` tiene `TU_USUARIO` sin reemplazar en la URL del repo | 🟢 Bajo | Actualizar con la URL real del repo |
| `QUICKSTART.md` referencia la ruta hardcodeada del repo | 🟢 Bajo | Actualizar con ruta correcta |

### 16.2 TODOs de Funcionalidad

```
[ ] Añadir script para crear wallpapers cat-dark/cat-light automáticamente
[ ] Automatizar detección del tema según hora del día
[ ] Añadir más variantes de gato en el widget (gato gris, blanco, etc.)
[ ] Crear módulo custom de Waybar para Cat Theme Toggle
[ ] Integración con Spicetify para Spotify
[ ] Tema para Discord (vesktop)
[ ] Soporte para Hyprpaper como alternativa a swww
[ ] Añadir animación de rofi que combine con el estilo del rice
```

### 16.3 TODOs de Documentación

```
[ ] Añadir screenshots reales a screenshots/
[ ] Grabar video demo del rice
[ ] Documentar la config de .zshrc
[ ] Añadir guía de migración desde X11 a Wayland
[ ] Documentar la configuración completa de Matugen templates
```

---

## 17. Evaluación del Proyecto

### 17.1 Fortalezas

| Área | Evaluación | Detalle |
|------|------------|---------|
| **Documentación** | ⭐⭐⭐⭐⭐ | Excepcional. 10+ archivos MD con guías detalladas |
| **Modularidad** | ⭐⭐⭐⭐⭐ | Configs separadas por función, fácil de mantener |
| **Feature Única** | ⭐⭐⭐⭐⭐ | Cat Theme Toggle con flip 3D es un nivel creativo muy alto |
| **Sistema de Colores** | ⭐⭐⭐⭐⭐ | Matugen + templates = theming dinámico completo |
| **Estética** | ⭐⭐⭐⭐☆ | Paleta espacial morada coherente y atractiva |
| **Scripts** | ⭐⭐⭐⭐☆ | Buenos scripts de utilidad, bien organizados |
| **Mantenibilidad** | ⭐⭐⭐⭐☆ | sync-configs.sh + git = buen workflow |

### 17.2 Áreas de Mejora

| Área | Prioridad | Acción Sugerida |
|------|-----------|-----------------|
| Screenshots | 🔴 Alta | Añadir capturas reales urgente (el repo las necesita) |
| URL del repo hardcodeada | 🟡 Media | Usar `${BASH_SOURCE[0]}` en sync-configs.sh |
| Wallpapers del toggle | 🟡 Media | Crear script para generar/configurar cat-dark.png |
| Tests del instalador | 🟡 Media | Verificar que install.sh funciona en instalación limpia |
| Video demo | 🟢 Baja | Muy recomendable para r/unixporn |

### 17.3 Puntuación Global

```
┌─────────────────────────────────────────────────────┐
│                                                       │
│   Diseño Visual:          ████████████████████  95%  │
│   Funcionalidad:          ████████████████████  90%  │
│   Documentación:          ████████████████████  98%  │
│   Originalidad:           ████████████████████  95%  │
│   Mantenibilidad:         ████████████████████  85%  │
│   Rendimiento:            ████████████████████  88%  │
│                                                       │
│   PUNTUACIÓN GLOBAL:              91/100 ⭐           │
│                                                       │
│   Veredicto: Proyecto de alta calidad con            │
│   feature única (Cat Toggle), excelente             │
│   documentación y sistema de theming dinámico.      │
│   Listo para publicar en r/unixporn 🚀              │
│                                                       │
└─────────────────────────────────────────────────────┘
```

---

## Apéndice A — Comandos de Referencia Rápida

```bash
# === THEMING ===
Super + W                    # Selector de wallpapers
Super + T                    # Toggle Dark/Light (con gatitos 🐈)
matugen image ~/path/wp.jpg  # Regenerar colores manualmente

# === WAYBAR ===
Super + R                    # Reiniciar Waybar
Super + Ctrl + B             # Cambiar estilo
Super + Alt + B              # Cambiar layout
pkill -SIGUSR2 waybar        # Recarga en caliente

# === SISTEMA ===
hyprctl reload               # Recargar config Hyprland
hyprctl keyword general:gaps_in 10  # Cambio en caliente
Super + L                    # Bloquear pantalla
Super + X                    # Menú de sesión

# === REPO ===
./sync-configs.sh            # Sistema → Repo
./install.sh                 # Repo → Sistema (con backup)
git diff                     # Ver qué cambió
git add . && git commit -m "Update" && git push  # Publicar cambios

# === DEBUG ===
journalctl --user -xe | grep hyprland   # Logs del compositor
pgrep swww-daemon                        # Verificar daemon de wallpaper
which hyprland waybar matugen swww       # Verificar instalación
```

---

*Auditoría generada el 12 de Marzo de 2026 — zGreenCat's Space Hyprland Rice*
