#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess
import os

ACTIVE_FILE  = os.path.expanduser("~/.config/hypr/.active-theme")
THEMES_DIR   = os.path.expanduser("~/.config/hypr/themes")
DEFAULTS = {
    "C_BG": "#0a0a14", "C_CRUST": "#050508", "C_SURFACE0": "#1a1a2e",
    "C_ACCENT": "#aa00ff", "C_FG": "#e0e0ff", "C_FG2": "#a0a0c0",
    "COLOR_SCHEME": "dark",
}


def _rgb(h):
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

def rgba(h, a):
    r, g, b = _rgb(h)
    return f"rgba({r},{g},{b},{a})"

def load_conf(path):
    out = {}
    try:
        for line in open(path):
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip().strip('"')
    except Exception:
        pass
    return out

def active_colors():
    active = ""
    try: active = open(ACTIVE_FILE).read().strip()
    except Exception: pass
    c = {**DEFAULTS}
    p = os.path.join(THEMES_DIR, active, "theme.conf")
    if active and os.path.exists(p):
        c.update(load_conf(p))
    return c

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except Exception:
        return ""

def set_vol(val):
    subprocess.run(f"pamixer --set-volume {int(val)}", shell=True)

def set_bright(val):
    subprocess.run(f"brightnessctl set {int(val)}%", shell=True)

def get_vol():
    v = run("pamixer --get-volume")
    return int(v) if v.isdigit() else 50

def get_vol_muted():
    return run("pamixer --get-mute") == "true"

def get_bright():
    cur = run("brightnessctl get")
    max_ = run("brightnessctl max")
    if cur and max_ and int(max_) > 0:
        return round(int(cur) / int(max_) * 100)
    return 50

def get_battery():
    cap = run("cat /sys/class/power_supply/BAT0/capacity 2>/dev/null")
    status = run("cat /sys/class/power_supply/BAT0/status 2>/dev/null")
    if not cap: return None, None
    icon = "󰂄" if status == "Charging" else ("󰁺" if int(cap) < 20 else "󰁿" if int(cap) < 50 else "󰂀" if int(cap) < 80 else "󰁹")
    return int(cap), icon

def get_wifi():
    name = run("nmcli -t -f NAME connection show --active 2>/dev/null | head -1")
    return name if name else "Desconectado"

def get_music():
    status = run("playerctl status 2>/dev/null")
    if status not in ("Playing", "Paused"):
        return None, None
    artist = run("playerctl metadata artist 2>/dev/null")
    title  = run("playerctl metadata title 2>/dev/null")
    text   = f"{artist} — {title}" if artist else title
    icon   = "󰏤" if status == "Paused" else "󰎆"
    return icon, text[:42] + "…" if len(text) > 42 else text


class QuickSettings(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_title("Quick Settings")
        self.set_default_size(340, 10)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_app_paintable(True)
        self.set_resizable(False)

        screen = self.get_screen()
        if v := screen.get_rgba_visual():
            self.set_visual(v)

        c = active_colors()
        is_light = c.get("COLOR_SCHEME") == "light"
        bg      = c.get("C_CRUST", DEFAULTS["C_CRUST"])
        accent  = c.get("C_ACCENT", DEFAULTS["C_ACCENT"])
        fg      = c.get("C_FG",    DEFAULTS["C_FG"])
        fg2     = c.get("C_FG2",   DEFAULTS["C_FG2"])
        surf    = c.get("C_SURFACE0", DEFAULTS["C_SURFACE0"])

        if is_light:
            bg, fg, fg2, surf = fg, bg, c.get("C_OVERLAY","#606080"), c.get("C_MANTLE","#e0e0e0")

        css = f"""
window {{
    background: {rgba(bg, 0.97)};
    border-radius: 14px;
    border: 1px solid {rgba(accent, 0.25)};
}}
.section-label {{
    color: {rgba(accent, 0.7)};
    font-size: 10px;
    font-weight: bold;
    letter-spacing: 1px;
    padding: 14px 18px 4px 18px;
}}
.row-box {{ padding: 4px 18px 4px 18px; }}
.icon-label {{
    color: {rgba(fg, 0.6)};
    font-size: 16px;
    min-width: 28px;
}}
.value-label {{
    color: {rgba(fg, 0.85)};
    font-size: 13px;
}}
.sub-label {{
    color: {rgba(fg2, 0.6)};
    font-size: 11px;
}}
scale trough {{
    background: {rgba(surf, 0.8)};
    border-radius: 4px;
    min-height: 4px;
}}
scale highlight {{
    background: {rgba(accent, 0.9)};
    border-radius: 4px;
}}
scale slider {{
    background: {rgba(accent, 1.0)};
    border-radius: 50%;
    min-width: 14px;
    min-height: 14px;
    border: none;
}}
.divider {{
    background: {rgba(fg, 0.06)};
    min-height: 1px;
    margin: 6px 18px;
}}
""".encode()

        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self._build(box)
        self.add(box)
        self.connect("key-press-event", self._on_key)
        self.connect("focus-out-event", lambda *_: self.destroy())
        self.show_all()

    def _section(self, label):
        lbl = Gtk.Label(label=label)
        lbl.get_style_context().add_class("section-label")
        lbl.set_halign(Gtk.Align.START)
        return lbl

    def _divider(self):
        d = Gtk.Box()
        d.get_style_context().add_class("divider")
        return d

    def _slider_row(self, icon, value, on_change):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("row-box")

        ico = Gtk.Label(label=icon)
        ico.get_style_context().add_class("icon-label")
        row.pack_start(ico, False, False, 0)

        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        scale.set_value(value)
        scale.set_draw_value(False)
        scale.set_hexpand(True)
        scale.connect("value-changed", lambda s: on_change(s.get_value()))
        row.pack_start(scale, True, True, 0)

        val_lbl = Gtk.Label(label=f"{value}%")
        val_lbl.get_style_context().add_class("value-label")
        val_lbl.set_width_chars(4)
        scale.connect("value-changed", lambda s, l=val_lbl: l.set_text(f"{int(s.get_value())}%"))
        row.pack_start(val_lbl, False, False, 0)
        return row

    def _info_row(self, icon, text, sub=None):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("row-box")

        ico = Gtk.Label(label=icon)
        ico.get_style_context().add_class("icon-label")
        row.pack_start(ico, False, False, 0)

        if sub:
            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
            lbl = Gtk.Label(label=text)
            lbl.get_style_context().add_class("value-label")
            lbl.set_halign(Gtk.Align.START)
            sub_lbl = Gtk.Label(label=sub)
            sub_lbl.get_style_context().add_class("sub-label")
            sub_lbl.set_halign(Gtk.Align.START)
            vbox.pack_start(lbl, False, False, 0)
            vbox.pack_start(sub_lbl, False, False, 0)
            row.pack_start(vbox, True, True, 0)
        else:
            lbl = Gtk.Label(label=text)
            lbl.get_style_context().add_class("value-label")
            lbl.set_halign(Gtk.Align.START)
            row.pack_start(lbl, True, True, 0)
        return row

    def _build(self, box):
        box.pack_start(self._section("AUDIO & DISPLAY"), False, False, 0)
        muted = get_vol_muted()
        vol_icon = "󰸈" if muted else "󰕾"
        box.pack_start(self._slider_row(vol_icon, get_vol(), set_vol), False, False, 0)
        box.pack_start(self._slider_row("󰃟", get_bright(), set_bright), False, False, 0)

        bat_cap, bat_icon = get_battery()
        wifi = get_wifi()
        music_icon, music_text = get_music()

        if bat_cap is not None or wifi:
            box.pack_start(self._divider(), False, False, 0)
            box.pack_start(self._section("SISTEMA"), False, False, 0)
            if bat_cap is not None:
                box.pack_start(self._info_row(bat_icon, f"{bat_cap}%"), False, False, 0)
            if wifi:
                box.pack_start(self._info_row("󰤨", wifi), False, False, 0)

        if music_text:
            box.pack_start(self._divider(), False, False, 0)
            box.pack_start(self._section("MÚSICA"), False, False, 0)
            box.pack_start(self._info_row(music_icon, music_text), False, False, 0)

        box.pack_start(Gtk.Box(spacing=0), False, False, 8)

    def _on_key(self, w, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()


if __name__ == "__main__":
    win = QuickSettings()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()
