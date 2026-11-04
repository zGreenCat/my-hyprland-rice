#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys

KEYBINDS = os.path.expanduser("~/.config/hypr/configs/keybinds.conf")

SKIP_ACTIONS = {"workspace", "movetoworkspace", "focusmonitor", "movecurrentworkspacetomonitor"}
SKIP_KEY_PREFIXES = ("XF86", "mouse:")
SKIP_KEYS = {str(i) for i in range(10)} | {"mouse_down", "mouse_up"}

ACTION_LABELS = {
    "killactive":      "Cerrar ventana",
    "fullscreen":      "Pantalla completa",
    "togglefloating":  "Toggle flotante",
    "togglesplit":     "Toggle split",
    "pseudo":          "Pseudo tile",
    "movefocus":       "Mover foco",
    "movewindow":      "Mover ventana",
    "resizeactive":    "Redimensionar ventana",
}

EXEC_LABELS = {
    "$terminal":            "Terminal",
    "$fileManager":         "File manager",
    "$menu":                "App launcher",
    "hyprlock":             "Lock screen",
    "wlogout":              "Power menu",
    "wbrestart.sh":         "Reiniciar Waybar",
    "WaybarStyles.sh":      "Waybar styles",
    "WaybarLayout.sh":      "Waybar layout",
    "KillActiveProcess.sh": "Matar proceso activo",
    "cat-theme-widget.py":  "Toggle tema (widget)",
    "omenu.sh":             "Menú principal",
    "pkill -SIGUSR1 waybar":"Toggle Waybar",
    "hyprpicker -a":        "Color picker",
    "yazi":                 "File manager (Yazi)",
    "spt":                  "Spotify TUI",
    "yt":                   "YouTube Music TUI",
    "swappy":               "Screenshot + editar",
    "grim":                 "Screenshot",
    "slurp":                "Screenshot área",
}

DIR_MAP = {"l": "←", "r": "→", "u": "↑", "d": "↓",
           "mon:l": "← monitor", "mon:r": "→ monitor"}

KITTY_TITLE_RE = re.compile(r'kitty --title "([^"]+)"')

def legacy_results():
    """Lee keybinds.conf (config legacy de Hyprland)."""
    seen = set()
    results = []

    with open(KEYBINDS) as f:
        for line in f:
            line = line.strip()

            if not re.match(r'^bind[el]?\s*=', line) or line.startswith("bindm"):
                continue

            comment = ""
            if " #" in line:
                line, comment_part = line.rsplit(" #", 1)
                comment = re.sub(r"(CAMBIADO:|🐈)\s*", "", comment_part).strip()
                if comment.lower() in {"dwindle", "master"}:
                    comment = ""

            m = re.match(r"^bind[el]?\s*=\s*([^,]*),\s*([^,]+),\s*([^,]+)(?:,\s*(.*))?$", line)
            if not m:
                continue

            mods_str, key, action, args = (
                m.group(1).strip(), m.group(2).strip(),
                m.group(3).strip(), (m.group(4) or "").strip()
            )

            if any(key.startswith(p) for p in SKIP_KEY_PREFIXES) or key in SKIP_KEYS:
                continue
            if action in SKIP_ACTIONS:
                continue

            mods = []
            for part in mods_str.split():
                if part == "$mainMod":
                    mods.append("SUPER")
                elif part in ("SHIFT", "CTRL", "ALT"):
                    mods.append(part)

            combo = " + ".join(mods + [key.upper()])
            if combo in seen:
                continue
            seen.add(combo)

            if comment:
                desc = comment
            elif action in ACTION_LABELS:
                desc = ACTION_LABELS[action]
                direction = DIR_MAP.get(args.strip())
                if direction:
                    desc += f" {direction}"
            elif action == "exec":
                desc = next((label for pattern, label in EXEC_LABELS.items() if pattern in args), None)
                if not desc:
                    tm = KITTY_TITLE_RE.search(args)
                    if tm:
                        desc = tm.group(1)
                    else:
                        cmd = re.sub(r"\[.*?\]", "", args).strip()
                        cmd = re.sub(r".*/scripts/", "", cmd)
                        cmd = re.sub(r"\.sh.*", "", cmd)
                        desc = cmd[:40] if cmd else action
            elif action == "hyprctl" and "exit" in args:
                desc = "Salir de Hyprland"
            else:
                desc = action

            results.append((combo, desc))
    return results


MODMASK_ORDER = ((64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT"))
LEGACY_EVAL_MSG = "eval is only supported with the lua config manager"


def is_lua_session():
    try:
        out = subprocess.run(["hyprctl", "eval", "return 1"], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return out.stdout.strip() != LEGACY_EVAL_MSG and out.returncode == 0


def lua_results(binds):
    """Config Lua: las descripciones viven en keybinds.lua (opción description de hl.bind)."""
    results = []
    for b in binds:
        if not b.get("has_description"):
            continue
        mods = [name for bit, name in MODMASK_ORDER if b.get("modmask", 0) & bit]
        results.append((" + ".join(mods + [b["key"].upper()]), b["description"]))
    return results


def hyprctl_binds():
    out = subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=5)
    if out.returncode != 0:
        sys.exit(f"keybindings-view: hyprctl binds falló: {out.stderr.strip() or out.stdout.strip()}")
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError as e:
        sys.exit(f"keybindings-view: respuesta inválida de hyprctl binds: {e}")


results = lua_results(hyprctl_binds()) if is_lua_session() else legacy_results()

if results:
    pad = max(len(c) for c, _ in results)
    for combo, desc in results:
        print(f"{combo:<{pad}}   →  {desc}")
