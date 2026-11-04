#!/usr/bin/env bash
# Convierte PDF a Markdown con MarkItDown y lo clasifica en mango-vault

VAULT="$HOME/mango-vault"
FOLDERS=("Proyectos" "Universidad" "Decisiones" "Dev" "Inbox")

classify() {
    local lower
    lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    if echo "$lower" | grep -qE "acta|minuta|reunion|asistentes|participantes|orden del dia"; then
        echo "Proyectos"; return
    fi
    if echo "$lower" | grep -qE "decision|resolucion|acuerdo|decreto|se acuerda|se resuelve"; then
        echo "Decisiones"; return
    fi
    if echo "$lower" | grep -qE "syllabus|ramo|asignatura|facultad|universidad|ucn|ficg|semestre|creditos|carrera|programa de estudio"; then
        echo "Universidad"; return
    fi
    if echo "$lower" | grep -qE "api|endpoint|arquitectura|especificacion|manual tecnico|deployment|repositorio|diagrama"; then
        echo "Dev"; return
    fi
    echo "Inbox"
}

# ── Selección de archivo ──
if [[ -n "$1" ]]; then
    PDF_PATH="$1"
else
    PDF_PATH=$(zenity --file-selection \
        --title="Seleccionar PDF" \
        --file-filter="PDF (*.pdf)|*.pdf" \
        2>/dev/null)
fi

[[ -z "$PDF_PATH" ]] && exit 0

if [[ ! -f "$PDF_PATH" ]]; then
    notify-send "Error" "Archivo no encontrado: $PDF_PATH"
    exit 1
fi

BASENAME=$(basename "$PDF_PATH" .pdf)

# ── Conversión ──
notify-send "󰈙 Convirtiendo..." "$BASENAME" --expire-time=2000

TEMP_MD=$(mktemp /tmp/vault-XXXXXX.md)
if ! /home/zgreencat/.local/bin/markitdown "$PDF_PATH" > "$TEMP_MD" 2>/dev/null; then
    notify-send "Error" "MarkItDown no pudo convertir el archivo"
    rm -f "$TEMP_MD"
    exit 1
fi

# ── Clasificación heurística ──
PREVIEW=$(head -60 "$TEMP_MD")
SUGGESTED=$(classify "$PREVIEW")

# Rofi: sugerido primero, resto debajo
OTHER_FOLDERS=$(printf "%s\n" "${FOLDERS[@]}" | grep -v "^${SUGGESTED}$")
FOLDER=$(printf "%s (sugerido)\n%s" "$SUGGESTED" "$OTHER_FOLDERS" \
    | rofi -dmenu -p "󰉋 " \
    -theme-str 'window {width: 420px;} listview {lines: 5;} entry {placeholder: "Carpeta destino...";}' \
    -i -no-custom)

[[ -z "$FOLDER" ]] && rm -f "$TEMP_MD" && exit 0
FOLDER="${FOLDER/ (sugerido)/}"

# ── Subcarpeta (solo si la carpeta elegida tiene subdirectorios) ──
SUBFOLDERS=$(find "$VAULT/$FOLDER" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)
if [[ -n "$SUBFOLDERS" ]]; then
    SUBFOLDER=$(printf "Sin subcarpeta\n%s\n+ Crear nueva..." "$SUBFOLDERS" \
        | rofi -dmenu -p "󰉋 " \
        -theme-str 'window {width: 420px;} listview {lines: 6;} entry {placeholder: "Subcarpeta del proyecto...";}' \
        -i -no-custom)

    [[ -z "$SUBFOLDER" ]] && rm -f "$TEMP_MD" && exit 0

    if [[ "$SUBFOLDER" == "+ Crear nueva..." ]]; then
        SUBFOLDER=$(rofi -dmenu -p "󰉋 " \
            -theme-str 'window {width: 420px;} listview {lines: 0; height: 0px;} entry {placeholder: "Nombre del nuevo proyecto...";}' \
            < /dev/null)
        [[ -z "$SUBFOLDER" ]] && rm -f "$TEMP_MD" && exit 0
        mkdir -p "$VAULT/$FOLDER/$SUBFOLDER"
    fi

    [[ "$SUBFOLDER" != "Sin subcarpeta" ]] && FOLDER="$FOLDER/$SUBFOLDER"
fi

# ── Detectar fecha del documento ──
extract_date() {
    # Intenta extraer fecha en formatos comunes, retorna YYYY-MM-DD o vacío
    local text="$1"
    local d m y raw

    # YYYY-MM-DD o YYYY/MM/DD
    raw=$(echo "$text" | grep -oE '[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}' | head -1)
    if [[ -n "$raw" ]]; then
        echo "${raw//\//-}"; return
    fi

    # DD-MM-YYYY o DD/MM/YYYY
    raw=$(echo "$text" | grep -oE '[0-9]{2}[-/][0-9]{2}[-/][0-9]{4}' | head -1)
    if [[ -n "$raw" ]]; then
        d="${raw:0:2}"; m="${raw:3:2}"; y="${raw:6:4}"
        echo "${y}-${m}-${d}"; return
    fi

    # DD de mes de YYYY (español)
    raw=$(echo "$text" | grep -ioE '[0-9]{1,2} de (enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre) de [0-9]{4}' | head -1)
    if [[ -n "$raw" ]]; then
        d=$(echo "$raw" | grep -oE '^[0-9]+')
        y=$(echo "$raw" | grep -oE '[0-9]{4}$')
        m=$(echo "$raw" | grep -ioE '(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)')
        case $(echo "$m" | tr '[:upper:]' '[:lower:]') in
            enero) m="01";; febrero) m="02";; marzo) m="03";;
            abril) m="04";; mayo) m="05";; junio) m="06";;
            julio) m="07";; agosto) m="08";; septiembre) m="09";;
            octubre) m="10";; noviembre) m="11";; diciembre) m="12";;
        esac
        printf "%s-%02d-%02d\n" "$y" "$m" "$d"; return
    fi
}

# Busca fecha: primero en nombre del archivo, luego en contenido
DOC_DATE=$(extract_date "$BASENAME")
[[ -z "$DOC_DATE" ]] && DOC_DATE=$(extract_date "$(head -40 "$TEMP_MD")")
[[ -z "$DOC_DATE" ]] && DOC_DATE=$(date +%Y-%m-%d)

# ── Nombre del archivo ──
DATE="$DOC_DATE"
DEFAULT_NAME="${DATE} ${BASENAME}"
FINAL_NAME=$(printf "%s" "$DEFAULT_NAME" \
    | rofi -dmenu -p "󰈙 " \
    -theme-str 'window {width: 650px;} listview {lines: 1;} entry {placeholder: "Nombre del archivo...";}' \
    -i)

[[ -z "$FINAL_NAME" ]] && FINAL_NAME="$DEFAULT_NAME"
FINAL_NAME="${FINAL_NAME%.md}"

# ── Buscar nota del proyecto padre para wikilink ──
PROJECT_LINK=""
NOTE_NAME=""
if [[ "$FOLDER" == */* ]]; then
    PARENT_DIR="$VAULT/${FOLDER%%/*}"
    SUBFOLDER_NAME="${FOLDER#*/}"
    MATCH=$(find "$PARENT_DIR" -maxdepth 1 -iname "${SUBFOLDER_NAME}.md" | head -1)
    if [[ -n "$MATCH" ]]; then
        NOTE_NAME=$(basename "$MATCH" .md)
        PROJECT_LINK="proyecto: \"[[${NOTE_NAME}]]\""
    fi
fi

# ── Guardar con frontmatter ──
DEST="$VAULT/$FOLDER/${FINAL_NAME}.md"
{
    echo "---"
    echo "tags: importado"
    echo "fuente: $(basename "$PDF_PATH")"
    echo "fecha: ${DATE}"
    [[ -n "$PROJECT_LINK" ]] && echo "$PROJECT_LINK"
    echo "---"
    echo ""
    [[ -n "$PROJECT_LINK" ]] && echo "Proyecto: [[${NOTE_NAME}]]" && echo ""
    cat "$TEMP_MD"
} > "$DEST"

rm -f "$TEMP_MD"

notify-send "󰈙 Importado" "${FINAL_NAME}.md → ${FOLDER}/" --expire-time=4000

ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "${FOLDER}/${FINAL_NAME}")
obsidian "obsidian://open?vault=mango-vault&file=${ENCODED}"
