#!/bin/bash

BATTERY_PATH="/sys/class/power_supply/BAT0"
ICON_WARNING="$HOME/.config/swaync/icons/battery-quarter-solid.svg"
ICON_CRITICAL="$HOME/.config/swaync/icons/battery-status.png"

get_battery() {
    cat "$BATTERY_PATH/capacity"
}

get_status() {
    cat "$BATTERY_PATH/status"
}

NOTIFIED_30=false
NOTIFIED_15=false
NOTIFIED_8=false

while true; do
    LEVEL=$(get_battery)
    STATUS=$(get_status)

    # Reset notificaciones cuando se conecta cargador
    if [[ "$STATUS" == "Charging" ]]; then
        NOTIFIED_30=false
        NOTIFIED_15=false
        NOTIFIED_8=false
    fi

    if [[ "$STATUS" != "Charging" ]]; then
        # 30% - Warning
        if [[ $LEVEL -le 30 && $LEVEL -gt 15 && "$NOTIFIED_30" == false ]]; then
            notify-send "Batería baja" "Nivel: ${LEVEL}%\nConecta el cargador pronto." \
                --icon="$ICON_WARNING" \
                --urgency=normal \
                --expire-time=8000 \
                --hint=string:x-canonical-private-synchronous:battery
            NOTIFIED_30=true
        fi

        # 15% - Critical
        if [[ $LEVEL -le 15 && $LEVEL -gt 8 && "$NOTIFIED_15" == false ]]; then
            notify-send "⚠️ Batería crítica" "Nivel: ${LEVEL}%\nConecta el cargador ahora." \
                --icon="$ICON_CRITICAL" \
                --urgency=critical \
                --expire-time=0 \
                --hint=string:x-canonical-private-synchronous:battery
            NOTIFIED_15=true
        fi

        # 8% - Hibernate
        if [[ $LEVEL -le 8 && "$NOTIFIED_8" == false ]]; then
            NOTIFIED_8=true
            for i in 30 20 10 5 3 2 1; do
                notify-send "🔴 Hibernando en ${i}s" "Batería: ${LEVEL}%\nGuardando sesión al disco..." \
                    --icon="$ICON_CRITICAL" \
                    --urgency=critical \
                    --expire-time=1100 \
                    --hint=string:x-canonical-private-synchronous:battery
                sleep 1
            done
            systemctl hibernate
        fi
    fi

    sleep 30
done
