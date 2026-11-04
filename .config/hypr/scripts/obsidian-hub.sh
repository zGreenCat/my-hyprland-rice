#!/usr/bin/env bash

VAULT="$HOME/mango-vault"
THEME_STR='window {width: 500px;} listview {lines: 4;} entry {placeholder: "Selecciona...";}'

# ── Menú principal ──
ACTION=$(printf "󰎚  Nueva reunion\n  Nueva decision\n󰈙  Importar PDF\n  Abrir vault" \
    | rofi -dmenu -p "󱓧 " \
    -theme-str "$THEME_STR" \
    -i -no-custom)

[[ -z "$ACTION" ]] && exit 0

case "$ACTION" in

"󰎚  Nueva reunion")
    TOPIC=$(rofi -dmenu -p "󰎚 " \
        -theme-str 'window {width: 600px;} listview {lines: 0; height: 0px;} entry {placeholder: "Nombre de la reunion...";}' \
        < /dev/null)
    [[ -z "$TOPIC" ]] && exit 0

    DATE=$(date +%Y-%m-%d)
    DATE_DISPLAY=$(date +%d-%m-%Y)
    FILENAME="${DATE} ${TOPIC}.md"
    FILEPATH="$VAULT/Proyectos/$FILENAME"

    # Notas del inbox de hoy como contexto
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
    ;;

"  Nueva decision")
    DECISION=$(rofi -dmenu -p "  " \
        -theme-str 'window {width: 600px;} listview {lines: 0; height: 0px;} entry {placeholder: "Describe la decision...";}' \
        < /dev/null)
    [[ -z "$DECISION" ]] && exit 0

    CONTEXT=$(rofi -dmenu -p "󰋗 " \
        -theme-str 'window {width: 600px;} listview {lines: 0; height: 0px;} entry {placeholder: "Contexto/razon (opcional)...";}' \
        < /dev/null)

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
    ;;

"󰈙  Importar PDF")
    ~/.config/hypr/scripts/pdf-to-vault.sh
    ;;

"  Abrir vault")
    obsidian "obsidian://open?vault=mango-vault"
    ;;

esac
