#!/bin/bash
if ! hyprctl clients -j | python3 -c "
import sys, json
clients = json.load(sys.stdin)
exit(0 if any(c['class'] == 'scratchpad' for c in clients) else 1)
" 2>/dev/null; then
    kitty --class scratchpad &
    sleep 0.4
fi
~/.config/hypr/scripts/hypr-do.sh toggle-special scratchpad
