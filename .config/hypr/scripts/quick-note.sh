#!/usr/bin/env bash
# Captura rápida al vault de Obsidian → Inbox/YYYY-MM-DD.md

VAULT="$HOME/mango-vault"
INBOX="$VAULT/Inbox"
NOTE="$INBOX/$(date +%Y-%m-%d).md"

idea=$(rofi -dmenu -p "󰎚 " \
    -theme-str 'window {width: 600px;} listview {lines: 0; height: 0px; spacing: 0px; padding: 0px; margin: 0px;} mainbox {children: ["inputbar"];} entry {placeholder: "Escribe una nota...";}' \
    < /dev/null)

[[ -z "$idea" ]] && exit 0

timestamp=$(date +%H:%M)

if [[ ! -f "$NOTE" ]]; then
    cat > "$NOTE" << EOF
---
tags: inbox
fecha: $(date +%Y-%m-%d)
---

# Inbox — $(date +%d-%m-%Y)

EOF
fi

echo "- $timestamp $idea" >> "$NOTE"

notify-send "󰎚 Nota guardada" "$idea" --expire-time=3000
