# 📝 Changelog

Todos los cambios notables en este proyecto serán documentados aquí.

## [Unreleased]

### 🎯 Por Hacer
- [ ] Añadir más wallpapers espaciales
- [ ] Crear video demo del rice
- [ ] Screenshots en alta calidad
- [ ] Documentar más keybindings personalizados
- [ ] Integración con Spotify (spicetify theme)
- [ ] Tema custom para Discord (vesktop)

---

## [1.0.0] - 2025-12-01

### 🎉 Release Inicial - Space Hyprland Rice

#### ✨ Añadido
- **Configuración modular de Hyprland**
  - hyprland.conf principal con estructura limpia
  - Configs separados por función (keybinds, looknfeel, animations, etc.)
  - Source de archivos para mejor organización

- **Tema Espacial Morado**
  - Palette base morada (`colors-base.conf`)
  - Bordes con gradiente en 3 tonos morados
  - Gaps amplios (8/16) para estética espacial
  - Blur estilo cristal con vibrancy
  - Sombras suaves con color personalizado
  - Dim ligero en ventanas inactivas

- **Animaciones Suaves**
  - 7 bezier curves personalizadas
  - Efecto flotante tipo espacial
  - Transiciones de fade muy suaves
  - Movimientos tipo "floating in space"

- **Scripts Personalizados**
  - `wallpaper-rotation.sh` - Rotación automática con logging
  - `theme-switcher.sh` - 4 variantes de tema (Deep Space, Nebula, Cosmic, Lofi)
  - `wppicker.sh` - Selector de wallpapers con preview
  - `sync-configs.sh` - Sincronizar configs al repo
  - Scripts de volumen, brillo, screenshots (del repo base)

- **Documentación Completa**
  - README.md con instrucciones detalladas
  - DEPENDENCIES.md con todos los paquetes necesarios
  - QUICKSTART.md para empezar rápido
  - WALLPAPERS.md con colección curada de wallpapers
  - Guías de instalación automática y manual

- **Herramientas**
  - `install.sh` - Instalador automático con backups
  - Script de sincronización bidireccional
  - Estructura de carpetas organizada

- **Integración con Matugen**
  - Generación automática de colores desde wallpapers
  - Templates para 8 aplicaciones
  - Post-hooks para reload automático

- **Waybar Customizado**
  - Múltiples layouts (5 opciones)
  - Múltiples estilos (4 opciones)
  - Colores sincronizados con Matugen

- **Otros Componentes**
  - SwayNC configurado con iconos custom
  - Wlogout con tema espacial
  - Rofi con colores dinámicos
  - Kitty terminal configurado
  - Hyprlock y Hypridle setup

#### 🎨 Paletas de Color
- **Deep Space**: Morado muy oscuro (#10002b base)
- **Nebula**: Morado medio vibrante (#9d4edd primary)
- **Cosmic**: Morado claro luminoso (#c77dff accent)
- **Lofi**: Tonos pastel morados (#b19cd9)

#### 📦 Wallpapers
- 4 wallpapers espaciales de ejemplo incluidos
- Guía para encontrar más wallpapers morados
- Lista curada de fuentes (Unsplash, Wallhaven, etc.)
- Prompts para generar con AI

#### ⌨️ Keybindings Principales
- `Super + W` - Selector de wallpapers
- `Super + D` - Rofi app launcher
- `Super + Return` - Terminal
- `Super + L` - Lock screen
- `Super + N` - Toggle notificaciones
- `Print` - Screenshot área
- Y muchos más...

---

## [0.1.0] - 2025-12-01

### 🚀 Setup Inicial
- Estructura básica del repositorio
- Copia de configs del repo base
- README inicial
- Gitignore configurado

---

## Formato

Este changelog sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

### Tipos de Cambios
- `✨ Añadido` para funcionalidades nuevas
- `🔧 Cambiado` para cambios en funcionalidades existentes
- `❌ Deprecado` para funcionalidades que serán removidas
- `🗑️ Removido` para funcionalidades removidas
- `🐛 Arreglado` para bugs corregidos
- `🔒 Seguridad` para vulnerabilidades
