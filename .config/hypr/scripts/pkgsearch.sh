#!/bin/bash

FZF_COLORS="bg:#151218,bg+:#543b72,fg:#e8e0e8,fg+:#eedbff,\
hl:#963afa,hl+:#eedbff,border:#d8bafa,\
header:#958e98,prompt:#d8bafa,pointer:#d8bafa,\
marker:#963afa,spinner:#963afa,info:#958e98,\
preview-bg:#1d1a20,separator:#543b72,scrollbar:#543b72"

selected=$(yay -Slq 2>/dev/null | fzf \
    --multi \
    --layout=reverse \
    --preview 'pacman -Si {1} 2>/dev/null || yay -Si {1} 2>/dev/null' \
    --preview-window=down:55%:wrap:border-top \
    --bind 'alt-p:toggle-preview' \
    --bind 'alt-j:preview-down' \
    --bind 'alt-k:preview-up' \
    --bind 'tab:toggle+down' \
    --header $'alt-p: toggle description  alt-j/k: scroll  tab: multi-select' \
    --color="$FZF_COLORS" \
    --border=sharp \
    --border-label=' Instalar paquetes ' \
    --border-label-pos=top \
    --prompt='> ' \
    --pointer='▶' \
    --marker='✔' \
    --info=inline \
    --no-bold)

if [[ -n "$selected" ]]; then
    pkgs=$(echo "$selected" | tr '\n' ' ')
    yay -S $pkgs
    echo
    read -p 'Presiona Enter para cerrar...'
fi
