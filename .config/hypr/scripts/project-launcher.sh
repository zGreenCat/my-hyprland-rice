#!/bin/bash
# Busca repos git y los abre en VSCode
# Edita SEARCH_DIRS para agregar más directorios

SEARCH_DIRS=(
    "$HOME/AntigravityWorkspace"
    "$HOME/projects"
    "$HOME/dev"
    "$HOME/repos"
    "$HOME"
)

EDITOR="${PROJECT_EDITOR:-code}"

# Buscar repos git (máx 3 niveles de profundidad)
projects=$(
    for dir in "${SEARCH_DIRS[@]}"; do
        [ -d "$dir" ] && find "$dir" -maxdepth 3 -name ".git" -type d 2>/dev/null | sed 's|/.git$||'
    done | sort -u
)

[ -z "$projects" ] && notify-send "Project Launcher" "No se encontraron repos git" -t 3000 && exit 0

selected=$(echo "$projects" | \
    sed "s|$HOME/||" | \
    rofi -dmenu -i \
        -p "󰊢  Proyecto" \
        -theme-str 'window {width: 560px;} listview {lines: 12; fixed-height: false;}')

[ -z "$selected" ] && exit 0

# Reconstruir ruta completa
full_path="$HOME/$selected"
[ ! -d "$full_path" ] && full_path="$selected"

# Si VSCode ya tiene el proyecto abierto, enfocarlo
if hyprctl clients -j 2>/dev/null | python3 -c "
import sys, json, os
clients = json.load(sys.stdin)
path = '$full_path'
name = os.path.basename(path)
for c in clients:
    if c.get('class','') in ('code','Code') and name in c.get('title',''):
        print(c['address'])
        exit(0)
exit(1)
" 2>/dev/null; then
    ~/.config/hypr/scripts/hypr-do.sh focus-window "class:^(code|Code)$"
else
    "$EDITOR" "$full_path" &
fi
