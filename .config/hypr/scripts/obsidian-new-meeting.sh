#!/usr/bin/env bash
# Crea una nota de reunion en el vault. Invocado por omenu (ags) y por obsidian-hub.sh.
VAULT="$HOME/mango-vault"
TOPIC="$1"

[[ -z "$TOPIC" ]] && exit 0

DATE=$(date +%Y-%m-%d)
DATE_DISPLAY=$(date +%d-%m-%Y)
FILENAME="${DATE} ${TOPIC}.md"
FILEPATH="$VAULT/Proyectos/$FILENAME"

INBOX_TODAY="$VAULT/Inbox/${DATE}.md"
INBOX_CONTEXT=""
if [[ -f "$INBOX_TODAY" ]]; then
    INBOX_CONTEXT=$(grep "^- " "$INBOX_TODAY" | sed 's/^- [0-9][0-9]:[0-9][0-9] /- /')
fi

cat > "$FILEPATH" << EOF
---
tags: reunion
fecha: ${DATE}
proyecto:
participantes:
---

# ${TOPIC} — ${DATE_DISPLAY}

## Contexto
<!-- De qué proyecto/tema es esta reunión -->

## Temas a tratar
${INBOX_CONTEXT:-"- "}

## Decisiones tomadas
-

## Pendientes que surgieron
- [ ]

## Próxima reunión
- Fecha:
- Temas:

## Links relacionados
-
EOF

notify-send "󰎚 Reunión creada" "$TOPIC" --expire-time=3000
obsidian "obsidian://open?vault=mango-vault&file=$(python3 -c "import urllib.parse; print(urllib.parse.quote('Proyectos/${DATE} ${TOPIC}'))")"
