# ✅ Rediseño Completado: Ventana/Escena Ilustrada

## 🎯 Objetivo Alcanzado

Se rediseñó completamente el toggle de **switch pill horizontal** a **ventana/escena ilustrada vertical** con animación flip 3D.

---

## 🔄 Cambios Principales

### Antes (Switch Pill)
```
┌──────────────────────────┐
│  🐈‍⬛  ○────────  🐈     │  ← Pill horizontal
│     (Slider thumb)       │  ← 180x80px
└──────────────────────────┘
```
- Mini-gatos de 20x35px
- Thumb circular que se desliza
- Diseño de toggle switch clásico
- Opacidad para gatos inactivos

### Ahora (Ventana/Escena)
```
╔════════════════════╗
║  ⭐   🌙    ⭐    ║  ← Cielo nocturno
║                    ║
║──────────────────  ║  ← Travesaño
║                    ║
║   ⛰️  ⛰️  ⛰️       ║  ← Montañas
║      🐈‍⬛           ║  ← Gato negro grande
╚════════════════════╝
    Dark Mode

     ↓ (Flip 3D)

╔════════════════════╗
║       ☀️          ║  ← Cielo diurno
║                    ║
║──────────────────  ║  ← Travesaño
║                    ║
║    🌸  🌼          ║  ← Césped con flores
║      🐈           ║  ← Gato naranja grande
╚════════════════════╝
    Light Mode
```
- Gatos tamaño original 50x140px
- Escenas completas ilustradas
- Flip 3D de tarjeta
- Elementos adicionales (luna, sol, montañas, etc.)
- Dimensiones: 280x420px

---

## 📦 Archivos Modificados

### 1. `cat-theme-toggle.html` (Reescrito completamente)
**Antes:** 277 líneas con mini-gatos y pill switch  
**Ahora:** 710 líneas con ventana/escena completa

**Nuevos elementos:**
```html
<!-- Escena Nocturna -->
<div class="scene scene--dark">
    <div class="window-frame"></div>
    <div class="stars">...</div>
    <div class="moon"></div>
    <div class="mountains">...</div>
    <div class="kitty"><div class="ear"></div></div>
    <div class="mode-label">Dark Mode</div>
</div>

<!-- Escena Diurna -->
<div class="scene scene--light">
    <div class="window-frame"></div>
    <div class="sun"></div>
    <div class="ground"></div>
    <div class="kitty"><div class="ear"></div></div>
    <div class="mode-label">Light Mode</div>
</div>
```

**CSS principal:**
- `.theme-toggle`: Contenedor con perspective 3D
- `.scenes-container`: Contenedor con transform-style: preserve-3d
- `.scene--dark / --light`: Escenas con backface-visibility: hidden
- Flip con `transform: rotateY(180deg)`

### 2. `windowrules.conf` (Actualizado)
```diff
- windowrule = size 200 120, title:^(Cat Theme Toggle)$
+ windowrule = size 280 420, title:^(Cat Theme Toggle)$

- windowrule = noanim, title:^(Cat Theme Toggle)$
+ windowrule = animation slide, title:^(Cat Theme Toggle)$

- windowrule = opacity 0.95, title:^(Cat Theme Toggle)$
+ windowrule = opacity 0.98, title:^(Cat Theme Toggle)$
```

### 3. Documentación Nueva
- ✅ `WINDOW_SCENE_DESIGN.md` - Guía completa del nuevo diseño
- ✅ `CAT_THEME_TOGGLE.md` - Actualizado con info de ventana/escena
- ✅ `README.md` - Keybind actualizado

---

## 🎨 Estructura CSS Reutilizada

Del `style.css` original:

| Elemento Original | Uso en el Toggle | Cambios |
|-------------------|------------------|---------|
| `.kitty` | `.kitty` | ✅ **Mismo código, tamaño original** |
| `.kitty::before` | `.kitty::before` | ✅ Torso redondeado |
| `.kitty::after` | `.kitty::after` | ✅ Cola animada |
| `@keyframes tail` | `@keyframes tail-wag` | ✅ Preservado (4s) |
| `.ear` | `.ear` | ✅ Orejas con triángulos |
| `.moon` | `.moon` | ✅ Luna creciente |
| `.star` | `.star` | ✅ Estrellas parpadeantes |
| `@keyframes twinkle` | `@keyframes twinkle` | ✅ Preservado (2s) |
| `.mountain-1/2` | `.mountain` | ✅ Montañas simplificadas |
| `.window` + `.window:before/after` | `.window-frame` + pseudoelementos | ✅ Marco adaptado |

**Elementos nuevos (no en original):**
- ☀️ `.sun` - Sol con rayos radiales
- 🏜️ `.ground` - Césped con gradient
- 🌸 Flores decorativas (emojis CSS)
- 🎴 Sistema flip 3D completo
- 📝 `.mode-label` - Labels dinámicos

---

## 🔧 Puntos de Personalización Documentados

### En el HTML (`cat-theme-toggle.html`):

#### 1. Colores del Cielo
```css
/* Línea ~75 - Cielo nocturno */
.scene--dark {
    background: linear-gradient(180deg, 
        #0a0e27 0%,      /* TODO: Cambia aquí */
        #1a1f3a 50%,
        #29467a 100%
    );
}

/* Línea ~88 - Cielo diurno */
.scene--light {
    background: linear-gradient(180deg, 
        #87ceeb 0%,      /* TODO: Cambia aquí */
        #ffd89b 40%,
        #ffa751 100%
    );
}
```

#### 2. Colores de los Gatos
```css
/* Línea ~204 */
.scene--dark .kitty {
    background-color: #2d2623;  /* TODO: Gato negro */
}

/* Línea ~208 */
.scene--light .kitty {
    background-color: #ff8c42;  /* TODO: Gato naranja */
}
```

#### 3. Velocidad de Animaciones
```css
/* Línea ~50 - Velocidad del flip */
transition: transform 0.8s;  /* TODO: 0.5s rápido, 1.2s lento */

/* Línea ~238 - Velocidad de cola */
animation: tail-wag 4s;  /* TODO: 3s rápido, 6s lento */

/* Línea ~360 - Velocidad de estrellas */
animation: twinkle 2s;  /* TODO: 1s rápido, 4s lento */
```

#### 4. Tamaño de la Ventana
```css
/* Línea ~27 */
.theme-toggle {
    width: 280px;   /* TODO: Ancho */
    height: 420px;  /* TODO: Alto */
}
```

---

## ✨ Características del Nuevo Diseño

### Ventajas:
1. ✅ **Escena completa**: No solo gatos, sino toda una ilustración
2. ✅ **Gatos tamaño original**: Más detalles visibles (orejas, cola, etc.)
3. ✅ **Efecto 3D**: Flip de tarjeta más impresionante que slide
4. ✅ **Contexto visual**: Luna/Sol indican claramente día/noche
5. ✅ **Marco de ventana**: Da sensación de "mirar por una ventana"
6. ✅ **Elementos decorativos**: Estrellas, montañas, flores añaden profundidad
7. ✅ **Colores del gato originales**: Negro oscuro y naranja brillante bien diferenciados

### Comparación de Tamaños:

| Elemento | Antes (Pill) | Ahora (Ventana) |
|----------|--------------|-----------------|
| Widget total | 180x80px | 280x420px |
| Gatos | 20x35px | 50x140px |
| Áreas clickeables | Toda la pill | Toda la ventana |
| Elementos visuales | 2 gatos + thumb | 2 escenas completas |

---

## 🚀 Cómo Usar

### 1. Activar Toggle
```bash
Super + T
```

### 2. Flujo Visual
1. Presionas Super+T
2. Aparece ventana con marco de madera
3. Si está en **Dark Mode**:
   - Ves escena nocturna (cielo azul, estrellas, luna, montañas, gato negro)
4. La ventana **gira en 3D** (flip en eje Y, 0.8s)
5. Ahora está en **Light Mode**:
   - Ves escena diurna (cielo naranja/celeste, sol, césped, flores, gato naranja)
6. Wallpaper del sistema cambia con transición circular (swww)
7. Ventana se cierra automáticamente en 2 segundos

### 3. Elementos Animados Durante la Transición
- Cola del gato moviéndose (4s loop)
- Estrellas parpadeando (2s loop, solo modo oscuro)
- Flip 3D de la tarjeta (0.8s)
- Fade in inicial (0.4s)

---

## 🎬 Demostración del Flip 3D

```
Vista lateral de la animación:

  t=0.0s          t=0.2s          t=0.4s          t=0.6s          t=0.8s
┌─────────┐    ┌────────┐      ┌──────┐       ┌────────┐    ┌─────────┐
│ 🌙  🐈‍⬛ │    │   ║   │      │  ║  │       │   ║   │    │ ☀️  🐈  │
│   ⭐    │    │   ║   │      │  ║  │       │   ║   │    │  🌸🌼   │
└─────────┘    └────────┘      └──────┘       └────────┘    └─────────┘
 (Frente)       (70deg)        (90deg)         (110deg)      (Reverso)
 Visible        Girando        Borde           Girando       Visible
```

**Técnica CSS:**
```css
/* Perspectiva en contenedor padre */
perspective: 1200px;

/* Transform 3D en contenedor de escenas */
transform-style: preserve-3d;
transform: rotateY(180deg);

/* Ocultar cara trasera */
backface-visibility: hidden;
```

---

## 📚 Documentación Relacionada

- **`WINDOW_SCENE_DESIGN.md`** - Detalles completos del diseño de ventana/escena
- **`CAT_THEME_TOGGLE.md`** - Guía de uso y configuración general
- **`CSS_CAT_ADAPTATION.md`** - Cómo se adaptó el CSS original
- **`cat-theme-toggle.html`** - Código fuente con comentarios TODO

---

## 🎯 Próximos Pasos Sugeridos

### Si quieres personalizar:
1. Abre `cat-theme-toggle.html`
2. Busca comentarios `/* TODO: ... */`
3. Cambia colores, tamaños, velocidades según tu gusto
4. Copia a `~/.config/hypr/scripts/`
5. Prueba con `Super + T`

### Variantes interesantes:
- **Atardecer/Amanecer**: Cielo rojo/naranja, gato rojo oscuro
- **Noche profunda**: Cielo negro puro, más estrellas
- **Día nublado**: Cielo gris, sol parcialmente cubierto
- **Escena marina**: Olas, peces, gato en muelle

---

¡Disfruta tu nueva ventana/escena ilustrada con gatos! 🪟🐈‍⬛🐈
