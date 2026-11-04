#!/usr/bin/env python3
# Un solo slot de waybar que alterna entre reloj y letra sincronizada.
# Scroll (arriba o abajo) sobre el módulo alterna el modo.
import subprocess
import json
import re
import os
import sys
import urllib.request
import urllib.parse
from datetime import datetime

CACHE_DIR = os.path.expanduser("~/.cache/waybar-lyrics")
MODE_FILE = os.path.expanduser("~/.cache/waybar-clock-lyrics-mode")
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


def read_mode():
    try:
        with open(MODE_FILE) as f:
            mode = f.read().strip()
    except FileNotFoundError:
        mode = "clock"
    return mode if mode in ("clock", "lyrics") else "clock"


def toggle_mode():
    write_mode("lyrics" if read_mode() == "clock" else "clock")


def write_mode(mode):
    with open(MODE_FILE, "w") as f:
        f.write(mode)


def render_clock():
    text = datetime.now().strftime(" %I:%M %p")
    print(json.dumps({"text": text, "tooltip": "Scroll: ver letra de la canción\nClick: calendario"}))


def render_lyrics():
    status = playerctl("status")
    title = playerctl("metadata", "title")

    if not title or status.lower() != "playing":
        print(json.dumps({"text": " sin reproducción", "tooltip": "Scroll: volver a la hora"}))
        return

    artist = playerctl("metadata", "artist")
    album = playerctl("metadata", "album")
    length_us = playerctl("metadata", "mpris:length")
    pos_raw = playerctl("position")

    duration_s = float(length_us) / 1_000_000 if length_us else None
    lines = load_or_fetch(artist, title, album, duration_s)

    tooltip = f"{title} — {artist}\nScroll: volver a la hora" if artist else title

    if not lines:
        print(json.dumps({"text": f" {title}", "tooltip": tooltip}))
        return

    pos_s = float(pos_raw) if pos_raw else 0.0
    text = current_line(lines, pos_s) or f" {title}"
    print(json.dumps({"text": text, "tooltip": tooltip}))


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "toggle":
        toggle_mode()
        return

    mode = read_mode()
    if mode == "lyrics":
        render_lyrics()
    else:
        render_clock()


if __name__ == "__main__":
    main()
