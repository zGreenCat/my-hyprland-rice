#!/usr/bin/env python3
"""Checklist de activación de hyprland.lua (fase 4).

  checklist.py snapshot   en sesión legacy (.conf): guarda el estado de referencia
  checklist.py verify     en sesión Lua: compara contra el snapshot y prueba eval/dispatch en vivo

Las opciones comparadas salen de las llamadas hl.config reales de ~/.config/hypr/hyprland.lua
(ejecutado con el hl simulado de harness/mock.lua).
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SNAPSHOT = os.path.join(HERE, "snapshot-legacy.json")
HYPR = os.path.expanduser("~/.config/hypr")
HYPR_DO = os.path.join(HYPR, "scripts/hypr-do.sh")
LEGACY_EVAL_MSG = "eval is only supported with the lua config manager"

AUTOSTART = {
    "nm-applet": "nm-applet",
    "waybar": "waybar",
    "awww-daemon": "awww-daemon",
    "blueman-applet": "blueman-applet",
    "ags": "ags run",
    "batsignal": "batsignal",
    "xsettingsd": "xsettingsd",
    "cliphist-text": "wl-paste --type text --watch cliphist store",
    "cliphist-image": "wl-paste --type image --watch cliphist store",
}
BIND_FLAGS = ("modmask", "key", "locked", "mouse", "repeat", "release", "non_consuming")


def sh(*cmd, check=False):
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    if check and out.returncode != 0:
        sys.exit(f"checklist: {' '.join(cmd)} falló: {out.stderr.strip() or out.stdout.strip()}")
    return out.stdout.strip()


def hyprctl_json(*args):
    raw = sh("hyprctl", *args, "-j", check=True)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        sys.exit(f"checklist: 'hyprctl {' '.join(args)} -j' no devolvió JSON: {raw[:200]}")


def mode():
    return "legacy" if sh("hyprctl", "eval", "return 1") == LEGACY_EVAL_MSG else "lua"


def lua_calls():
    script = (
        f"package.path='{HYPR}/?.lua;'..package.path; "
        f"dofile('{HERE}/harness/mock.lua'); dofile('{HYPR}/hyprland.lua')"
    )
    out = subprocess.run(["lua5.4", "-e", script], capture_output=True, text=True, cwd=HYPR)
    if out.returncode != 0:
        sys.exit(f"checklist: no se pudo ejecutar hyprland.lua con el mock: {out.stderr.strip()}")
    return [line.split("\t") for line in out.stdout.splitlines()]


def option_names(calls):
    names = []

    def walk(prefix, value):
        if isinstance(value, dict) and "colors" not in value:
            for k, v in value.items():
                sep = "." if prefix.endswith(":col") or prefix == "col" else ":"
                walk(f"{prefix}{sep}{k}" if prefix else k, v)
        else:
            names.append(prefix.replace(":col:", ":col."))

    for c in calls:
        if c[0] == "config":
            walk("", json.loads(c[1]))
    return sorted(set(names))


def getoption(name):
    for candidate in (name, name.replace(":", ".")):
        out = subprocess.run(["hyprctl", "getoption", candidate, "-j"], capture_output=True, text=True, timeout=5)
        try:
            data = json.loads(out.stdout)
        except json.JSONDecodeError:
            continue
        data.pop("option", None)
        return data
    return {"error": sh("hyprctl", "getoption", name)}


def proc_env(pattern, keys):
    pids = sh("pgrep", "-xo", pattern).split()
    if not pids:
        return {"error": f"{pattern} no está corriendo"}
    with open(f"/proc/{pids[0]}/environ", "rb") as f:
        env = dict(kv.split("=", 1) for kv in f.read().decode(errors="replace").split("\0") if "=" in kv)
    return {k: env.get(k) for k in keys}


def collect(calls):
    env_keys = sorted({json.loads(c[1]) for c in calls if c[0] == "env"})
    binds = hyprctl_json("binds")
    return {
        "options": {n: getoption(n) for n in option_names(calls)},
        "binds": [{k: b.get(k) for k in BIND_FLAGS} for b in binds],
        "monitors": sorted(
            (m["name"], m["width"], m["height"], round(m["refreshRate"], 2), m["x"], m["y"], m["scale"])
            for m in hyprctl_json("monitors") if not m["name"].startswith("HEADLESS-")
        ),
        "workspacerules": sorted((r["workspaceString"], r.get("monitor")) for r in hyprctl_json("workspacerules")),
        "autostart": {name: bool(sh("pgrep", "-f", pat)) for name, pat in AUTOSTART.items()},
        "env_waybar": proc_env("waybar", env_keys),
        "keybindings_view": sh("python3", os.path.join(HYPR, "scripts/keybindings-view.py"), check=True).splitlines(),
    }


def snapshot():
    if mode() != "legacy":
        sys.exit("checklist: snapshot debe correrse en la sesión legacy (.conf)")
    data = collect(lua_calls())
    with open(SNAPSHOT, "w") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    print(f"snapshot guardado: {SNAPSHOT}")
    print(f"  {len(data['options'])} opciones, {len(data['binds'])} binds, {len(data['monitors'])} monitores, "
          f"{sum(data['autostart'].values())}/{len(data['autostart'])} autostart corriendo, "
          f"{len(data['keybindings_view'])} líneas de vista")


def verify():
    if not os.path.exists(SNAPSHOT):
        sys.exit(f"checklist: falta {SNAPSHOT}; correr 'snapshot' en la sesión legacy primero")
    with open(SNAPSHOT) as f:
        ref = json.load(f)
    results = []

    def check(name, ok, detail=""):
        results.append(ok)
        print(f"[{'PASA' if ok else 'FALLA'}] {name}{(' — ' + detail) if detail and not ok else ''}")

    m = mode()
    check("sesión en modo Lua", m == "lua", f"modo detectado: {m}")
    if m != "lua":
        sys.exit(1)
    eval_out = sh("hyprctl", "eval", "return 1")
    check("hyprctl eval responde ok", eval_out == "ok", eval_out)
    errors = sh("hyprctl", "configerrors")
    check("sin errores de config", errors in ("", "no errors"), errors[:300])
    check("hypr-do.sh detecta modo lua", sh(HYPR_DO, "mode") == "lua")

    cur = collect(lua_calls())
    diffs = {k: (v, cur["options"].get(k)) for k, v in ref["options"].items() if cur["options"].get(k) != v}
    check(f"opciones idénticas ({len(ref['options'])})", not diffs,
          "; ".join(f"{k}: legacy={a} lua={b}" for k, (a, b) in diffs.items()))
    check(f"binds idénticos en orden y flags ({len(ref['binds'])})", cur["binds"] == ref["binds"],
          f"legacy={len(ref['binds'])} lua={len(cur['binds'])}")
    check("monitores idénticos", [list(x) for x in cur["monitors"]] == ref["monitors"],
          f"{ref['monitors']} vs {cur['monitors']}")
    check("reglas de workspace idénticas", [list(x) for x in cur["workspacerules"]] == ref["workspacerules"],
          f"{ref['workspacerules']} vs {cur['workspacerules']}")
    missing = [k for k, v in ref["autostart"].items() if v and not cur["autostart"].get(k)]
    check("autostart: mismos procesos corriendo", not missing, f"faltan: {missing}")
    env_diff = {k: (v, cur["env_waybar"].get(k)) for k, v in ref["env_waybar"].items() if cur["env_waybar"].get(k) != v}
    check("variables de entorno (vistas por waybar)", not env_diff, str(env_diff))
    check("vista de atajos idéntica", cur["keybindings_view"] == ref["keybindings_view"],
          f"{len(ref['keybindings_view'])} vs {len(cur['keybindings_view'])} líneas")

    theme = os.path.join(HYPR, "themes", open(os.path.join(HYPR, ".active-theme")).read().strip(), "theme.conf")
    vals = sh("bash", "-c", f'source "{theme}"; printf "%s\\n" "$HYPR_BORDER_ACTIVE" "$HYPR_BORDER_INACTIVE" '
                            f'"$HYPR_SHADOW" "$HYPR_SHADOW_INACTIVE" "${{HYPR_ROUNDING:-12}}"').splitlines()
    before = getoption("general:col.active_border")
    out = subprocess.run([HYPR_DO, "set-colors", *vals], capture_output=True, text=True)
    check("hypr-do set-colors (eval en vivo)", out.returncode == 0, out.stderr.strip())
    check("bordes iguales tras set-colors", getoption("general:col.active_border") == before)
    out = sh("hyprctl", "reload")
    check("hyprctl reload", out == "ok", out)
    check("opciones idénticas tras reload (relee colors.lua)",
          {k: getoption(k) for k in ref["options"]} == ref["options"])

    print(f"\n{sum(results)}/{len(results)} comprobaciones pasan")
    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    if action == "snapshot":
        snapshot()
    elif action == "verify":
        verify()
    else:
        sys.exit(__doc__)
