#!/bin/bash
# Eliminar un tema del rice. Protege el tema activo y limpia COUNTERPART colgante.
THEMES_DIR="$HOME/.config/hypr/themes"
ACTIVE=$(cat "$HOME/.config/hypr/.active-theme" 2>/dev/null)

mapfile -t SLUGS < <(find "$THEMES_DIR" -mindepth 2 -maxdepth 2 -name theme.conf -printf '%h\n' \
    | xargs -r -n1 basename | sort)
if [ ${#SLUGS[@]} -eq 0 ]; then
    notify-send "Temas" "No hay temas para eliminar." -t 3000
    exit 0
fi

LIST=""
for s in "${SLUGS[@]}"; do
    name=$(grep -m1 '^THEME_NAME=' "$THEMES_DIR/$s/theme.conf" | cut -d'"' -f2)
    mark=""; [ "$s" = "$ACTIVE" ] && mark="  ● activo"
    LIST+="$s — ${name}${mark}\n"
done

CHOICE=$(echo -e "$LIST" | rofi -dmenu -i -p "Eliminar tema" \
    -theme-str 'window {width: 540px;} listview {lines: 8;}')
[ -z "$CHOICE" ] && exit 0
SLUG="${CHOICE%% —*}"

if [ -z "$SLUG" ] || [ ! -d "$THEMES_DIR/$SLUG" ]; then
    notify-send "⚠️ Tema inválido" "No se encontró '$SLUG'." -t 4000
    exit 1
fi
if [ "$SLUG" = "$ACTIVE" ]; then
    notify-send "⚠️ Tema activo" "No se elimina el tema en uso. Cambia de tema primero." -t 4000
    exit 1
fi

CONFIRM=$(echo -e "No\nSi, eliminar" | rofi -dmenu -i -p "Borrar $SLUG?" \
    -theme-str 'window {width: 420px;} listview {lines: 2;}')
[ "$CONFIRM" = "Si, eliminar" ] || exit 0

rm -rf "${THEMES_DIR:?}/${SLUG:?}"

# Limpiar referencias COUNTERPART al tema borrado
for conf in "$THEMES_DIR"/*/theme.conf; do
    [ -f "$conf" ] || continue
    if grep -q "COUNTERPART=\"$SLUG\"" "$conf"; then
        sed -i "s/COUNTERPART=\"$SLUG\"/COUNTERPART=\"\"/" "$conf"
    fi
done

notify-send "🗑️ Tema eliminado" "$SLUG" -t 3000
