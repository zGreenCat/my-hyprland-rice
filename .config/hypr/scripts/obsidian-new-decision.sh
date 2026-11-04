#!/usr/bin/env bash
# Registra una decision en el vault. Invocado por omenu (ags) y por obsidian-hub.sh.
VAULT="$HOME/mango-vault"
DECISION="$1"
CONTEXT="$2"

[[ -z "$DECISION" ]] && exit 0

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H:%M)
NOTE="$VAULT/Decisiones/${DATE}.md"

if [[ ! -f "$NOTE" ]]; then
    cat > "$NOTE" << EOF
---
tags: decisiones
fecha: ${DATE}
---

# Decisiones — $(date +%d-%m-%Y)

EOF
fi

if [[ -n "$CONTEXT" ]]; then
    printf "\n## %s — %s\n**Decisión:** %s\n**Razón:** %s\n" \
        "$TIMESTAMP" "$DECISION" "$DECISION" "$CONTEXT" >> "$NOTE"
else
    printf "\n## %s — %s\n**Decisión:** %s\n" \
        "$TIMESTAMP" "$DECISION" "$DECISION" >> "$NOTE"
fi

notify-send "  Decisión guardada" "$DECISION" --expire-time=3000
