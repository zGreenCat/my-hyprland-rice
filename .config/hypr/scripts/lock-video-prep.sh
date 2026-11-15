#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════
#  lock-video-prep.sh — prepara el video de fondo del bloqueo para un tema
#
#  Uso: lock-video-prep.sh <video-origen> <tema> [opciones]
#    --grade "<filtro ffmpeg>"   teñido previo (p. ej. colorize=hue=352:...)
#    --tone <0-100>             mezcla con el tritono del tema (como el artifact)
#    --stops "#c1,#c2,#c3,#c4"   tonos de sombra → luz para --tone
#    --fade <segundos>          fundido en el empalme para un bucle sin corte (0 = sin fundido)
#
#  Salida: ~/.local/share/lockscreen/<tema>.mp4 (1920x1080, fps de origen, H.264, sin audio)
# ════════════════════════════════════════════════════════════════════════
set -euo pipefail

die() { echo "lock-video-prep: $*" >&2; exit 1; }

[ $# -ge 2 ] || die "uso: lock-video-prep.sh <video-origen> <tema> [--grade F] [--tone N --stops C1,C2,C3,C4] [--fade S]"
SRC=$1 THEME=$2; shift 2
GRADE="" TONE=0 STOPS="" FADE=1

while [ $# -gt 0 ]; do
    case $1 in
        --grade) GRADE=$2; shift 2 ;;
        --tone) TONE=$2; shift 2 ;;
        --stops) STOPS=$2; shift 2 ;;
        --fade) FADE=$2; shift 2 ;;
        *) die "opción desconocida: $1" ;;
    esac
done

[ -f "$SRC" ] || die "no existe el video de origen: $SRC"
command -v ffmpeg >/dev/null || die "falta ffmpeg"
[ "$TONE" -eq 0 ] || [ -n "$STOPS" ] || die "--tone requiere --stops"

OUT_DIR="$HOME/.local/share/lockscreen"
OUT="$OUT_DIR/$THEME.mp4"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT_DIR"

DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$SRC")
python3 -I -c "import sys; sys.exit(0 if float(sys.argv[1]) > 2 * float(sys.argv[2]) else 1)" "$DURATION" "$FADE" \
    || die "el video ($DURATION s) es muy corto para un fundido de $FADE s"

FILTER="scale=1920:1080:force_original_aspect_ratio=increase:flags=lanczos,crop=1920:1080"
[ -z "$GRADE" ] || FILTER="$FILTER,$GRADE"

if [ "$TONE" -gt 0 ]; then
    python3 -I - "$STOPS" "$TONE" "$WORK/tone.cube" <<'PY'
import sys

stops_arg, tone_arg, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
stops = [tuple(int(h.strip().lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)) for h in stops_arg.split(",")]
if len(stops) < 2:
    raise SystemExit("--stops necesita al menos dos colores")
mix = int(tone_arg) / 100
size = 33

def gradient(lum):
    pos = lum * (len(stops) - 1)
    i = min(int(pos), len(stops) - 2)
    t = pos - i
    return tuple(stops[i][c] + (stops[i + 1][c] - stops[i][c]) * t for c in range(3))

with open(out_path, "w") as f:
    f.write(f"LUT_3D_SIZE {size}\n")
    for b in range(size):
        for g in range(size):
            for r in range(size):
                src = (r / (size - 1), g / (size - 1), b / (size - 1))
                lum = 0.2126 * src[0] + 0.7152 * src[1] + 0.0722 * src[2]
                toned = gradient(lum)
                f.write(" ".join(f"{(1 - mix) * s + mix * t:.6f}" for s, t in zip(src, toned)) + "\n")
PY
    FILTER="$FILTER,lut3d=file=$WORK/tone.cube"
fi

if python3 -I -c "import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)" "$FADE"; then
    OFFSET=$(python3 -I -c "import sys; print(f'{float(sys.argv[1]) - 2 * float(sys.argv[2]):.3f}')" "$DURATION" "$FADE")
    GRAPH="[0:v]$FILTER,split[a][b];
[a]trim=start=$FADE,setpts=PTS-STARTPTS[body];
[b]trim=end=$FADE,setpts=PTS-STARTPTS[head];
[body][head]xfade=transition=fade:duration=$FADE:offset=$OFFSET,format=yuv420p[out]"
else
    GRAPH="[0:v]$FILTER,format=yuv420p[out]"
fi

ffmpeg -v error -stats -y -i "$SRC" -filter_complex "$GRAPH" -map "[out]" -an \
    -c:v libx264 -preset slow -crf 18 -profile:v high -movflags +faststart "$WORK/out.mp4"
mv "$WORK/out.mp4" "$OUT"

echo "listo: $OUT ($(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -show_entries format=duration -of csv=p=0 "$OUT" | tr '\n' ' '))"
