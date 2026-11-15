#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════
#  idle-inhibit.sh — interruptor "No bloquear" compartido por waybar y AGS
#  Mantiene un bloqueo de inactividad de systemd, que hypridle respeta
#  (ignore_systemd_inhibit = false por defecto). Se apaga al cerrar sesión.
#
#  idle-inhibit.sh on | off | toggle | status (JSON para waybar) | is-on
# ════════════════════════════════════════════════════════════════════════
set -u

PIDFILE="${XDG_RUNTIME_DIR:-/run/user/$UID}/idle-inhibit.pid"
WAYBAR_SIGNAL=9

running() {
    [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

start() {
    running && return 0
    setsid systemd-inhibit --what=idle --who="No bloquear" --why="Activado desde la barra o el centro de control" \
        --mode=block sleep infinity </dev/null >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    sleep 0.2
    if ! running; then
        rm -f "$PIDFILE"
        echo "idle-inhibit.sh: systemd-inhibit no arrancó" >&2
        return 1
    fi
}

stop() {
    if running; then
        kill -- -"$(cat "$PIDFILE")" 2>/dev/null || kill "$(cat "$PIDFILE")"
    fi
    rm -f "$PIDFILE"
}

notify_waybar() {
    pkill -RTMIN+"$WAYBAR_SIGNAL" -x waybar 2>/dev/null || true
}

case "${1:-}" in
    on) start; rc=$?; notify_waybar; exit $rc ;;
    off) stop; notify_waybar ;;
    toggle) if running; then stop; else start; fi; rc=$?; notify_waybar; exit $rc ;;
    is-on) running ;;
    status)
        if running; then
            printf '{"text":"󰅶","alt":"on","class":"on","tooltip":"No bloquear: activo"}\n'
        else
            printf '{"text":"󰛊","alt":"off","class":"off","tooltip":"No bloquear: inactivo"}\n'
        fi
        ;;
    *) echo "uso: idle-inhibit.sh on|off|toggle|status|is-on" >&2; exit 2 ;;
esac
