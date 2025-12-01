# 🚀 Guía de Inicio Rápido

## Para empezar a personalizar tu rice

### 1. Hacer tu primer commit
```bash
cd /home/zgreencat/rice_repos/arch-hyprland/my-hyprland-rice

# Ver el estado
git status

# Añadir todos los archivos
git add .

# Commit inicial con todas las configs base
git commit -m "feat: Setup inicial con configs base"
```

### 2. Conectar con GitHub

```bash
# Crear repo en GitHub primero (github.com/new)
# Luego conectar:
git remote add origin https://github.com/TU_USUARIO/my-space-hyprland.git
git branch -M main
git push -u origin main
```

### 3. Añadir tus wallpapers espaciales

```bash
# Descargar wallpapers espaciales/lofi/morados
# Guardarlos en:
cd wallpapers/

# Luego commitear
git add wallpapers/
git commit -m "feat: Añadir wallpapers espaciales"
git push
```

### 4. Probar el sistema de colores

```bash
# Seleccionar un wallpaper (Super + W)
# O manualmente:
matugen image ~/Pictures/wallpapers/tu-wallpaper.jpg

# Los colores se generarán automáticamente
# Verás el cambio en waybar, kitty, rofi, etc.
```

### 5. Personalizar colores base morados

Edita: `~/.config/hypr/colors.conf`

```conf
# Ajusta estos valores para tu palette morada preferida
$primary = rgb(9d4edd)      # Morado vibrante
$secondary = rgb(7b2cbf)    # Morado oscuro
$accent = rgb(c77dff)       # Morado claro
$background = rgb(10002b)   # Casi negro morado
```

Luego:
```bash
hyprctl reload
```

### 6. Workflow diario

```bash
# Cada vez que cambies algo en tu sistema:

# 1. Sincronizar al repo
cd ~/my-hyprland-rice
./sync-configs.sh

# 2. Ver qué cambió
git diff

# 3. Commitear con mensaje descriptivo
git add .
git commit -m "feat: Cambiar animaciones a estilo espacial"

# 4. Pushear a GitHub
git push
```

### 7. Tomar screenshots

```bash
# Screenshot de área (Print o grim + slurp)
grim -g "$(slurp)" ~/my-hyprland-rice/screenshots/mi-setup.png

# Añadir al repo
git add screenshots/
git commit -m "docs: Añadir screenshots del setup"
git push
```

### 8. Probar diferentes estilos de waybar

```bash
# En tu sesión de Hyprland:
Super + Ctrl + B  # Abrir menú de estilos

# Probar:
# - islands: Módulos flotantes
# - full bar: Barra completa tradicional
# - bintang default: Compacto

# El que más te guste, será tu default
```

## 📝 Tips

1. **Commits frecuentes**: Cada cambio que funcione → commit
2. **Mensajes descriptivos**: 
   - `feat: ` para nuevas funcionalidades
   - `fix: ` para correcciones
   - `docs: ` para documentación
   - `style: ` para cambios visuales
3. **Branches para experimentos**: 
   ```bash
   git checkout -b experimental-animations
   # Probar cosas locas
   git checkout main  # Volver a lo que funciona
   ```
4. **Backup antes de cambios grandes**:
   ```bash
   git tag backup-$(date +%Y%m%d)
   git push --tags
   ```

## 🎯 Próximos pasos

1. ✅ Añadir más wallpapers espaciales
2. ✅ Personalizar colores morados base
3. ✅ Ajustar animaciones a tu gusto
4. ✅ Tomar screenshots de tu setup
5. ✅ Documentar tus keybindings personalizados
6. ✅ Añadir tus scripts propios
7. ✅ Compartir en r/unixporn cuando esté listo 😎

## 🆘 Comandos útiles

```bash
# Recargar Hyprland sin cerrar sesión
hyprctl reload

# Reiniciar waybar
pkill waybar && waybar &

# Ver logs de Hyprland
journalctl --user -u hyprland -f

# Verificar errores en hyprland.conf
hyprctl config

# Listar todas las ventanas y sus clases
hyprctl clients
```

¡Listo para empezar! 🚀
