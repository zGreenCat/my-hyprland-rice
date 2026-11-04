#!/bin/bash
SCRIPTS="$HOME/.config/hypr/scripts"

_menu() {
    echo -e "$2" | rofi -dmenu -i -p "$1" \
        -theme-str 'window {width: 420px;} listview {lines: 8; fixed-height: false;}'
}

show_style_menu() {
    case $(_menu "󰸌  Style" "󰏘  Cambiar tema\n󰐕  Nuevo tema\n󰩹  Eliminar tema") in
        *Cambiar*)  python3 "$SCRIPTS/theme-selector-preview.py" ;;
        *Nuevo*)    python3 "$SCRIPTS/theme-creator.py" ;;
        *Eliminar*) "$SCRIPTS/delete-theme.sh" ;;
    esac
}

show_learn_menu() {
    case $(_menu "󰙨  Learn" "󰌌  Keybindings\n󰖟  Hyprland Wiki\n󰣇  Arch Wiki\n󰕷  Neovim Docs") in
        *Keybindings*) python3 "$SCRIPTS/keybindings-view.py" | \
            rofi -dmenu -p "󰌌  Keybindings" \
            -theme-str 'window {width: 780px;} listview {lines: 16; fixed-height: true;}' \
            > /dev/null 2>&1 ;;
        *Hyprland*)    xdg-open "https://wiki.hyprland.org" ;;
        *Arch*)        xdg-open "https://wiki.archlinux.org" ;;
        *Neovim*)      xdg-open "https://neovim.io/doc/" ;;
    esac
}

show_audio_menu() {
    case $(_menu "󰕾  Audio" "󰕾  Mezclador (pavucontrol)\n󰄠  Enviar audio al PC") in
        *Mezclador*) pavucontrol ;;
        *Enviar*)    "$SCRIPTS/audio-al-pc.sh" menu ;;
    esac
}

show_system_menu() {
    case $(_menu "󰒋  System" "󰂯  Bluetooth\n󰕾  Audio\n󰤨  Red\n󰑐  Reiniciar Waybar\n󰐥  Power Menu") in
        *Bluetooth*)  blueman-manager ;;
        *Audio*)      show_audio_menu ;;
        *Red*)        nm-connection-editor ;;
        *Reiniciar*)  "$SCRIPTS/wbrestart.sh" ;;
        *Power*)      wlogout ;;
    esac
}

show_install_menu() {
    case $(_menu "󰏗  Install" "󰇚  Instalar paquete\n󰚰  Actualizar sistema\n󰆴  Remover paquete") in
        *Instalar*)   kitty bash -c "$SCRIPTS/pkgsearch.sh" ;;
        *Actualizar*) kitty bash -c 'yay -Syu; read' ;;
        *Remover*)    kitty bash -c "yay -R \$(yay -Qq | rofi -dmenu -p 'Remover paquete'); read" ;;
    esac
}

show_main_menu() {
    case $(_menu "  Menu" "󰣆  Apps\n󰸌  Style\n󰙨  Learn\n󰒋  System\n󰏗  Install") in
        *Apps*)    rofi -show drun ;;
        *Style*)   show_style_menu ;;
        *Learn*)   show_learn_menu ;;
        *System*)  show_system_menu ;;
        *Install*) show_install_menu ;;
    esac
}

pgrep -x rofi && pkill rofi
show_main_menu
