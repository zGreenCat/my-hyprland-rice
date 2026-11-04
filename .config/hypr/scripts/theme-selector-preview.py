#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib
import subprocess
import os
import glob

THEMES_DIR   = os.path.expanduser("~/.config/hypr/themes")
APPLY_SCRIPT = os.path.expanduser("~/.config/hypr/scripts/apply-theme.sh")
ACTIVE_FILE  = os.path.expanduser("~/.config/hypr/.active-theme")

WINDOW_W  = 860
WINDOW_H  = 520
SIDEBAR_W = 300
PREVIEW_W = WINDOW_W - SIDEBAR_W
PREVIEW_H = int(PREVIEW_W * 9 / 16)

DEFAULTS = {
    "C_BG":      "#0a0a14", "C_CRUST":   "#050508",
    "C_SURFACE0":"#1a1a2e", "C_ACCENT":  "#aa00ff",
    "C_FG":      "#e0e0ff", "C_FG2":     "#a0a0c0",
    "C_OVERLAY": "#606080", "COLOR_SCHEME": "dark",
}


# ── helpers ───────────────────────────────────────────────────────────────

def _rgb(hex_color):
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

def rgba(hex_color, alpha):
    r, g, b = _rgb(hex_color)
    return f"rgba({r},{g},{b},{alpha})"


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


def active_theme_colors():
    active = ""
    try:
        active = open(ACTIVE_FILE).read().strip()
    except Exception:
        pass
    conf_path = os.path.join(THEMES_DIR, active, "theme.conf") if active else ""
    c = {**DEFAULTS}
    if conf_path and os.path.exists(conf_path):
        c.update(load_conf(conf_path))
    return c


def build_css(c):
    bg      = c.get("C_BG",      DEFAULTS["C_BG"])
    crust   = c.get("C_CRUST",   DEFAULTS["C_CRUST"])
    surf0   = c.get("C_SURFACE0",DEFAULTS["C_SURFACE0"])
    accent  = c.get("C_ACCENT",  DEFAULTS["C_ACCENT"])
    fg      = c.get("C_FG",      DEFAULTS["C_FG"])
    fg2     = c.get("C_FG2",     DEFAULTS["C_FG2"])
    overlay = c.get("C_OVERLAY", DEFAULTS["C_OVERLAY"])
    is_light = c.get("COLOR_SCHEME", "dark") == "light"

    # For light themes invert the chrome (use FG as bg, BG as fg)
    win_bg   = rgba(bg,    0.97) if not is_light else rgba(fg,    0.97)
    side_bg  = rgba(crust, 0.98) if not is_light else rgba(overlay, 0.15)
    text_dim = rgba(fg2,   0.55) if not is_light else rgba(crust, 0.55)
    text_hi  = rgba(fg,    0.92) if not is_light else rgba(crust, 0.92)
    text_mid = rgba(fg2,   0.38) if not is_light else rgba(crust, 0.38)
    prev_bg  = rgba(crust, 0.98) if not is_light else rgba(surf0, 0.3)
    search_c = rgba(fg,    0.45) if not is_light else rgba(crust, 0.55)
    search_f = rgba(fg,    0.80) if not is_light else rgba(crust, 0.85)

    css = f"""
window {{
    background: {win_bg};
    border-radius: 14px;
    border: 1px solid {rgba(accent, 0.30)};
}}
.sidebar {{
    background: {side_bg};
    border-radius: 14px 0 0 14px;
}}
.search-box {{
    background: {rgba(accent, 0.06)};
    border: none;
    border-bottom: 1px solid {rgba(accent, 0.15)};
    border-radius: 14px 0 0 0;
    color: {search_c};
    font-size: 14px;
    padding: 14px 18px;
    caret-color: {rgba(accent, 0.7)};
}}
.search-box:focus {{
    background: {rgba(accent, 0.10)};
    color: {search_f};
    outline: none;
    box-shadow: none;
}}
row {{
    padding: 0;
    background: transparent;
    border: none;
    outline: none;
}}
row:focus {{ outline: none; box-shadow: none; }}
.row-inner {{
    padding: 16px 24px;
    color: {text_mid};
    font-size: 18px;
    font-weight: 300;
}}
row:selected .row-inner {{
    color: {text_hi};
    background: {rgba(accent, 0.18)};
    font-weight: 400;
}}
row:hover:not(:selected) .row-inner {{
    color: {text_dim};
    background: {rgba(accent, 0.07)};
}}
.active-dot {{
    color: {rgba(accent, 0.90)};
    font-size: 8px;
    padding-right: 4px;
}}
.preview-area {{
    background: {prev_bg};
    border-radius: 0 14px 14px 0;
    padding: 28px;
}}
.preview-img-box {{
    background: {rgba(crust, 0.5)};
    border-radius: 6px;
    border: 1px solid {rgba(accent, 0.12)};
}}
.theme-label {{
    color: {text_dim};
    font-size: 14px;
    font-weight: 300;
    padding-top: 10px;
}}
"""
    return css.encode()


# ── theme list ────────────────────────────────────────────────────────────

def get_active():
    try:
        return open(ACTIVE_FILE).read().strip()
    except Exception:
        return ""


def load_themes():
    out = []
    for conf in sorted(glob.glob(f"{THEMES_DIR}/*/theme.conf")):
        folder = os.path.basename(os.path.dirname(conf))
        d = load_conf(conf)
        name    = d.get("THEME_NAME", folder)
        mode    = d.get("COLOR_SCHEME", "")
        preview = os.path.join(os.path.dirname(conf), "preview.png")
        out.append({"name": name, "folder": folder, "preview": preview, "mode": mode})
    return out


# ── widget ────────────────────────────────────────────────────────────────

class ThemeSelector(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_default_size(WINDOW_W, WINDOW_H)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        self.set_resizable(False)

        screen = self.get_screen()
        if v := screen.get_rgba_visual():
            self.set_visual(v)

        colors = active_theme_colors()
        provider = Gtk.CssProvider()
        provider.load_from_data(build_css(colors))
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.all_themes = load_themes()
        self.active     = get_active()
        self.selected   = None

        self._build()
        self.show_all()

        if self.all_themes:
            self.list_box.select_row(self.list_box.get_row_at_index(0))
            self.search.grab_focus()

    def _build(self):
        root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)

        # LEFT
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        sidebar.get_style_context().add_class("sidebar")
        sidebar.set_size_request(SIDEBAR_W, -1)

        self.search = Gtk.Entry()
        self.search.set_placeholder_text("Search ...")
        self.search.get_style_context().add_class("search-box")
        self.search.connect("changed", self._on_search)
        self.search.connect("activate", self._on_search_enter)
        sidebar.pack_start(self.search, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.list_box.set_filter_func(self._filter)
        self.list_box.connect("row-selected",  self._on_selected)
        self.list_box.connect("row-activated", self._on_activated)

        for t in self.all_themes:
            self.list_box.add(self._make_row(t))

        scroll.add(self.list_box)
        sidebar.pack_start(scroll, True, True, 0)

        # RIGHT
        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        right.get_style_context().add_class("preview-area")

        img_frame = Gtk.Box()
        img_frame.get_style_context().add_class("preview-img-box")
        img_frame.set_size_request(PREVIEW_W - 56, PREVIEW_H)
        img_frame.set_halign(Gtk.Align.CENTER)
        img_frame.set_valign(Gtk.Align.CENTER)

        self.preview_img = Gtk.Image()
        self.preview_img.set_size_request(PREVIEW_W - 56, PREVIEW_H)
        img_frame.pack_start(self.preview_img, True, True, 0)
        right.pack_start(img_frame, True, True, 0)

        self.theme_label = Gtk.Label(label="")
        self.theme_label.get_style_context().add_class("theme-label")
        self.theme_label.set_halign(Gtk.Align.START)
        right.pack_start(self.theme_label, False, False, 0)

        root.pack_start(sidebar, False, False, 0)
        root.pack_start(right,   True,  True,  0)
        self.add(root)
        self.connect("key-press-event", self._on_key)

    def _make_row(self, t):
        row = Gtk.ListBoxRow()
        row.theme_data = t
        inner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        inner.get_style_context().add_class("row-inner")
        lbl = Gtk.Label(label=t["name"])
        lbl.set_halign(Gtk.Align.START)
        inner.pack_start(lbl, True, True, 0)
        if t["folder"] == self.active:
            dot = Gtk.Label(label="●")
            dot.get_style_context().add_class("active-dot")
            inner.pack_end(dot, False, False, 0)
        row.add(inner)
        return row

    def _on_search(self, entry):
        self.list_box.invalidate_filter()
        GLib.idle_add(self._select_first_visible)

    def _select_first_visible(self):
        idx = 0
        while row := self.list_box.get_row_at_index(idx):
            if row.is_visible():
                self.list_box.select_row(row)
                break
            idx += 1

    def _on_search_enter(self, entry):
        if row := self.list_box.get_selected_row():
            self._apply(row.theme_data["folder"])

    def _filter(self, row):
        q = self.search.get_text().strip().lower()
        return not q or q in row.theme_data["name"].lower()

    def _on_selected(self, lb, row):
        if not row:
            return
        t = row.theme_data
        self.selected = t["folder"]
        mode = " · Modo claro" if t["mode"] == "light" else " · Modo oscuro" if t["mode"] == "dark" else ""
        active_str = " · Activo" if t["folder"] == self.active else ""
        self.theme_label.set_text(f"{t['name']}{mode}{active_str}")
        self._show_preview(t["preview"])

    def _on_activated(self, lb, row):
        self._apply(row.theme_data["folder"])

    def _on_key(self, w, event):
        key = event.keyval
        if key == Gdk.KEY_Escape:
            self.destroy()
        elif key in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            if self.selected:
                self._apply(self.selected)

    def _show_preview(self, path):
        if os.path.exists(path):
            try:
                pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                    path, PREVIEW_W - 56, PREVIEW_H, True
                )
                self.preview_img.set_from_pixbuf(pb)
                return
            except Exception:
                pass
        self.preview_img.clear()

    def _apply(self, folder):
        subprocess.Popen(
            ["bash", APPLY_SCRIPT, folder],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.destroy()


if __name__ == "__main__":
    win = ThemeSelector()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()
