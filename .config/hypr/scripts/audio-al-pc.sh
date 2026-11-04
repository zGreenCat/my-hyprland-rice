#!/usr/bin/env bash
set -euo pipefail

SINK="SerieAlPC"
SERVICE="audio-al-pc.service"
PC_IP="${PC_IP:-192.168.1.141}"
PC_PORT="${PC_PORT:-5555}"
WAYBAR_SIG=8

notify() { notify-send -a "Audio al PC" -i audio-volume-high "󰄠 Audio al PC" "$1" 2>/dev/null || true; }
die() {
    echo "ERROR: $1" >&2
    notify-send -a "Audio al PC" -u critical "󰄠 Audio al PC" "$1" 2>/dev/null || true
    exit 1
}
refresh_waybar() { pkill -RTMIN+${WAYBAR_SIG} waybar 2>/dev/null || true; }

sink_exists() { pactl list sinks short | grep -q "[[:space:]]${SINK}[[:space:]]"; }
sink_index()  { pactl -f json list sinks | jq -r --arg n "$SINK" '.[]|select(.name==$n)|.index'; }
service_on()  { systemctl --user is-active --quiet "$SERVICE"; }

# streams actualmente ruteados al sink de envio
sent_count() {
    local idx; idx=$(sink_index)
    [ -z "$idx" ] && { echo 0; return; }
    pactl -f json list sink-inputs | jq --argjson s "$idx" '[.[]|select(.sink==$s)]|length'
}

start_service() {
    service_on && return 0
    sink_exists || die "El sink '${SINK}' no existe. Reinicia pipewire."
    systemctl --user start "$SERVICE"
    for _ in $(seq 20); do
        service_on && { refresh_waybar; return 0; }
        sleep 0.1
    done
    die "El servicio no arrancó. Ver: journalctl --user -u ${SERVICE} -n 30"
}

# devuelve todos los streams a los parlantes del notebook y corta el envio
stop_all() {
    local idx def
    idx=$(sink_index)
    def=$(pactl get-default-sink)
    if [ -n "$idx" ] && [ "$def" != "$SINK" ]; then
        while read -r id; do
            [ -n "$id" ] && pactl move-sink-input "$id" "$def" 2>/dev/null || true
        done < <(pactl -f json list sink-inputs | jq -r --argjson s "$idx" '.[]|select(.sink==$s)|.index')
    fi
    service_on && systemctl --user stop "$SERVICE"
    refresh_waybar
    notify "Envío cortado. Audio de vuelta en el notebook."
}

# ── salida JSON para waybar ────────────────────────────────────────────────
cmd_status() {
    if ! service_on; then
        printf '{"text":"","tooltip":"","class":"off"}\n'
        return
    fi
    local n; n=$(sent_count)
    printf '{"text":"󰄠 %s","tooltip":"Enviando a %s:%s\\n%s app(s) ruteada(s)\\nClick: cortar y volver al notebook","class":"on"}\n' \
        "$n" "$PC_IP" "$PC_PORT" "$n"
}

# ── menu rofi con checkboxes ───────────────────────────────────────────────
cmd_menu() {
    sink_exists || die "El sink '${SINK}' no existe. Reinicia pipewire: systemctl --user restart pipewire pipewire-pulse wireplumber"

    while true; do
        local idx def rows acts n
        idx=$(sink_index)
        def=$(pactl get-default-sink)
        rows=(); acts=()

        if service_on; then
            n=$(sent_count)
            rows+=("󰓛  Cortar envío  ·  ${n} app(s) al PC")
            acts+=("stop")
        else
            rows+=("󰐊  Iniciar envío al PC")
            acts+=("start")
        fi
        rows+=("───────────────────────────")
        acts+=("noop")

        local any=0
        while IFS=$'\t' read -r id sink app media; do
            [ -z "$id" ] && continue
            any=1
            local label mark
            label="${media:-$app}"
            label="${label%% - $app}"
            [ ${#label} -gt 44 ] && label="${label:0:41}..."
            if [ "$sink" = "$idx" ]; then mark="󰄬"; else mark="󰄱"; fi
            rows+=("${mark}  ${app}  ·  ${label}")
            acts+=("toggle:${id}")
        done < <(pactl -f json list sink-inputs \
                 | jq -r '.[]|[(.index|tostring),(.sink|tostring),(.properties["application.name"]//"?"),(.properties["media.name"]//"")]|@tsv')

        if [ "$any" -eq 0 ]; then
            rows+=("(ninguna app está emitiendo audio)")
            acts+=("noop")
        fi

        local sel
        sel=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -p "󰄠  Audio al PC" -format i \
              -theme-str 'window {width: 560px;} listview {lines: 10; fixed-height: false;}') || break
        [ -z "$sel" ] && break

        case "${acts[$sel]}" in
            noop) : ;;
            start) start_service; notify "Enviando a ${PC_IP}:${PC_PORT}" ;;
            stop)  stop_all ;;
            toggle:*)
                local id="${acts[$sel]#toggle:}"
                local cur
                cur=$(pactl -f json list sink-inputs | jq -r --argjson i "$id" '.[]|select(.index==$i)|.sink')
                if [ -z "$cur" ]; then
                    notify "Ese stream ya no existe."
                elif [ "$cur" = "$idx" ]; then
                    pactl move-sink-input "$id" "$def"
                    [ "$(sent_count)" -eq 0 ] && service_on && stop_all
                else
                    start_service
                    pactl move-sink-input "$id" "$SINK"
                fi
                refresh_waybar
                ;;
        esac
    done
}

case "${1:-menu}" in
    menu)   cmd_menu ;;
    status) cmd_status ;;
    stop)   stop_all ;;
    start)  start_service; notify "Enviando a ${PC_IP}:${PC_PORT}" ;;
    *)      echo "uso: $(basename "$0") [menu|status|stop|start]" >&2; exit 1 ;;
esac
