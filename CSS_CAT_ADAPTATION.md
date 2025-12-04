# 🎨 Adaptación del Gato CSS Original a Mini-Gatos

## 📋 Mapeo de Elementos

Este documento explica cómo se adaptó el gato grande de `style.css` a los mini-gatos del toggle.

---

## 🔄 Elementos Reutilizados

### ✅ Del gato original (`style.css`) → Mini-gato (`cat-theme-toggle.html`)

| Elemento Original | Líneas CSS | Adaptado Como | Líneas HTML | Cambios |
|------------------|------------|---------------|-------------|---------|
| `.kitty` | 86-93 | `.mini-kitty__body` | 101-109 | ✅ Reducido de 50x140px a 20x35px |
| `.kitty:before` (torso) | 94-103 | `.mini-kitty__body::before` | 112-121 | ✅ Reducido de 40x80px a 12x20px |
| `.kitty:after` (cola) | 104-115 | `.mini-kitty__body::after` | 124-135 | ✅ Reducido de 10x80px a 4x20px, animación preservada |
| `@keyframes tail` | 116-120 | `@keyframes tail-wag` | 137-143 | ✅ Renombrado, timing ajustado de 4s a 3s |
| `.ear` | 121-128 | `.mini-kitty__ear` | 146-153 | ✅ Reducido triángulo de 40px a 15px |
| `.ear:before` | 129-137 | `.mini-kitty__ear::before` | 155-163 | ✅ Segunda oreja, reducida proporcionalmente |

### ⚠️ Elementos Simplificados

| Elemento | Cambio | Razón |
|----------|--------|-------|
| Ojos | Agregados desde cero (`.mini-kitty__eyes`) | El original no tenía ojos visibles |
| Nariz | No implementada | Muy pequeña a esta escala (opcional) |
| Patas | No implementadas | No visibles en el gato original de ventana |

---

## ❌ Elementos NO Reutilizados (escena completa)

Estos elementos eran parte de la **escena de la ventana**, no del gato en sí:

| Elemento | Líneas CSS | Razón de Exclusión |
|----------|------------|-------------------|
| `.window` | 16-27 | Marco de ventana, no necesario |
| `.window:before` / `:after` | 28-44 | Bordes decorativos de ventana |
| `.mountain-1` / `.mountain-2` | 45-81 | Montañas del fondo |
| `.moon` | 139-146 | Luna en el cielo |
| `.star` | 147-153 | Estrellas con animación twinkle |
| `@keyframes twinkle` | 154-158 | Animación de estrellas |
| `body { background }` | 1-4 | Color de fondo general |
| `.container` | 5-14 | Contenedor de la escena completa |

---

## 🎨 Variantes de Color

### Gato Original (estilo único)
```css
background-color: #2d2623;  /* Marrón/negro oscuro */
```

### Mini-Gatos (dos variantes)

#### Gato Negro (Dark Mode)
```css
.mini-kitty--dark .mini-kitty__body {
    background-color: #2d2623;  /* Mismo color del original */
}
```

#### Gato Naranja (Light Mode)
```css
.mini-kitty--light .mini-kitty__body {
    background-color: #ff8c42;  /* Naranja nuevo */
}
```

---

## 📐 Escalado de Dimensiones

### Fórmula de Conversión

El gato original medía **~50x140px** (ancho x alto).  
Los mini-gatos miden **20x35px**.

**Factor de escala:** ~0.4x (40% del tamaño original)

| Medida Original | Medida Mini-Gato | Cálculo |
|----------------|------------------|---------|
| Cuerpo: 50px ancho | 20px | 50 * 0.4 = 20 |
| Cuerpo: 140px alto | 35px | 140 * 0.25 = 35 |
| Torso: 40px ancho | 12px | 40 * 0.3 = 12 |
| Cola: 10px ancho | 4px | 10 * 0.4 = 4 |
| Orejas: 40px alto | 15px | 40 * 0.375 = 15 |
| Border-radius: 40px | 10px | 40 * 0.25 = 10 |

**Nota:** No todas las proporciones son lineales. Algunos elementos se ajustaron visualmente para que el gato se vea bien a escala pequeña.

---

## ✨ Nuevas Animaciones Añadidas

Estas animaciones NO estaban en el gato original:

### 1. Ear Wiggle (Movimiento de Orejas)
```css
@keyframes ear-wiggle {
    0%, 100% { transform: rotate(0deg); }
    25% { transform: rotate(-5deg); }
    75% { transform: rotate(5deg); }
}
```
**Activación:** `:hover` en el gato activo

### 2. Eye Glow (Ojos Brillantes)
```css
.mini-kitty__eye {
    background-color: #ffd700;
    box-shadow: 0 0 6px #ffd700;  /* Efecto glow */
    opacity: 0;  /* Ocultos por defecto */
    transition: opacity 0.3s ease;
}
```
**Activación:** Cuando el gato está activo (tema seleccionado)

### 3. Fade In/Out de Gatos Inactivos
```css
body.dark .cat-right,
body.light .cat-left {
    opacity: 0.3;
    filter: grayscale(0.6);
}
```

---

## 🛠️ Cómo Personalizar los Mini-Gatos

### Cambiar tamaño general:
Edita estas variables en `.mini-kitty` (línea 101):
```css
.mini-kitty {
    width: 20px;   /* Ancho base */
    height: 35px;  /* Alto base */
}
```

Luego ajusta proporcionalmente:
- `.mini-kitty__body` (cuerpo principal)
- `.mini-kitty__body::before` (torso lateral)
- `.mini-kitty__body::after` (cola)
- `.mini-kitty__ear` (orejas)

### Cambiar velocidad de animación de cola:
```css
/* Línea 119 */
animation: tail-wag 3s ease-in-out infinite;
/*                  ^^^ Cambia este valor (2s = más rápido, 5s = más lento) */
```

### Añadir más detalles:
Puedes agregar:
- **Bigotes:** Líneas delgadas con `::after` en `.mini-kitty__body`
- **Nariz:** Círculo pequeño con `border-radius: 50%`
- **Patas:** Rectángulos pequeños en `bottom: 0`
- **Manchas:** Elementos posicionados absolutamente con `border-radius`

---

## 📊 Comparación Visual

```
┌─────────────────────────────────────────────────────┐
│  GATO ORIGINAL (style.css)                          │
│  ┌─────────────────┐                                │
│  │    Ventana      │  50x140px                      │
│  │   ┌─────────┐   │  Escala 1:1                    │
│  │   │  🐱🌙   │   │  Color: #2d2623                │
│  │   │ /\_/\   │   │  Animación: tail 4s            │
│  │   │ (o o)   │   │                                │
│  │   │  = Y =  │   │                                │
│  │   │ (>   )> │   │                                │
│  │   └─────────┘   │                                │
│  └─────────────────┘                                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  MINI-GATOS (cat-theme-toggle.html)                 │
│  ┌──────────────────────────────────────────┐       │
│  │  [🐱]  ═══════════════ [🐱]  │  20x35px  │       │
│  │  Dark      (Slider)      Light           │       │
│  │ #2d2623     [⚪]      #ff8c42            │       │
│  └──────────────────────────────────────────┘       │
│  Escala: ~0.4x                                      │
│  Animación: tail-wag 3s                             │
└─────────────────────────────────────────────────────┘
```

---

## 💡 Sugerencias de Mejora

### Fácil:
- ✅ Cambiar colores (ver sección de colores en `CAT_THEME_TOGGLE.md`)
- ✅ Ajustar velocidad de animaciones (cambiar valores `3s`, `0.3s`, etc.)
- ✅ Modificar tamaño del widget completo

### Intermedio:
- 🔄 Añadir más poses de gato (sentado, acostado, estirándose)
- 🔄 Crear más variantes de color (gato gris, café, blanco)
- 🔄 Sincronizar animación de cola con eventos (hover, click)

### Avanzado:
- 🚀 Múltiples gatos en el toggle (3+ temas)
- 🚀 Animación de transición entre gatos (morph CSS)
- 🚀 Gatos que reaccionan al mouse (ojos siguiendo cursor)
- 🚀 Efectos de partículas al cambiar tema

---

## 📚 Referencias

**Código original:**
- `index.html` - Estructura HTML del gato en ventana
- `style.css` - Estilos CSS completos con escena

**Código adaptado:**
- `.config/hypr/scripts/cat-theme-toggle.html` - Mini-gatos integrados
- `.config/hypr/scripts/cat-theme-widget.py` - Launcher GTK WebKit

**Documentación:**
- `CAT_THEME_TOGGLE.md` - Guía completa de uso y personalización
- `README.md` - Documentación general del rice
