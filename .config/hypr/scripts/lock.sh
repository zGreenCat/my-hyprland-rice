#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════
#  lock.sh — bloquea la sesión con el bloqueo con video (lockscreen/lock.js)
#  Si lock.js no logra bloquear o se cae, usa hyprlock como respaldo.
#  Lo lanzan hypridle (lock_cmd), SUPER+L y waybar.
#  Los mensajes van al journal: journalctl --user -t lockscreen
# ════════════════════════════════════════════════════════════════════════
set -u

LOCK_DIR="$HOME/.config/hypr/lockscreen"
LOCK_JS="$LOCK_DIR/lock.js"

pidof hyprlock >/dev/null && exit 0
pgrep -f "gjs -m $LOCK_JS" >/dev/null && exit 0

# lock.js cierra waybar al bloquear y lo relanza al desbloquear; si algo falla, no quedarse sin barra.
ensure_waybar() {
    sleep 2
    pgrep -x waybar >/dev/null && return
    logger -t lockscreen "waybar no volvió tras desbloquear; lo relanzo"
    hyprctl eval 'hl.exec_cmd("GDK_BACKEND=wayland waybar")' >/dev/null
}

fallback_hyprlock() {
    logger -t lockscreen "$1; lanzo hyprlock como respaldo"
    hyprlock
    ensure_waybar
    exit 0
}

[ -f "$LOCK_JS" ] || fallback_hyprlock "no existe $LOCK_JS"

export GST_PLUGIN_FEATURE_RANK="nvvp9dec:NONE,nvh264dec:NONE,nvh265dec:NONE,nvav1dec:NONE"
export VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.json
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json

LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so gjs -m "$LOCK_JS" 2> >(logger -t lockscreen)
rc=$?

[ "$rc" -eq 0 ] || fallback_hyprlock "lock.js terminó con código $rc"
ensure_waybar
