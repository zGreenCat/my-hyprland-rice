#!/bin/bash
# hypridle: suspender por inactividad solo con batería; enchufado queda prendido para acceso remoto.
AC=/sys/class/power_supply/ADP1/online
if [ ! -r "$AC" ]; then
    notify-send "⚠️ hypridle" "No pude leer $AC; no suspendo." -t 5000
    exit 1
fi
[ "$(cat "$AC")" = 0 ] && systemctl suspend
exit 0
