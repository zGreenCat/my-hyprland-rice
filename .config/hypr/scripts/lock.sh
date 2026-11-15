#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════
#  lock.sh — bloquea la sesión con el bloqueo con video (lockscreen/lock.js)
#  Si lock.js no logra bloquear o se cae, usa hyprlock como respaldo.
#  Lo lanza hypridle (lock_cmd); para bloquear a mano: loginctl lock-session
#  Los mensajes van al journal: journalctl --user -t lockscreen
# ════════════════════════════════════════════════════════════════════════
set -u

LOCK_DIR="$HOME/.config/hypr/lockscreen"
LOCK_JS="$LOCK_DIR/lock.js"

pidof hyprlock >/dev/null && exit 0
pgrep -f "gjs -m $LOCK_JS" >/dev/null && exit 0

if [ ! -f "$LOCK_JS" ]; then
    logger -t lockscreen "no existe $LOCK_JS; uso hyprlock"
    exec hyprlock
fi

export GST_PLUGIN_FEATURE_RANK="nvvp9dec:NONE,nvh264dec:NONE,nvh265dec:NONE,nvav1dec:NONE"
export VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.json
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json

LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so gjs -m "$LOCK_JS" 2> >(logger -t lockscreen)
rc=$?

if [ "$rc" -ne 0 ]; then
    logger -t lockscreen "lock.js terminó con código $rc; lanzo hyprlock como respaldo"
    exec hyprlock
fi
