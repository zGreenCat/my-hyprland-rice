# 🌌 Space Wallpapers Collection

Esta carpeta contiene los wallpapers para tu rice espacial.

## 🎨 Temática

Enfocado en:
- 🪐 Planetas y sistemas solares
- 🌌 Nebulosas y galaxias
- 🌠 Estrellas y constelaciones
- 🎵 Lofi space aesthetic
- 💜 Tonos morados y violetas predominantes
- 🌃 Paisajes espaciales nocturnos

## 📥 Fuentes Recomendadas

### Unsplash (Gratis, Alta calidad)
```bash
# Buscar en: unsplash.com
- "purple nebula"
- "space lofi"
- "purple galaxy"
- "planets"
- "cosmic purple"
- "violet space"
```

### Wallhaven (Gratis con registro)
```bash
# URL: wallhaven.cc
# Filtros recomendados:
- Categoría: Space
- Colores: Violet, Purple
- Resolución: 1920x1080 o superior
- Purity: SFW
```

### Reddit
- r/wallpapers
- r/spaceporn
- r/MinimalWallpaper
- r/Amoledbackgrounds (usar filtro purple)

### ArtStation
```bash
# artstation.com
# Buscar:
- "lofi space"
- "cosmic art"
- "purple planet"
- "nebula illustration"
```

### Otros Sitios
- **Pexels**: pexels.com (buscar "purple space")
- **PixaBay**: pixabay.com
- **DeviantArt**: deviantart.com (tag: space, purple)

## 💻 Comandos Útiles

### Descargar desde terminal
```bash
# Con wget
wget "URL_DEL_WALLPAPER" -O ~/Pictures/wallpapers/nombre.jpg

# Con curl
curl -L "URL" -o ~/Pictures/wallpapers/nombre.jpg
```

### Optimizar tamaño (opcional)
```bash
# Instalar imagemagick si no lo tienes
sudo pacman -S imagemagick

# Redimensionar a 1920x1080
mogrify -resize 1920x1080^ -gravity center -extent 1920x1080 *.jpg
```

### Organizar por color
```bash
# Ver colores dominantes de una imagen
magick identify -verbose wallpaper.jpg | grep -A 10 "Histogram"
```

## 🎯 Tips para Elegir Wallpapers

1. **Colores oscuros**: Mejor para batería y ojos en la noche
2. **No muy busy**: Fondos simples hacen más legible el texto
3. **Resolución nativa**: Usa tu resolución de pantalla o superior
4. **Formato**: PNG para mejor calidad, JPG para menor tamaño
5. **Prueba con Matugen**: El generador de colores funciona mejor con imágenes con paletas claras

## 🔧 Uso

### Cambiar wallpaper con el picker
```bash
# Presiona Super + W
# O ejecuta:
~/.config/hypr/scripts/wppicker.sh
```

### Cambiar manualmente con matugen
```bash
matugen image ~/Pictures/wallpapers/tu-wallpaper.jpg
```

### Ver wallpaper actual
```bash
ls -l ~/.config/hypr/current_wallpaper
```

## 🎨 Colores que Funcionan Bien

Para que Matugen genere buenos colores morados:
- Wallpapers con predominancia de morado/violeta
- Imágenes con nebulosas (naturalmente moradas)
- Paisajes nocturnos con tonos fríos
- Arte lofi con paletas pastel

## 📦 Wallpapers Incluidos

Actualmente tienes 4 wallpapers de ejemplo. ¡Añade más!
