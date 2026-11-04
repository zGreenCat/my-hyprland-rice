#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🌌 Wallpaper Rotation Script
#  Cambia automáticamente entre wallpapers cada cierto tiempo
# ════════════════════════════════════════════════════════════════════════

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
INTERVAL=3600  # Segundos (3600 = 1 hora)
LOG_FILE="$HOME/.cache/wallpaper-rotation.log"

# Crear directorio de log si no existe
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

change_wallpaper() {
    # Obtener lista de wallpapers
    local wallpapers=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,gif})
    
    # Verificar que hay wallpapers
    if [ ${#wallpapers[@]} -eq 0 ]; then
        log_message "ERROR: No se encontraron wallpapers en $WALLPAPER_DIR"
        return 1
    fi
    
    # Seleccionar wallpaper aleatorio
    local random_wall="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    
    # Verificar que el archivo existe
    if [ ! -f "$random_wall" ]; then
        log_message "ERROR: Archivo no válido: $random_wall"
        return 1
    fi
    
    # Cambiar wallpaper con awww (solo imagen, no toca los colores del tema)
    log_message "Cambiando a: $(basename "$random_wall")"
    if ! pgrep -x awww-daemon > /dev/null; then
        awww-daemon &
        sleep 0.5
    fi
    awww img "$random_wall" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-fps 60 \
        --transition-duration 1.2 \
        --transition-bezier 0.25,0.1,0.25,1.0

    # Persistir para restaurar en boot
    ln -sf "$random_wall" "$HOME/.config/hypr/current_wallpaper"

    # Notificar al usuario
    notify-send -i "$random_wall" "🌌 Wallpaper cambiado" \
        "$(basename "$random_wall")" -t 3000
}

# Log de inicio
log_message "════════════════════════════════════════"
log_message "Iniciando rotación de wallpapers"
log_message "Intervalo: $INTERVAL segundos"
log_message "Directorio: $WALLPAPER_DIR"

# Cambiar inmediatamente al iniciar
change_wallpaper

# Loop infinito
while true; do
    sleep "$INTERVAL"
    change_wallpaper
done
