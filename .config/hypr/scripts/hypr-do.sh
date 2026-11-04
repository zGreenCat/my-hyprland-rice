#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  hypr-do.sh — acciones de Hyprland que funcionan con config Lua y legacy (.conf)
#  Hyprland 0.57 eliminó `hyprctl keyword` y los dispatch legacy; este script
#  detecta el modo y usa la variante correcta. hyprctl sale con 0 aunque falle,
#  así que se valida la salida ("ok") y se falla explícito por stderr.
#
#  Uso: hypr-do.sh <acción> [args]
#    ws-next | ws-prev                  workspace existente siguiente/anterior
#    exit                               salir de Hyprland
#    dpms on|off                        encender/apagar pantallas
#    toggle-special <nombre>            mostrar/ocultar workspace especial
#    focus-window <selector>            enfocar ventana (ej: "class:^(code)$")
#    exec <comando...>                  lanzar comando
#    move-ws <workspace> <monitor>      mover workspace a un monitor
#    monitor <salida> <modo> <pos> <escala>
#    set-colors <activo> <inactivo> <sombra> <sombra_inactiva> <rounding>
#    colors-lua <activo> <inactivo> <sombra> <sombra_inactiva>   (imprime colors.lua)
#    mode                               imprime "lua" o "legacy"
# ════════════════════════════════════════════════════════════════════════
set -u

LEGACY_EVAL_MSG="eval is only supported with the lua config manager"

die() {
    echo "hypr-do: $*" >&2
    exit 1
}

is_lua() {
    local out
    out=$(hyprctl eval 'return 1' 2>&1) || die "hyprctl no responde: $out"
    [ "$out" != "$LEGACY_EVAL_MSG" ]
}

run() {
    local out
    out=$("$@" 2>&1)
    [ "$out" = "ok" ] || die "'$*' falló: $out"
}

lua_eval() {
    run hyprctl eval "$1"
}

luaq() {
    local s=${1//\\/\\\\}
    s=${s//\"/\\\"}
    printf '"%s"' "$s"
}

# "rgb(a) rgb(b) 45deg" → { colors = { "rgb(a)", "rgb(b)" }, angle = 45 }; un color solo → "rgb(a)"
lua_color() {
    local tok colors=() angle=""
    for tok in $1; do
        if [[ "$tok" =~ ^(rgb|rgba)\([0-9a-fA-F]{6,8}\)$ ]]; then
            colors+=("$(luaq "$tok")")
        elif [[ "$tok" =~ ^([0-9]+)deg$ ]]; then
            angle=${BASH_REMATCH[1]}
        else
            die "color inválido '$tok' en '$1'"
        fi
    done
    [ ${#colors[@]} -gt 0 ] || die "sin colores en '$1'"
    if [ ${#colors[@]} -eq 1 ] && [ -z "$angle" ]; then
        printf '%s' "${colors[0]}"
        return
    fi
    local joined
    joined=$(printf '%s, ' "${colors[@]}")
    printf '{ colors = { %s }%s }' "${joined%, }" "${angle:+, angle = $angle}"
}

need() {
    [ "$1" -ge "$2" ] || die "'$ACTION' requiere $2 argumento(s)"
}

ACTION=${1:-}
[ -n "$ACTION" ] || die "falta acción (ver cabecera del script)"
shift

case "$ACTION" in
    mode)
        if is_lua; then echo lua; else echo legacy; fi
        ;;
    ws-next | ws-prev)
        dir="+1"; [ "$ACTION" = ws-prev ] && dir="-1"
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.focus({ workspace = \"e$dir\" }))"
        else run hyprctl dispatch workspace "e$dir"; fi
        ;;
    exit)
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.exit())"
        else run hyprctl dispatch exit; fi
        ;;
    dpms)
        need $# 1
        case "$1" in
            on) lua_action=enable ;;
            off) lua_action=disable ;;
            *) die "dpms espera on|off, recibió '$1'" ;;
        esac
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.dpms({ action = \"$lua_action\" }))"
        else run hyprctl dispatch dpms "$1"; fi
        ;;
    toggle-special)
        need $# 1
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.workspace.toggle_special($(luaq "$1")))"
        else run hyprctl dispatch togglespecialworkspace "$1"; fi
        ;;
    focus-window)
        need $# 1
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.focus({ window = $(luaq "$1") }))"
        else run hyprctl dispatch focuswindow "$1"; fi
        ;;
    exec)
        need $# 1
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.exec_cmd($(luaq "$*")))"
        else run hyprctl dispatch exec "$*"; fi
        ;;
    move-ws)
        need $# 2
        [[ "$1" =~ ^[0-9]+$ ]] || die "move-ws espera workspace numérico, recibió '$1'"
        if is_lua; then lua_eval "hl.dispatch(hl.dsp.workspace.move({ workspace = $1, monitor = $(luaq "$2") }))"
        else run hyprctl dispatch moveworkspacetomonitor "$1" "$2"; fi
        ;;
    monitor)
        need $# 4
        if is_lua; then
            lua_eval "hl.monitor({ output = $(luaq "$1"), mode = $(luaq "$2"), position = $(luaq "$3"), scale = $4 })"
        else
            run hyprctl keyword monitor "$1,$2,$3,$4"
        fi
        ;;
    set-colors)
        need $# 5
        [[ "$5" =~ ^[0-9]+$ ]] || die "rounding debe ser entero, recibió '$5'"
        if is_lua; then
            active=$(lua_color "$1") || exit 1
            inactive=$(lua_color "$2") || exit 1
            shadow=$(lua_color "$3") || exit 1
            shadow_inactive=$(lua_color "$4") || exit 1
            lua_eval "hl.config({ general = { col = { active_border = $active, inactive_border = $inactive } }, decoration = { rounding = $5, shadow = { color = $shadow, color_inactive = $shadow_inactive } } })"
        else
            run hyprctl keyword general:col.active_border "$1"
            run hyprctl keyword general:col.inactive_border "$2"
            run hyprctl keyword decoration:shadow:color "$3"
            run hyprctl keyword decoration:shadow:color_inactive "$4"
            run hyprctl keyword decoration:rounding "$5"
        fi
        ;;
    colors-lua)
        need $# 4
        active=$(lua_color "$1") || exit 1
        inactive=$(lua_color "$2") || exit 1
        shadow=$(lua_color "$3") || exit 1
        shadow_inactive=$(lua_color "$4") || exit 1
        printf 'return {\n  active_border = %s,\n  inactive_border = %s,\n  shadow = %s,\n  shadow_inactive = %s,\n}\n' \
            "$active" "$inactive" "$shadow" "$shadow_inactive"
        ;;
    *)
        die "acción desconocida '$ACTION'"
        ;;
esac
