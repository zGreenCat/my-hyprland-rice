3# 🪟 Cat Theme Toggle - Documentación

## 📋 Descripción

Sistema de toggle de tema visual con **ventana/escena ilustrada** que cambia entre modo oscuro y claro con:
- ✅ **Escena nocturna completa**: Cielo estrellado + Luna + Gato Negro + Montañas
- ✅ **Escena diurna completa**: Cielo soleado + Sol + Gato Naranja + Césped
- ✅ Animación flip 3D de tarjeta (efecto ventana girando)
- ✅ Cambio de wallpaper con transición circular (swww)
- ✅ Integración completa con Matugen, GTK, Hyprland
- ✅ CSS reutilizado del gato original (`style.css`)

---

## 🎨 Componentes

### 1. Widget Visual (`cat-theme-widget.py` + `cat-theme-toggle.html`)
**Ubicación:** 
- `.config/hypr/scripts/cat-theme-widget.py` (launcher GTK WebKit)
- `.config/hypr/scripts/cat-theme-toggle.html` (UI HTML/CSS - VENTANA ILUSTRADA)

**Tecnología:** Python3 + GTK3 + WebKit2 + HTML5/CSS3

**Características:**
- **Ventana con marco de madera** (280x420px) mostrando escenas completas
- **Gatos tamaño original**: Reutilizados del `style.css` (50x140px)
- **Escena nocturna**: Gradient azul + Luna creciente + 5 estrellas parpadeantes + 4 montañas + Gato negro (#2d2623)
- **Escena diurna**: Gradient celeste/naranja + Sol radiante + Césped verde + Flores 🌸🌼 + Gato naranja (#ff8c42)
- **Flip 3D**: Transición suave de 0.8s rotando en eje Y (perspectiva 3D)
- **Animaciones**: Cola del gato (4s), parpadeo de estrellas (2s)
- **Marco de ventana**: Bordes de madera café con travesaños celestes
- **No es un switch**: Es una tarjeta/ventana que gira completa

### 2. Script de Cambio de Tema (`cat-theme-toggle.sh`)
**Ubicación:** `.config/hypr/scripts/cat-theme-toggle.sh`

**Funcionalidad:**
- Lee/guarda estado del tema en `~/.config/hypr/.theme-mode`
- Cambia wallpaper con transición circular usando `swww`
- Aplica tema a Matugen (generación de colores)
- Actualiza GTK theme
- Recarga Hyprland, Waybar, Kitty

---

## 🚀 Uso

### Keybind
```
Super + T  →  Abre widget de gatitos y cambia tema automáticamente
```

### Flujo de ejecución
```
1. Presionar Super + T
2. Widget se abre en el centro
3. Toggle automático dark ↔ light
4. Wallpaper cambia con transición circular (1.2s)
5. Sistema se reconfigura con nuevos colores
6. Widget se cierra automáticamente (2s)
```

---

## ⚙️ Configuración

### 📁 Wallpapers

**Editar:** `.config/hypr/scripts/cat-theme-toggle.sh` (líneas 16-17)

```bash
DARK_WALLPAPER="$WALLPAPER_DIR/cat-dark.png"      # Wallpaper oscuro
LIGHT_WALLPAPER="$WALLPAPER_DIR/cat-light.png"    # Wallpaper claro
```

**Crear wallpapers:**
```bash
mkdir -p ~/Pictures/wallpapers

# Opción 1: Descargar wallpapers con temática de gatos
# (buscar en wallhaven.cc con tags: cat, dark/light)

# Opción 2: Symlinks a wallpapers existentes
ln -s ~/Pictures/wallpapers/mi-wallpaper-oscuro.png ~/Pictures/wallpapers/cat-dark.png
ln -s ~/Pictures/wallpapers/mi-wallpaper-claro.jpg ~/Pictures/wallpapers/cat-light.png
```

### 🎨 Colores del Widget

**Editar:** `.config/hypr/scripts/cat-theme-toggle.html` (en la sección `<style>`)

#### Colores de fondo del contenedor:
```css
/* Estado Dark (línea ~39) */
body.dark .toggle-container {
    background: linear-gradient(135deg, #1a0f2e 0%, #2d1b4e 100%);
}

/* Estado Light (línea ~44) */
body.light .toggle-container {
    background: linear-gradient(135deg, #fff5e6 0%, #ffe4b8 100%);
}
```

#### Colores del Thumb (slider):
```css
/* Thumb Dark Mode (línea ~61) */
body.dark .thumb {
    background: linear-gradient(135deg, #9b7fd6 0%, #c9a8ff 100%);
}

/* Thumb Light Mode (línea ~67) */
body.light .thumb {
    background: linear-gradient(135deg, #ff9d5c 0%, #ffb380 100%);
}
```

#### Colores de los mini-gatos:
```css
/* Gato Negro (línea ~180) */
.mini-kitty--dark .mini-kitty__body {
    background-color: #2d2623;  /* Marrón muy oscuro */
}

.mini-kitty--dark .mini-kitty__eye {
    background-color: #ffd700;  /* Ojos amarillos/dorados */
    box-shadow: 0 0 6px #ffd700;
}

/* Gato Naranja (línea ~195) */
.mini-kitty--light .mini-kitty__body {
    background-color: #ff8c42;  /* Naranja brillante */
}

.mini-kitty--light .mini-kitty__eye {
    background-color: #4a9eff;  /* Ojos azules */
    box-shadow: 0 0 6px #4a9eff;
}
```

**Formato de colores CSS:**
- Hexadecimal: `#RRGGBB` (ej: `#ff8c42`)
- RGB: `rgb(255, 140, 66)`
- RGBA con transparencia: `rgba(255, 140, 66, 0.8)`

**Ejemplos de paletas:**
- Gato gris: `#6b6b6b`
- Gato café: `#8b4513`
- Gato blanco: `#f5f5f5`
- Ojos verdes: `#00ff7f`
- Ojos rojos: `#ff4444`

### 📏 Tamaños

**Editar:** `.config/hypr/scripts/cat-theme-toggle.html`

#### Tamaño del contenedor:
```css
/* Línea ~34 */
.toggle-container {
    width: 180px;    /* Ancho del pill card */
    height: 80px;    /* Alto del pill card */
    border-radius: 40px;  /* Redondez (la mitad del height para pill perfecto) */
}
```

#### Tamaño del Thumb (slider):
```css
/* Línea ~50 */
.thumb {
    width: 60px;     /* Ancho del círculo */
    height: 60px;    /* Alto del círculo */
    top: 10px;       /* Margen superior (centra verticalmente) */
}

/* Posiciones del thumb */
body.dark .thumb {
    left: 10px;      /* Posición izquierda (dark mode) */
}

body.light .thumb {
    left: 110px;     /* Posición derecha (light mode) */
}
```

#### Tamaño de los mini-gatos:
```css
/* Línea ~101 */
.mini-kitty {
    width: 20px;     /* Ancho del gato */
    height: 35px;    /* Alto del gato */
}

.mini-kitty__body {
    height: 35px;    /* Alto del cuerpo */
    width: 20px;     /* Ancho del cuerpo */
    border-radius: 10px 10px 0 0;  /* Redondez superior */
}
```

#### Ajustes de tiempo:
```javascript
/* Línea ~271 (en <script>) */
setTimeout(() => {
    if (window.close) window.close();
}, 2000);  /* Auto-cerrar después de 2000ms (2 segundos) */
```

```css
/* Línea ~121 (animación de cola) */
@keyframes tail-wag {
    /* ... */
}
/* Aplicada en línea ~119 */
animation: tail-wag 3s ease-in-out infinite;  /* 3 segundos por ciclo */
```

### 🌊 Transición de Wallpaper

**Editar:** `.config/hypr/scripts/cat-theme-toggle.sh` (líneas 77-83)

```bash
swww img "$WALLPAPER" \
    --transition-type grow \        # Tipo: grow/fade/wipe/etc
    --transition-pos 0.5,0.5 \      # Centro (0.5,0.5 = medio de pantalla)
    --transition-fps 60 \           # FPS de animación
    --transition-duration 1.2 \     # Duración en segundos
    --transition-bezier 0.25,0.1,0.25,1.0  # Curva de easing
```

**Tipos de transición disponibles:**
- `grow` - Circular expansion (recomendado)
- `fade` - Crossfade simple
- `wipe` - Wipe direccional
- `wave` - Efecto onda
- `outer` - Desde bordes al centro

**Posiciones del centro:**
- `0.0,0.0` - Esquina superior izquierda
- `0.5,0.5` - Centro de pantalla
- `1.0,1.0` - Esquina inferior derecha
- `0.5,0.0` - Centro arriba
- etc.

---

## 🔧 Integración con otros sistemas

### Añadir al Waybar (botón)

**Editar:** `.config/waybar/ModulesCustom`

```json
"custom/cat-theme": {
    "format": "🐈",
    "on-click": "python3 ~/.config/hypr/scripts/cat-theme-widget.py",
    "tooltip": true,
    "tooltip-format": "Toggle Dark/Light Theme"
}
```

Luego añadir `"custom/cat-theme"` a los modules en `config`.

### Usar desde terminal

```bash
# Toggle manual
~/.config/hypr/scripts/cat-theme-toggle.sh

# Forzar dark
~/.config/hypr/scripts/cat-theme-toggle.sh silent dark

# Forzar light
~/.config/hypr/scripts/cat-theme-toggle.sh silent light
```

### Detectar tema actual desde otro script

```bash
THEME=$(cat ~/.config/hypr/.theme-mode)
if [ "$THEME" = "light" ]; then
    echo "Modo claro activo"
else
    echo "Modo oscuro activo"
fi
```

---

## 🎯 Extensiones Futuras

### Añadir más temas (3+)

**Modificar:** `cat-theme-toggle.sh`

```bash
# En lugar de if/else, usar case:
case "$NEW_THEME" in
    dark)   WALLPAPER="$DARK_WALLPAPER" ;;
    light)  WALLPAPER="$LIGHT_WALLPAPER" ;;
    sunset) WALLPAPER="$SUNSET_WALLPAPER" ;;
    space)  WALLPAPER="$SPACE_WALLPAPER" ;;
esac
```

### Añadir más gatitos al widget

Editar función `draw_cat()` en `cat-theme-widget.py` para:
- Más colores de gatos
- Diferentes poses
- Accesorios (sombreros, lazos, etc.)

### Sincronizar con hora del día

```bash
# En cat-theme-toggle.sh, añadir:
HOUR=$(date +%H)
if [ $HOUR -ge 6 ] && [ $HOUR -lt 18 ]; then
    # Día (6am - 6pm)
    DEFAULT_THEME="light"
else
    # Noche
    DEFAULT_THEME="dark"
fi
```

---

## 🐛 Troubleshooting

### El wallpaper no cambia
```bash
# Verificar que swww-daemon esté corriendo
pgrep swww-daemon

# Si no está corriendo, iniciarlo:
swww-daemon &

# Probar manualmente:
swww img ~/Pictures/wallpapers/tu-wallpaper.jpg --transition-type grow
```

### El widget no abre
```bash
# Verificar dependencias:
python3 -c "import gi; gi.require_version('Gtk', '3.0'); gi.require_version('WebKit2', '4.0'); from gi.repository import WebKit2"

# Si falla GTK:
sudo pacman -S python-gobject gtk3

# Si falla WebKit2:
sudo pacman -S webkit2gtk

# Verificar que el HTML existe:
ls -la ~/.config/hypr/scripts/cat-theme-toggle.html
```

### Los colores no cambian
```bash
# Verificar que matugen funcione:
matugen image ~/Pictures/wallpapers/test.jpg

# Ver logs:
journalctl --user -xe | grep matugen
```

### El script no se ejecuta
```bash
# Hacer ejecutable:
chmod +x ~/.config/hypr/scripts/cat-theme-toggle.sh
chmod +x ~/.config/hypr/scripts/cat-theme-widget.py

# Probar manualmente:
python3 ~/.config/hypr/scripts/cat-theme-widget.py
```

---

## 📚 Referencias

- **swww**: https://github.com/LGFae/swww
- **Matugen**: https://github.com/InioX/matugen
- **GTK3 Cairo**: https://pycairo.readthedocs.io/
- **Hyprland windowrules**: https://wiki.hyprland.org/Configuring/Window-Rules/
