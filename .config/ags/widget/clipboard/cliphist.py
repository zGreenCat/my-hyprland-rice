#!/usr/bin/env python3
"""Puente entre cliphist y el portapapeles de AGS.

  cliphist.py list            JSON con las entradas (tipo, etiqueta, miniatura)
  cliphist.py show <entrada>  JSON con el contenido completo de una entrada
  cliphist.py copy <entrada>  copia la entrada al portapapeles
  cliphist.py delete <entrada> borra la entrada del historial
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

cache_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "cliphist"
preview_dir = cache_dir / "previews"

SHOW_MAX_CHARS = 6000
BINARY_RE = re.compile(r"\[\[ binary data (.+) \]\]")
LINK_RE = re.compile(r"^(https?|ftp)://\S+$")
COLOR_RE = re.compile(r"^(#[0-9a-fA-F]{3,8}|rgba?\([\d\s.,%]+\)|hsla?\([\d\s.,%deg]+\))$")
DIMENSIONS_RE = re.compile(r"(\d+x\d+)")


def run(command: list[str], input_data: bytes | None = None) -> bytes:
    return subprocess.run(command, input=input_data, stdout=subprocess.PIPE, check=True).stdout


def display_text(entry: str) -> str:
    return re.sub(r"^\d+\t", "", entry)


def detect_type(display: str) -> str:
    if BINARY_RE.search(display):
        return "image"
    text = display.strip()
    if LINK_RE.match(text):
        return "link"
    if COLOR_RE.match(text):
        return "color"
    return "text"


def one_line(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def image_dimensions(display: str) -> str | None:
    match = BINARY_RE.search(display)
    dims = DIMENSIONS_RE.search(match.group(1)) if match else None
    return dims.group(1).replace("x", "×") if dims else None


def image_label(display: str) -> str:
    dims = image_dimensions(display)
    return f"Imagen · {dims}" if dims else "Imagen"


def describe_text(text: str) -> str:
    lines = text.count("\n") + 1
    chars = len(text)
    line_word = "línea" if lines == 1 else "líneas"
    return f"{lines} {line_word} · {chars} caracteres"


def preview_paths(entry: str) -> tuple[Path, Path]:
    digest = hashlib.sha256(entry.encode()).hexdigest()
    return preview_dir / f"{digest}-square.png", preview_dir / f"{digest}-large.png"


def make_thumbnail(entry: str, path: Path, geometry: list[str]) -> None:
    decoded = run(["cliphist", "decode"], entry.encode())
    run(["magick", "-", *geometry, str(path)], decoded)


def list_items() -> None:
    preview_dir.mkdir(parents=True, exist_ok=True)
    keep: set[Path] = set()
    items = []

    for entry in run(["cliphist", "list"]).decode(errors="replace").splitlines():
        display = display_text(entry)
        kind = detect_type(display)
        item = {"source": entry, "type": kind, "label": one_line(display), "thumb": None}

        if kind == "image":
            small, large = preview_paths(entry)
            keep.update({small, large})
            if not small.exists():
                make_thumbnail(entry, small, ["-thumbnail", "28x28^", "-gravity", "center", "-extent", "28x28"])
            item["label"] = image_label(display)
            item["thumb"] = str(small)

        items.append(item)

    for stale in preview_dir.glob("*.png"):
        if stale not in keep:
            stale.unlink()

    print(json.dumps(items))


def show_item(entry: str) -> None:
    display = display_text(entry)
    kind = detect_type(display)

    if kind == "image":
        _, large = preview_paths(entry)
        if not large.exists():
            preview_dir.mkdir(parents=True, exist_ok=True)
            make_thumbnail(entry, large, ["-thumbnail", "1040x640>"])
        print(json.dumps({"type": kind, "meta": image_dimensions(display) or "tamaño desconocido", "image": str(large), "text": None}))
        return

    text = run(["cliphist", "decode"], entry.encode()).decode(errors="replace")
    shown = text if len(text) <= SHOW_MAX_CHARS else text[:SHOW_MAX_CHARS] + "\n…"
    print(json.dumps({"type": kind, "meta": describe_text(text), "image": None, "text": shown}))


def copy_item(entry: str) -> None:
    decoded = run(["cliphist", "decode"], entry.encode())
    subprocess.run(["wl-copy"], input=decoded, check=True)


def delete_item(entry: str) -> None:
    run(["cliphist", "delete"], entry.encode())


USAGE = "Uso: cliphist.py list | show <entrada> | copy <entrada> | delete <entrada>"
COMMANDS = {"show": show_item, "copy": copy_item, "delete": delete_item}

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "list":
        list_items()
    elif len(sys.argv) == 3 and sys.argv[1] in COMMANDS:
        COMMANDS[sys.argv[1]](sys.argv[2])
    else:
        raise SystemExit(USAGE)
