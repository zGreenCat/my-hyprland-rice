#!/usr/bin/env bash
# Mutea/desmutea TODOS los sinks, no solo el default, para que el mute
# sea global sin importar a qué salida esté enrutada cada app.
set -euo pipefail

wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
  target=1
else
  target=0
fi

pactl list short sinks | cut -f1 | while read -r sink; do
  pactl set-sink-mute "$sink" "$target"
done
