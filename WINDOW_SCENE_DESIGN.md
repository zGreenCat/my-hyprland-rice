# 🪟 Diseño del Toggle: Ventana/Escena Ilustrada

## 📐 Concepto de Diseño

El toggle NO es un switch pill tradicional. Es una **ventana/tarjeta ilustrada** que muestra dos escenas completas que representan el tema actual.

### Metáfora Visual:
- **Ventana con marco de madera** que muestra una vista
- **Escena Nocturna** (Dark Mode): Cielo estrellado + Luna + Gato Negro
- **Escena Diurna** (Light Mode): Cielo soleado + Sol + Gato Naranja
- **Transición**: Flip 3D de la tarjeta (como si la ventana tuviera dos caras)

---

## 🎨 Estructura de las Escenas

### 🌙 Escena Nocturna (Dark Mode)

```
┌─────────────────────────────────┐
│  ╔═════════════════════════╗  │
│  ║  ⭐    🌙    ⭐         ║  │  ← Cielo azul oscuro
│  ║                         ║  │  ← Estrellas parpadeantes
│  ║───────────────────────  ║  │  ← Travesaño horizontal
│  ║                         ║  │
│  ║     ⛰️  ⛰️  ⛰️          ║  │  ← Montañas
│  ║        🐈‍⬛              ║  │  ← Gato negro
│  ╚═════════════════════════╝  │  ← Marco de ventana
│         Dark Mode              │
└─────────────────────────────────┘
```

**Elementos:**
- **Fondo**: Gradient azul oscuro (#0a0e27 → #29467a)
- **Estrellas**: 5 puntos amarillos parpadeantes
- **Luna**: Creciente amarilla (#e8ae4a)
- **Montañas**: 4 triángulos azules (#22366d)
- **Gato**: Color #2d2623 (marrón muy oscuro)
- **Marco**: Madera café con bordes celestes

### ☀️ Escena Diurna (Light Mode)

```
┌─────────────────────────────────┐
│  ╔═════════════════════════╗  │
│  ║            ☀️           ║  │  ← Cielo celeste/naranja
│  ║                         ║  │
│  ║───────────────────────  ║  │  ← Travesaño horizontal
│  ║                         ║  │
│  ║     🌸  🌼              ║  │  ← Césped con flores
│  ║        🐈              ║  │  ← Gato naranja
│  ╚═════════════════════════╝  │  ← Marco de ventana
│         Light Mode             │
└─────────────────────────────────┘
```

**Elementos:**
- **Fondo**: Gradient celeste/naranja (#87ceeb → #ffa751)
- **Sol**: Círculo amarillo brillante con rayos (#ffeb3b)
- **Césped**: Gradient verde (#7cb342 → #558b2f)
- **Flores**: Emojis decorativos 🌸 🌼
- **Gato**: Color #ff8c42 (naranja brillante)
- **Marco**: Mismo que escena nocturna

---

## 🔄 Animación de Transición

### Efecto Flip 3D (Tarjeta Giratoria)

```
Vista Superior:
                              
   Dark Mode        →  Girando  →    Light Mode
  ┌─────────┐       ┌───────┐       ┌─────────┐
  │ 🌙  🐈‍⬛ │       │   ║   │       │ ☀️  🐈  │
  │   ⭐    │       │   ║   │       │  🌸🌼   │
  └─────────┘       └───────┘       └─────────┘
    (0deg)          (90deg)          (180deg)
```

**Mecánica:**
1. **Estado inicial**: Escena nocturna visible (rotateY: 0deg)
2. **Al presionar Super+T**: Tarjeta gira en eje Y
3. **Durante rotación**: Se ve el "borde" de la tarjeta
4. **Estado final**: Escena diurna visible (rotateY: 180deg)
5. **Duración**: 0.8 segundos con easing suave

**CSS clave:**
```css
.scenes-container {
    transform-style: preserve-3d;
    transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

body.light .scenes-container {
    transform: rotateY(180deg);
}

.scene {
    backface-visibility: hidden;
}
```

---

## 🎯 Puntos de Personalización

### 1. Colores del Cielo

**Escena Nocturna** (línea ~75):
```css
.scene--dark {
    background: linear-gradient(180deg, 
        #0a0e27 0%,      /* TODO: Azul muy oscuro arriba */
        #1a1f3a 50%,     /* TODO: Azul medio */
        #29467a 100%     /* TODO: Azul más claro abajo */
    );
}
```

**Escena Diurna** (línea ~88):
```css
.scene--light {
    background: linear-gradient(180deg, 
        #87ceeb 0%,      /* TODO: Celeste claro arriba */
        #ffd89b 40%,     /* TODO: Amarillo suave */
        #ffa751 100%     /* TODO: Naranja abajo */
    );
}
```

### 2. Colores de los Gatos

**Gato Negro** (línea ~204):
```css
.scene--dark .kitty {
    background-color: #2d2623;  /* TODO: Marrón muy oscuro */
}
```

**Gato Naranja** (línea ~208):
```css
.scene--light .kitty {
    background-color: #ff8c42;  /* TODO: Naranja brillante */
}
```

### 3. Velocidad de Animaciones

**Flip de la tarjeta** (línea ~50):
```css
.scenes-container {
    transition: transform 0.8s;  /* TODO: Cambia 0.8s */
}
```

**Cola del gato** (línea ~238):
```css
animation: tail-wag 4s ease-in-out infinite;  /* TODO: Cambia 4s */
```

**Parpadeo de estrellas** (línea ~360):
```css
animation: twinkle 2s ease-in-out infinite;  /* TODO: Cambia 2s */
```

### 4. Elementos de la Escena

**Añadir más estrellas** (HTML línea ~598):
```html
<div class="stars">
    <div class="star"></div>
    <div class="star"></div>
    <div class="star"></div>
    <!-- TODO: Añade más <div class="star"></div> -->
</div>
```

**Cambiar posición de la luna** (línea ~316):
```css
.moon {
    top: 70px;   /* TODO: Altura */
    left: 60px;  /* TODO: Posición horizontal */
}
```

**Cambiar posición del sol** (línea ~393):
```css
.sun {
    top: 60px;    /* TODO: Altura */
    right: 50px;  /* TODO: Posición horizontal */
}
```

### 5. Tamaño de la Ventana

**Dimensiones** (línea ~27):
```css
.theme-toggle {
    width: 280px;   /* TODO: Ancho de la ventana */
    height: 420px;  /* TODO: Alto de la ventana */
}
```

**Ajustar marco interno** (línea ~107):
```css
.window-frame {
    width: 240px;   /* TODO: Ancho del marco */
    height: 360px;  /* TODO: Alto del marco */
}
```

---

## 🖼️ Elementos Reutilizados del CSS Original

| Elemento Original | En el Toggle | Cambios |
|-------------------|--------------|---------|
| `.kitty` | `.kitty` | ✅ Mismo código, diferentes colores |
| `.ear` | `.ear` | ✅ Orejas con triángulos CSS |
| `@keyframes tail` | `@keyframes tail-wag` | ✅ Animación de cola preservada |
| `.moon` | `.moon` | ✅ Luna creciente con box-shadow |
| `.star` | `.star` | ✅ Estrellas parpadeantes |
| `.mountain-1/2` | `.mountain` | ✅ Montañas con triángulos |
| `.window` | `.window-frame` | ✅ Marco de ventana adaptado |

**Nuevos elementos añadidos:**
- ☀️ Sol con rayos radiales
- 🏜️ Césped con gradient verde
- 🌸 Flores decorativas (emojis)
- 🎴 Sistema de flip 3D
- 📝 Labels dinámicos

---

## 🔧 Troubleshooting

### La ventana se ve muy grande/pequeña:
```css
/* Línea ~27 */
.theme-toggle {
    width: 280px;   /* Reduce/aumenta */
    height: 420px;  /* Reduce/aumenta */
}
```

### El flip es muy lento/rápido:
```css
/* Línea ~50 */
transition: transform 0.8s;  /* 0.5s = rápido, 1.2s = lento */
```

### Los colores no se ven bien:
Usa herramienta de picking de colores y reemplaza en secciones TODO marcadas.

### El gato no se ve centrado:
```css
/* Línea ~194 */
.kitty {
    left: 50%;  /* Centrado horizontal */
    transform: translateX(-50%);
}
```

### Quiero más/menos estrellas:
Añade o elimina `<div class="star"></div>` en HTML línea ~598.

---

## 📚 Comparación: Antes vs Ahora

| Aspecto | Antes (Pill Switch) | Ahora (Ventana/Escena) |
|---------|---------------------|------------------------|
| **Metáfora** | Toggle switch | Ventana con vista |
| **Diseño** | Pill horizontal + círculo | Tarjeta vertical ilustrada |
| **Gatos** | Mini-gatos (20x35px) | Gatos grandes (50x140px) |
| **Animación** | Slider lateral | Flip 3D de tarjeta |
| **Elementos** | Solo gatos + thumb | Escena completa (cielo, luna, montañas, etc.) |
| **Tamaño** | 180x80px | 280x420px |
| **Interacción** | Click en pill | Click en toda la ventana |
| **Reutilización CSS** | Mini-versiones | CSS original completo |

---

## 🎨 Galería de Variantes Sugeridas

### Variante 1: Atardecer/Amanecer
```css
/* Escena intermedia */
background: linear-gradient(180deg, #ff6b6b 0%, #feca57 50%, #ee5a6f 100%);
/* Gato: #d63031 (rojo oscuro) */
```

### Variante 2: Noche Profunda
```css
/* Cielo más oscuro */
background: linear-gradient(180deg, #000000 0%, #0c0c1e 50%, #1a1a3e 100%);
/* Más estrellas, luna más brillante */
```

### Variante 3: Día Nublado
```css
/* Cielo gris suave */
background: linear-gradient(180deg, #95a5a6 0%, #b4bbbf 50%, #d1d8e0 100%);
/* Sol parcialmente cubierto */
```

---

## 🚀 Futuras Mejoras Sugeridas

### Fácil:
- [ ] Añadir más estrellas con posiciones aleatorias
- [ ] Cambiar emojis de flores por flores CSS
- [ ] Ajustar sombras del marco de ventana

### Intermedio:
- [ ] Añadir nubes flotantes en escena diurna
- [ ] Pájaros volando en escena diurna
- [ ] Más montañas con diferentes alturas

### Avanzado:
- [ ] Efecto parallax (montañas + estrellas a diferente velocidad)
- [ ] Gatos con ojos que parpadean
- [ ] Transición de hora del día (amanecer/atardecer)
- [ ] Efectos de clima (lluvia, nieve)

---

**Documentación relacionada:**
- `CAT_THEME_TOGGLE.md` - Guía general de uso
- `CSS_CAT_ADAPTATION.md` - Detalles técnicos de adaptación
- `cat-theme-toggle.html` - Código fuente completo
