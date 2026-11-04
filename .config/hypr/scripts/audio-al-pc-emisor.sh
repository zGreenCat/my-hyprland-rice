#!/usr/bin/env bash
set -euo pipefail

PC_IP="${PC_IP:-192.168.1.141}"
PC_PORT="${PC_PORT:-5555}"
SINK="SerieAlPC"
MONITOR="${SINK}.monitor"
SDP_OUT="${HOME}/.local/share/audio-al-pc/stream.sdp"

if ! pactl list sinks short | grep -q "[[:space:]]${SINK}[[:space:]]"; then
    echo "ERROR: sink '${SINK}' no existe. Reinicia pipewire:" >&2
    echo "  systemctl --user restart pipewire pipewire-pulse wireplumber" >&2
    exit 1
fi

mkdir -p "$(dirname "${SDP_OUT}")"
cat > "${SDP_OUT}" <<SDP
v=0
o=- 0 0 IN IP4 ${PC_IP}
s=SerieAlPC
c=IN IP4 ${PC_IP}
t=0 0
m=audio ${PC_PORT} RTP/AVP 97
b=AS:1536
a=rtpmap:97 L16/48000/2
SDP

echo "Emisor: ${MONITOR} -> rtp://${PC_IP}:${PC_PORT}  (L16 48k estereo, sin compresion)"
echo "SDP para el PC: ${SDP_OUT}"
echo "Rutea el reproductor al sink 'Serie al PC' (pavucontrol > Playback)."
echo "Ctrl-C para cortar."

exec ffmpeg -hide_banner -loglevel warning -stats \
    -fflags +nobuffer -flags low_delay \
    -f pulse -i "${MONITOR}" \
    -ac 2 -ar 48000 -c:a pcm_s16be \
    -max_delay 0 -flush_packets 1 \
    -f rtp "rtp://${PC_IP}:${PC_PORT}?pkt_size=1316"
