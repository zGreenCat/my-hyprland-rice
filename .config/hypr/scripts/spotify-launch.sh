#!/bin/bash
# Aplica un theme de Spicetify pendiente (si el cambio de tema del rice
# ocurrió con Spotify abierto) antes de lanzar Spotify.
if [ -f "$HOME/.config/spicetify/.pending-apply" ]; then
    spicetify apply &>/dev/null
    rm -f "$HOME/.config/spicetify/.pending-apply"
fi
exec spotify "$@"
