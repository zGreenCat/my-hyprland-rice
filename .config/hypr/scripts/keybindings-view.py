#!/usr/bin/env python3
"""Lista los atajos con descripción de la sesión Hyprland (descripciones definidas en configs/keybinds.lua)."""
import json
import subprocess
import sys

MODMASK_ORDER = ((64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT"))


def lua_results(binds):
    results = []
    for b in binds:
        if not b.get("has_description"):
            continue
        mods = [name for bit, name in MODMASK_ORDER if b.get("modmask", 0) & bit]
        results.append((" + ".join(mods + [b["key"].upper()]), b["description"]))
    return results


def hyprctl_binds():
    try:
        out = subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired) as e:
        sys.exit(f"keybindings-view: no pude ejecutar hyprctl: {e}")
    if out.returncode != 0:
        sys.exit(f"keybindings-view: hyprctl binds falló: {out.stderr.strip() or out.stdout.strip()}")
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError as e:
        sys.exit(f"keybindings-view: respuesta inválida de hyprctl binds: {e}")


results = lua_results(hyprctl_binds())
if not results:
    sys.exit("keybindings-view: ningún atajo tiene descripción (¿sesión sin keybinds.lua?)")

pad = max(len(c) for c, _ in results)
for combo, desc in results:
    print(f"{combo:<{pad}}   →  {desc}")
