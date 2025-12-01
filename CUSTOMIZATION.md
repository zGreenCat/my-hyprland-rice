# 🎨 Guía de Personalización

Cómo personalizar cada aspecto de tu Space Hyprland Rice.

## 📐 Cambiar Gaps y Bordes

### Gaps (Espacios entre ventanas)

```bash
# Editar: ~/.config/hypr/configs/looknfeel.conf

general {
    gaps_in = 8    # Espacio interno (entre ventanas)
    gaps_out = 16  # Espacio externo (del borde de pantalla)
    border_size = 3  # Grosor del borde
}
```

**Recomendaciones:**
- Minimalista: `gaps_in = 4, gaps_out = 8, border_size = 2`
- Espacioso (actual): `gaps_in = 8, gaps_out = 16, border_size = 3`
- Muy espacioso: `gaps_in = 12, gaps_out = 24, border_size = 4`

## 🎨 Personalizar Colores

### Cambiar Bordes

```bash
# Editar: ~/.config/hypr/configs/looknfeel.conf

# Borde sólido morado
col.active_border = rgb(9d4edd)

# Gradiente en 2 colores
col.active_border = rgb(c77dff) rgb(7b2cbf) 45deg

# Gradiente en 3 colores (actual)
col.active_border = rgb(c77dff) rgb(7b2cbf) rgb(5a189a) 45deg

# Gradiente en 4 colores
col.active_border = rgb(e0aaff) rgb(c77dff) rgb(7b2cbf) rgb(5a189a) 45deg
```

**Ángulos de gradiente:**
- `0deg` = horizontal →
- `45deg` = diagonal ↗
- `90deg` = vertical ↑
- `270deg` = diagonal ↙

### Paletas Alternativas

#### Palette 1: Deep Purple (Actual)
```conf
$primary = rgb(9d4edd)
$secondary = rgb(7b2cbf)
$accent = rgb(c77dff)
$background = rgb(10002b)
```

#### Palette 2: Lavender Dream
```conf
$primary = rgb(b19cd9)
$secondary = rgb(a480cf)
$accent = rgb(e8b4f0)
$background = rgb(1f1235)
```

#### Palette 3: Cosmic Blue-Purple
```conf
$primary = rgb(7209b7)
$secondary = rgb(560bad)
$accent = rgb(b5179e)
$background = rgb(0a0310)
```

#### Palette 4: Neon Purple
```conf
$primary = rgb(bf00ff)
$secondary = rgb(8000ff)
$accent = rgb(ff00ff)
$background = rgb(0d0015)
```

## ✨ Ajustar Animaciones

### Velocidad de Animaciones

```bash
# Editar: ~/.config/hypr/configs/UserAnimations.conf

# Más lentas (más dramático)
animation = windowsIn, 1, 8, spaceIn, popin 90%
animation = workspaces, 1, 10, space, slide

# Más rápidas (más snappy)
animation = windowsIn, 1, 3, spaceIn, popin 90%
animation = workspaces, 1, 4, space, slide

# Desactivar animaciones
animations {
    enabled = false
}
```

### Crear Tu Propia Bezier Curve

```conf
# Sintaxis: bezier = NOMBRE, x1, y1, x2, y2
bezier = custom, 0.25, 0.1, 0.25, 1

# Usar tu bezier
animation = windows, 1, 5, custom, slide
```

**Herramienta**: [cubic-bezier.com](https://cubic-bezier.com) para visualizar curvas

## 🪟 Opacidad y Blur

### Transparencia de Ventanas

```bash
# Editar: ~/.config/hypr/configs/looknfeel.conf

decoration {
    active_opacity = 0.98    # Ventana activa (0.0 - 1.0)
    inactive_opacity = 0.85  # Ventanas inactivas
    fullscreen_opacity = 1.0 # Fullscreen
}
```

### Reglas por Aplicación

```bash
# Editar: ~/.config/hypr/configs/windowrules.conf

# Terminal más transparente
windowrulev2 = opacity 0.80 0.70, class:^(kitty)$

# Navegador casi opaco
windowrulev2 = opacity 0.98 0.95, class:^(firefox)$

# VSCode transparente
windowrulev2 = opacity 0.90 0.85, class:^(code)$

# Discord muy transparente
windowrulev2 = opacity 0.85 0.75, class:^(discord)$
```

### Configuración de Blur

```bash
blur {
    enabled = true
    size = 8          # Tamaño del blur (1-20)
    passes = 3        # Calidad (1-10, más = mejor pero más CPU)
    vibrancy = 0.2    # Intensidad del color (0.0-1.0)
    contrast = 1.1    # Contraste (0.0-2.0)
    brightness = 1.0  # Brillo (0.0-2.0)
}
```

**Presets de Blur:**

- **Bajo (rendimiento)**: `size = 4, passes = 1`
- **Medio (equilibrado)**: `size = 6, passes = 2`
- **Alto (actual)**: `size = 8, passes = 3`
- **Ultra (estético)**: `size = 12, passes = 4`

## ⌨️ Personalizar Keybindings

```bash
# Editar: ~/.config/hypr/configs/keybinds.conf

# Cambiar tecla modificadora
$mainMod = SUPER  # Tecla Windows
# $mainMod = ALT  # Alt
# $mainMod = CTRL # Control

# Añadir keybindings custom
bind = $mainMod, T, exec, kitty                    # Super + T = Terminal
bind = $mainMod SHIFT, B, exec, firefox           # Super + Shift + B = Browser
bind = $mainMod, M, exec, spotify                 # Super + M = Music

# Ejecutar scripts personalizados
bind = $mainMod, F1, exec, ~/.config/hypr/scripts/theme-switcher.sh
bind = $mainMod, F2, exec, ~/.config/hypr/scripts/wallpaper-rotation.sh
```

## 🎭 Workspaces Personalizados

```bash
# Editar: ~/.config/hypr/configs/tags.conf

# Nombres descriptivos
workspace = 1, name:term    # Terminal
workspace = 2, name:web     # Navegador
workspace = 3, name:code    # IDE
workspace = 4, name:media   # Multimedia
workspace = 5, name:chat    # Comunicación

# Con iconos (requiere nerd font)
workspace = 1, name:  # Terminal
workspace = 2, name:  # Web
workspace = 3, name:  # Code
workspace = 4, name:  # Media
workspace = 5, name:  # Chat

# Workspaces persistentes (siempre visibles en waybar)
workspace = 1, persistent:true
workspace = 2, persistent:true
```

## 📱 Waybar

### Cambiar Posición

```bash
# Editar: ~/.config/waybar/config

"position": "top",      # top, bottom, left, right
"height": 32,           # Altura en píxeles
"margin": "10 10 0 10", # Márgenes (top right bottom left)
```

### Cambiar Módulos

```bash
# Añadir/quitar módulos en "modules-left", "modules-center", "modules-right"

"modules-left": ["custom/menu", "hyprland/workspaces"],
"modules-center": ["clock"],
"modules-right": ["pulseaudio", "network", "battery", "custom/swaync"],
```

### Cambiar Estilos

```bash
# Usar el selector de estilos
Super + Ctrl + B

# O manualmente
ln -sf ~/.config/waybar/style/islands.css ~/.config/waybar/style.css
pkill -SIGUSR2 waybar
```

## 🔔 Notificaciones (SwayNC)

### Posición y Tamaño

```bash
# Editar: ~/.config/swaync/config.json

{
    "positionX": "right",  # left, center, right
    "positionY": "top",    # top, center, bottom
    "width": 400,          # Ancho en píxeles
    "height": 600          # Alto
}
```

## 🎯 Tips de Optimización

### Para Mejor Rendimiento

```bash
# Reducir efectos visuales
decoration {
    blur { enabled = false }  # Desactivar blur
    drop_shadow = false       # Sin sombras
}

animations {
    enabled = false           # Sin animaciones
}

misc {
    vfr = true               # Variable framerate (ahorra CPU)
}
```

### Para Mejor Estética

```bash
# Aumentar gaps y blur
general {
    gaps_in = 12
    gaps_out = 24
    border_size = 4
}

decoration {
    blur {
        size = 12
        passes = 4
    }
}
```

## 🔄 Aplicar Cambios

Después de editar configs:

```bash
# Recargar Hyprland
hyprctl reload

# O solo recargar config específico
hyprctl keyword general:gaps_in 10
hyprctl keyword decoration:rounding 15

# Reiniciar waybar
pkill -SIGUSR2 waybar

# O reiniciar completamente
Super + R  # Ejecuta wbrestart.sh
```

## 📚 Recursos Adicionales

- [Hyprland Wiki](https://wiki.hyprland.org)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)
- [r/unixporn](https://reddit.com/r/unixporn) - Inspiración
- [Hyprland Discord](https://discord.gg/hyprland) - Soporte

---

💡 **Tip**: Haz backup antes de cambios grandes:
```bash
cp ~/.config/hypr/configs/looknfeel.conf{,.backup}
```
