#!/usr/bin/env python3
# Letras sincronizadas para waybar: consulta lrclib.net (API pública) cuando
# cambia la canción, cachea el resultado, y muestra la línea correspondiente
# a la posición actual de reproducción.
import subprocess
import json
import re
import os
import urllib.request
import urllib.parse

CACHE_DIR = os.path.expanduser("~/.cache/waybar-lyrics")
os.makedirs(CACHE_DIR, exist_ok=True)


def playerctl(*args):
    try:
        return subprocess.check_output(
            ["playerctl", "-p", "spotify", *args], stderr=subprocess.DEVNULL, text=True
        ).strip()
    except subprocess.CalledProcessError:
        return ""


def cache_path(artist, title):
    safe = re.sub(r"[^a-zA-Z0-9]+", "_", f"{artist}-{title}").lower().strip("_")
    return os.path.join(CACHE_DIR, f"{safe}.json")


def fetch_lyrics(artist, title, album, duration_s):
    params = {"artist_name": artist, "track_name": title}
    if album:
        params["album_name"] = album
    if duration_s:
        params["duration"] = int(duration_s)
    url = "https://lrclib.net/api/get?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "waybar-lyrics/1.0"})
        with urllib.request.urlopen(req, timeout=5) as r:
            data = json.load(r)
        synced = data.get("syncedLyrics")
        if not synced:
            return []
        lines = []
        for line in synced.splitlines():
            m = re.match(r"\[(\d+):(\d+\.\d+)\](.*)", line)
            if m:
                minutes, seconds, text = m.groups()
                ts = int(minutes) * 60 + float(seconds)
                lines.append([ts, text.strip()])
        return lines
    except Exception:
        return []


def load_or_fetch(artist, title, album, duration_s):
    path = cache_path(artist, title)
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    lines = fetch_lyrics(artist, title, album, duration_s)
    with open(path, "w") as f:
        json.dump(lines, f)
    return lines


def current_line(lines, pos_s):
    current = ""
    for ts, text in lines:
        if ts <= pos_s:
            current = text
        else:
            break
    return current


def main():
    status = playerctl("status")
    title = playerctl("metadata", "title")

    if not title or status.lower() != "playing":
        print(json.dumps({"text": "", "tooltip": "Sin reproducción", "class": "idle"}))
        return

    artist = playerctl("metadata", "artist")
    album = playerctl("metadata", "album")
    length_us = playerctl("metadata", "mpris:length")
    pos_raw = playerctl("position")

    duration_s = float(length_us) / 1_000_000 if length_us else None
    lines = load_or_fetch(artist, title, album, duration_s)

    tooltip = f"{title} — {artist}" if artist else title

    if not lines:
        print(json.dumps({"text": f" {title}", "tooltip": f"{tooltip} (sin letra sincronizada)"}))
        return

    pos_s = float(pos_raw) if pos_raw else 0.0
    text = current_line(lines, pos_s) or f" {title}"
    print(json.dumps({"text": text, "tooltip": tooltip}))


if __name__ == "__main__":
    main()
