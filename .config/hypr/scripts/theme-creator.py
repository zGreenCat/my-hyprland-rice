#!/usr/bin/env python3
"""Creador visual de temas para el rice.

Sugiere una paleta completa desde un wallpaper (PIL + numpy), deja ajustarla con
pickers nativos y preview en vivo, y escribe un theme.conf válido (hex de 6
dígitos garantizado). Solo ofrece assets (GTK/icon/cursor) instalados.
"""
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib

import os
import re
import glob
import colorsys
import subprocess

from PIL import Image, ImageDraw

HOME         = os.path.expanduser("~")
THEMES_DIR   = os.path.join(HOME, ".config/hypr/themes")
APPLY_SCRIPT = os.path.join(HOME, ".config/hypr/scripts/apply-theme.sh")
WALL_DIR     = os.path.join(HOME, "Pictures/wallpapers")

ICON_DIRS = [os.path.join(HOME, ".local/share/icons"),
             os.path.join(HOME, ".icons"),
             "/usr/share/icons"]
GTK_DIRS  = [os.path.join(HOME, ".themes"), "/usr/share/themes"]

# Orden de la paleta tal como aparece en los theme.conf existentes.
PALETTE_KEYS = [
    "C_BG", "C_MANTLE", "C_CRUST", "C_SURFACE0", "C_SURFACE1", "C_SURFACE2",
    "C_OVERLAY", "C_FG", "C_FG2", "C_ACCENT", "C_BLUE", "C_GREEN", "C_YELLOW",
    "C_RED", "C_CYAN", "C_PINK", "C_LAVENDER",
]

# Descripción del rol de cada color (tooltip al pasar el cursor).
PALETTE_HELP = {
    "C_BG":       "Fondo principal del escritorio y ventanas.",
    "C_MANTLE":   "Fondo un paso más oscuro (paneles, barras).",
    "C_CRUST":    "El fondo más oscuro (sombras, fondo de ventana activa).",
    "C_SURFACE0": "Superficie elevada: tarjetas, inputs, waybar.",
    "C_SURFACE1": "Superficie elevada media: hover, filas.",
    "C_SURFACE2": "Superficie elevada alta: elemento seleccionado/activo.",
    "C_OVERLAY":  "Bordes suaves, separadores, texto deshabilitado.",
    "C_FG":       "Texto principal.",
    "C_FG2":      "Texto secundario / atenuado.",
    "C_ACCENT":   "Color estrella: foco, resaltados, borde activo.",
    "C_BLUE":     "Semántico azul: info, enlaces.",
    "C_GREEN":    "Semántico verde: éxito / ok.",
    "C_YELLOW":   "Semántico amarillo: advertencias.",
    "C_RED":      "Semántico rojo: errores, urgente.",
    "C_CYAN":     "Acento secundario cian.",
    "C_PINK":     "Acento decorativo rosa.",
    "C_LAVENDER": "Acento decorativo lavanda.",
}

# Hue canónico (0..1) de cada color semántico.
CANON_HUES = {
    "C_RED": 0 / 360, "C_YELLOW": 48 / 360, "C_GREEN": 130 / 360,
    "C_CYAN": 185 / 360, "C_BLUE": 215 / 360, "C_LAVENDER": 260 / 360,
    "C_PINK": 320 / 360,
}


# ── helpers de color ───────────────────────────────────────────────────────

def clamp01(x):
    return max(0.0, min(1.0, x))


def hex_rgb(hx):
    h = hx.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def hex_of(r, g, b):
    return "#%02x%02x%02x" % (
        int(round(max(0, min(255, r)))),
        int(round(max(0, min(255, g)))),
        int(round(max(0, min(255, b)))),
    )


def rgb_hsv(r, g, b):
    return colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)


def hsv_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, clamp01(s), clamp01(v))
    return hex_of(r * 255, g * 255, b * 255)


def gdk_of(hx):
    r, g, b = hex_rgb(hx)
    c = Gdk.RGBA()
    c.red, c.green, c.blue, c.alpha = r / 255, g / 255, b / 255, 1.0
    return c


def rgba_hex(c):
    return hex_of(c.red * 255, c.green * 255, c.blue * 255)


# ── motor de paleta ────────────────────────────────────────────────────────

def extract_dominants(path, n=16):
    im = Image.open(path).convert("RGB")
    im.thumbnail((200, 200))
    q = im.quantize(colors=n, method=Image.Quantize.MEDIANCUT).convert("RGB")
    cols = q.getcolors(200 * 200) or []
    cols.sort(key=lambda c: -c[0])
    return [c[1] for c in cols]


def suggest_palette(path, scheme="dark"):
    rgbs = extract_dominants(path, 16)
    hsvs = [rgb_hsv(*c) for c in rgbs]

    # Acento: dominante más vívido (saturación·valor), con saturación mínima.
    cand = [i for i in range(len(hsvs)) if hsvs[i][1] > 0.2] or list(range(len(hsvs)))
    ai = max(cand, key=lambda i: hsvs[i][1] * hsvs[i][2])
    ah, asat, _ = hsvs[ai]
    accent = hex_of(*rgbs[ai])

    pal = {"C_ACCENT": accent}

    if scheme == "dark":
        ladder = {"C_CRUST": 0.03, "C_MANTLE": 0.05, "C_BG": 0.08,
                  "C_SURFACE0": 0.13, "C_SURFACE1": 0.18, "C_SURFACE2": 0.24,
                  "C_OVERLAY": 0.40}
        tint = min(0.25, asat * 0.5)
        for k, v in ladder.items():
            pal[k] = hsv_hex(ah, tint, v)
        light = [i for i, (h, s, v) in enumerate(hsvs) if v > 0.8 and s < 0.25]
        pal["C_FG"] = hex_of(*rgbs[light[0]]) if light else hsv_hex(ah, 0.08, 0.92)
        pal["C_FG2"] = hsv_hex(ah, 0.12, 0.70)
        sem_v, sem_s = 0.85, 0.65
    else:
        ladder = {"C_CRUST": 0.99, "C_MANTLE": 0.97, "C_BG": 0.95,
                  "C_SURFACE0": 0.90, "C_SURFACE1": 0.84, "C_SURFACE2": 0.78,
                  "C_OVERLAY": 0.58}
        tint = min(0.12, asat * 0.3)
        for k, v in ladder.items():
            pal[k] = hsv_hex(ah, tint, v)
        pal["C_FG"] = hsv_hex(ah, 0.55, 0.16)
        pal["C_FG2"] = hsv_hex(ah, 0.40, 0.34)
        sem_v, sem_s = 0.55, 0.70

    for key, th in CANON_HUES.items():
        match = None
        for (h, s, v) in hsvs:
            if s < 0.3:
                continue
            d = abs(h - th)
            d = min(d, 1 - d)
            if d < 25 / 360:
                match = (h, s, v)
                break
        if match:
            h, s, v = match
            pal[key] = hsv_hex(h, max(s, 0.6), max(v, 0.65))
        else:
            pal[key] = hsv_hex(th, max(asat, sem_s), sem_v)

    return pal


def chrome_of(pal, rounding, waybar):
    ah, asat, av = rgb_hsv(*hex_rgb(pal["C_ACCENT"]))
    a2 = hsv_hex(ah + 30 / 360, asat, av)
    a3 = hsv_hex(ah + 90 / 360, asat, av)

    def rgbfn(hx):
        return "rgb(%s)" % hx.lstrip("#")

    return {
        "HYPR_BORDER_ACTIVE": f"{rgbfn(pal['C_ACCENT'])} {rgbfn(a2)} {rgbfn(a3)} 45deg",
        "HYPR_BORDER_INACTIVE": rgbfn(pal["C_BG"]),
        "HYPR_SHADOW": "rgba(%s44)" % pal["C_ACCENT"].lstrip("#"),
        "HYPR_SHADOW_INACTIVE": "rgba(00000099)",
        "HYPR_ROUNDING": rounding,
        "WAYBAR_LAYOUT": waybar,
    }


# ── descubrimiento de assets instalados ────────────────────────────────────

_ICON_HINTS = {"apps", "places", "actions", "devices", "mimetypes", "status",
               "categories", "scalable", "16x16", "22x22", "24x24", "48x48"}


def list_icon_themes():
    res = set()
    for d in ICON_DIRS:
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            p = os.path.join(d, name)
            if not os.path.isfile(os.path.join(p, "index.theme")):
                continue
            if _ICON_HINTS & set(os.listdir(p)):
                res.add(name)
    return sorted(res)


def list_cursor_themes():
    res = set()
    for d in ICON_DIRS:
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            p = os.path.join(d, name)
            if os.path.isdir(os.path.join(p, "cursors")):
                res.add(name)
    return sorted(res)


def list_gtk_themes():
    res = set()
    for d in GTK_DIRS:
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            # Saltar variantes de densidad duplicadas (ruido visual).
            if name.endswith(("-hdpi", "-xhdpi")):
                continue
            p = os.path.join(d, name)
            if os.path.isfile(os.path.join(p, "gtk-3.0/gtk.css")) or \
               os.path.isdir(os.path.join(p, "gtk-4.0")):
                res.add(name)
    return sorted(res)


def list_existing_themes():
    return sorted(os.path.basename(os.path.dirname(c))
                  for c in glob.glob(f"{THEMES_DIR}/*/theme.conf"))


# ── preview de assets (GTK / iconos) ───────────────────────────────────────

PREVIEW_ICONS = ["folder", "system-file-manager", "web-browser",
                 "utilities-terminal", "preferences-system", "user-trash"]

# Colores CSS con nombre que aparecen en @define-color (mínimo necesario).
_CSS_NAMED = {"white": "#ffffff", "black": "#000000", "red": "#ff0000",
              "green": "#008000", "blue": "#0000ff", "gray": "#808080",
              "grey": "#808080", "transparent": "#000000"}

_DEFINE_RE = re.compile(
    r"@define-color\s+(theme_bg_color|theme_base_color|theme_fg_color|"
    r"theme_selected_bg_color)\s+([^;]+);")


def gtk_theme_dir(name):
    for d in GTK_DIRS:
        p = os.path.join(d, name)
        if os.path.isdir(p):
            return p
    return None


def gtk_preview_path(name):
    """Ruta al thumbnail.png del tema GTK, si existe (convención GNOME Tweaks)."""
    base = gtk_theme_dir(name)
    if not base:
        return None
    thumb = os.path.join(base, "gtk-3.0", "thumbnail.png")
    return thumb if os.path.isfile(thumb) else None


def _resolve_css_color(val):
    val = val.strip()
    if val.startswith("#"):
        h = val[1:]
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        if len(h) >= 6 and re.match(r"^[0-9a-fA-F]{6}$", h[:6]):
            return "#" + h[:6].lower()
    return _CSS_NAMED.get(val.lower())


def gtk_preview_colors(name):
    """Lista [bg, base, fg, selected] de hex desde gtk.css, o [] si no hay."""
    base = gtk_theme_dir(name)
    if not base:
        return []
    css = os.path.join(base, "gtk-3.0", "gtk.css")
    if not os.path.isfile(css):
        return []
    try:
        text = open(css, encoding="utf-8", errors="ignore").read()
    except Exception:
        return []
    found = {}
    for key, val in _DEFINE_RE.findall(text):
        hexv = _resolve_css_color(val)
        if hexv and key not in found:
            found[key] = hexv
    order = ["theme_bg_color", "theme_base_color", "theme_fg_color",
             "theme_selected_bg_color"]
    return [found[k] for k in order if k in found]


def slugify(name):
    s = re.sub(r"[^a-z0-9]+", "-", name.strip().lower()).strip("-")
    return s or "tema"


# ── escritura de tema ──────────────────────────────────────────────────────

def wall_token(path):
    if path and path.startswith(HOME):
        return "$HOME" + path[len(HOME):]
    return path or ""


def write_theme(slug, name, scheme, pal, assets, rounding, waybar,
                wallpaper, counterpart):
    folder = os.path.join(THEMES_DIR, slug)
    os.makedirs(folder, exist_ok=True)
    chrome = chrome_of(pal, rounding, waybar)
    lines = [
        f'THEME_NAME="{name}"',
        f'COLOR_SCHEME="{scheme}"',
        f'COUNTERPART="{counterpart}"',
        f'WALLPAPER="{wall_token(wallpaper)}"',
        f'GTK_THEME="{assets["gtk"]}"',
        f'ICON_THEME="{assets["icon"]}"',
        f'CURSOR_THEME="{assets["cursor"]}"',
        "",
    ]
    for k in PALETTE_KEYS:
        lines.append(f'{k}="{pal[k]}"')
    lines.append("")
    lines.append(f'HYPR_BORDER_ACTIVE="{chrome["HYPR_BORDER_ACTIVE"]}"')
    lines.append(f'HYPR_BORDER_INACTIVE="{chrome["HYPR_BORDER_INACTIVE"]}"')
    lines.append(f'HYPR_SHADOW="{chrome["HYPR_SHADOW"]}"')
    lines.append(f'HYPR_SHADOW_INACTIVE="{chrome["HYPR_SHADOW_INACTIVE"]}"')
    lines.append(f'HYPR_ROUNDING={rounding}')
    lines.append(f'WAYBAR_LAYOUT="{waybar}"')
    with open(os.path.join(folder, "theme.conf"), "w") as f:
        f.write("\n".join(lines) + "\n")
    gen_preview(os.path.join(folder, "preview.png"), pal, wallpaper)
    return folder


def gen_preview(out_path, pal, wallpaper=None):
    """Genera preview.png para el selector: el wallpaper (cover-fit) con una
    franja de paleta abajo, igual de proporción que los demás temas. Si no hay
    wallpaper válido, cae a una tira de swatches."""
    w, h = 1280, 720
    strip_keys = ["C_ACCENT", "C_BLUE", "C_GREEN", "C_YELLOW", "C_RED",
                  "C_CYAN", "C_PINK", "C_LAVENDER"]

    base = None
    if wallpaper and os.path.isfile(wallpaper):
        try:
            src = Image.open(wallpaper).convert("RGB")
            sw, sh = src.size
            scale = max(w / sw, h / sh)            # cover
            rs = src.resize((max(1, int(sw * scale)), max(1, int(sh * scale))))
            rw, rh = rs.size
            left, top = (rw - w) // 2, (rh - h) // 2
            base = rs.crop((left, top, left + w, top + h))
        except Exception:
            base = None

    if base is None:                               # fallback: solo swatches
        base = Image.new("RGB", (w, h), hex_rgb(pal["C_BG"]))
        d = ImageDraw.Draw(base)
        n = len(strip_keys)
        bw = w / n
        for i, k in enumerate(strip_keys):
            d.rectangle([i * bw, h * 0.5, (i + 1) * bw, h], fill=hex_rgb(pal[k]))
        d.rectangle([60, 60, w - 60, h * 0.42], outline=hex_rgb(pal["C_ACCENT"]), width=6)
        base.save(out_path)
        return

    # Franja de paleta en el borde inferior.
    d = ImageDraw.Draw(base)
    sh = int(h * 0.07)
    bw = w / len(strip_keys)
    for i, k in enumerate(strip_keys):
        d.rectangle([i * bw, h - sh, (i + 1) * bw, h], fill=hex_rgb(pal[k]))
    base.save(out_path)


# ── preview en vivo (CSS) ──────────────────────────────────────────────────

def preview_css(pal):
    return f"""
.pv-desktop {{ background:{pal['C_BG']}; border-radius:10px; }}
.pv-bar {{ background:{pal['C_SURFACE0']}; border-radius:8px;
           margin:10px; padding:8px 14px; }}
.pv-bar-txt {{ color:{pal['C_FG']}; font-size:13px; }}
.pv-bar-acc {{ color:{pal['C_ACCENT']}; font-weight:bold; }}
.pv-win {{ background:{pal['C_CRUST']}; border-radius:10px;
           border:2px solid {pal['C_ACCENT']}; margin:10px 28px; padding:16px; }}
.pv-title {{ color:{pal['C_FG']}; font-size:15px; font-weight:bold; }}
.pv-body {{ color:{pal['C_FG2']}; font-size:12px; }}
.pv-btn {{ background:{pal['C_ACCENT']}; color:{pal['C_BG']};
           border-radius:6px; padding:4px 14px; font-weight:bold; }}
.pv-chip-b {{ color:{pal['C_BLUE']}; }}
.pv-chip-g {{ color:{pal['C_GREEN']}; }}
.pv-chip-r {{ color:{pal['C_RED']}; }}
""".encode()


# ── ventana ────────────────────────────────────────────────────────────────

class Creator(Gtk.Window):
    def __init__(self):
        super().__init__(title="Nuevo tema")
        self.set_default_size(1040, 780)
        self.set_position(Gtk.WindowPosition.CENTER)

        self.wallpaper = None
        self.scheme = "dark"
        self.color_btns = {}

        self.pv_provider = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_screen(
            self.get_screen(), self.pv_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self._build()
        self.show_all()

        walls = self._wallpapers()
        if walls:
            self._load_wallpaper(walls[0])
        else:
            self._set_palette({k: "#202030" for k in PALETTE_KEYS})

    # -- construcción ---------------------------------------------------------

    def _build(self):
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        root.set_border_width(12)

        # TOP: metadata
        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        top.pack_start(Gtk.Label(label="Nombre:"), False, False, 0)
        self.name_entry = Gtk.Entry()
        self.name_entry.set_placeholder_text("Mi Tema")
        self.name_entry.set_width_chars(18)
        self.name_entry.set_tooltip_text("Nombre visible en el selector. La carpeta usa una versión en minúsculas con guiones.")
        top.pack_start(self.name_entry, False, False, 0)

        self.rb_dark = Gtk.RadioButton.new_with_label_from_widget(None, "Oscuro")
        self.rb_light = Gtk.RadioButton.new_with_label_from_widget(self.rb_dark, "Claro")
        self.rb_dark.set_tooltip_text("Esquema base. 'Claro' invierte el chrome (fondos claros, texto oscuro).")
        self.rb_light.set_tooltip_text("Esquema base. 'Claro' invierte el chrome (fondos claros, texto oscuro).")
        self.rb_dark.connect("toggled", self._on_scheme)
        top.pack_start(self.rb_dark, False, False, 0)
        top.pack_start(self.rb_light, False, False, 0)

        self.cb_counter = Gtk.CheckButton(label="Generar contraparte")
        self.cb_counter.set_tooltip_text("Crea también el gemelo claro/oscuro del mismo wallpaper, enlazado con COUNTERPART (lo usa Super+T).")
        top.pack_start(self.cb_counter, False, False, 0)

        round_lbl = Gtk.Label(label="Redondeo:")
        round_lbl.set_tooltip_text("Redondeo de esquinas de las ventanas, en píxeles (HYPR_ROUNDING).")
        top.pack_start(round_lbl, False, False, 0)
        self.spin_round = Gtk.SpinButton.new_with_range(0, 30, 1)
        self.spin_round.set_value(10)
        self.spin_round.set_tooltip_text("Redondeo de esquinas de las ventanas, en píxeles (HYPR_ROUNDING).")
        top.pack_start(self.spin_round, False, False, 0)

        self.cb_float = Gtk.CheckButton(label="Waybar flotante")
        self.cb_float.set_active(True)
        self.cb_float.set_tooltip_text("Barra separada de los bordes (floating) vs pegada arriba (normal).")
        top.pack_start(self.cb_float, False, False, 0)
        root.pack_start(top, False, False, 0)

        # MIDDLE: wallpapers | preview
        mid = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        left.set_size_request(280, -1)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.wall_flow = Gtk.FlowBox()
        self.wall_flow.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.wall_flow.set_max_children_per_line(2)
        self.wall_flow.set_tooltip_text("Elige un wallpaper: se sugiere una paleta automáticamente desde sus colores.")
        self.wall_flow.connect("child-activated", self._on_wall)
        for path in self._wallpapers():
            self.wall_flow.add(self._wall_thumb(path))
        scroll.add(self.wall_flow)
        left.pack_start(scroll, True, True, 0)
        browse = Gtk.Button(label="Examinar…")
        browse.connect("clicked", self._on_browse)
        left.pack_start(browse, False, False, 0)
        mid.pack_start(left, False, False, 0)

        self.preview_box = self._build_preview()
        mid.pack_start(self.preview_box, True, True, 0)
        root.pack_start(mid, True, True, 0)

        # COLOR ROW
        hint = Gtk.Label(label="Colores — pasa el cursor por cada uno para ver su uso. Click = picker.")
        hint.set_halign(Gtk.Align.START)
        hint.set_opacity(0.6)
        root.pack_start(hint, False, False, 0)

        cflow = Gtk.FlowBox()
        cflow.set_selection_mode(Gtk.SelectionMode.NONE)
        cflow.set_max_children_per_line(17)
        cflow.set_min_children_per_line(9)
        for key in PALETTE_KEYS:
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            help_txt = f"{key} — {PALETTE_HELP.get(key, '')}"
            lbl = Gtk.Label(label=key.replace("C_", ""))
            lbl.set_max_width_chars(8)
            lbl.set_tooltip_text(help_txt)
            btn = Gtk.ColorButton()
            btn.set_title(key)
            btn.set_tooltip_text(help_txt)
            btn.connect("color-set", self._on_color, key)
            self.color_btns[key] = btn
            box.pack_start(btn, False, False, 0)
            box.pack_start(lbl, False, False, 0)
            cflow.add(box)
        root.pack_start(cflow, False, False, 0)

        # ASSETS ROW
        self.icon_combo = self._combo(list_icon_themes(),
                                      ["Papirus-Dark", "Papirus", "Adwaita"])
        self.gtk_combo = self._combo(list_gtk_themes(),
                                     ["Sweet-Dark", "Sweet", "Adwaita-dark", "Adwaita"])
        self.cursor_combo = self._combo(list_cursor_themes(),
                                        ["Bibata-Modern-Classic", "Bibata-Modern-Ice", "Adwaita"])
        self.counter_combo = self._combo([""] + list_existing_themes(), "")
        tips = {
            "Iconos": "Set de iconos del tema. Solo aparecen los instalados en el sistema.",
            "GTK": "Tema de apps GTK (ventanas de configuración, Nautilus…). Solo instalados.",
            "Cursor": "Tema del cursor del mouse. Solo instalados.",
            "Contraparte": "Tema opuesto claro/oscuro para Super+T. Se ignora si marcas 'Generar contraparte'.",
        }
        for cap, w in (("Iconos", self.icon_combo), ("GTK", self.gtk_combo),
                       ("Cursor", self.cursor_combo), ("Contraparte", self.counter_combo)):
            w.set_tooltip_text(tips[cap])

        assets_col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)

        # Bloques con preview en vivo: iconos | GTK
        pv_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)

        ib = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        ihdr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        icl = Gtk.Label(label="Iconos:"); icl.set_tooltip_text(tips["Iconos"])
        ihdr.pack_start(icl, False, False, 0)
        ihdr.pack_start(self.icon_combo, False, False, 0)
        ib.pack_start(ihdr, False, False, 0)
        self.icon_preview = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        ib.pack_start(self.icon_preview, False, False, 0)
        pv_row.pack_start(ib, False, False, 0)

        gb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        ghdr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        gcl = Gtk.Label(label="GTK:"); gcl.set_tooltip_text(tips["GTK"])
        ghdr.pack_start(gcl, False, False, 0)
        ghdr.pack_start(self.gtk_combo, False, False, 0)
        gb.pack_start(ghdr, False, False, 0)
        self.gtk_preview = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        gb.pack_start(self.gtk_preview, False, False, 0)
        pv_row.pack_start(gb, False, False, 0)

        assets_col.pack_start(pv_row, False, False, 0)

        # Cursor + Contraparte (sin preview)
        crow = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        for cap, w in (("Cursor", self.cursor_combo), ("Contraparte", self.counter_combo)):
            cl = Gtk.Label(label=cap + ":")
            cl.set_tooltip_text(tips[cap])
            crow.pack_start(cl, False, False, 0)
            crow.pack_start(w, False, False, 0)
        assets_col.pack_start(crow, False, False, 0)
        root.pack_start(assets_col, False, False, 0)

        self.icon_combo.connect("changed", lambda *_: self._refresh_icon_preview())
        self.gtk_combo.connect("changed", lambda *_: self._refresh_gtk_preview())
        self._refresh_icon_preview()
        self._refresh_gtk_preview()

        # BOTTOM
        bottom = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.status = Gtk.Label(label="")
        self.status.set_halign(Gtk.Align.START)
        bottom.pack_start(self.status, True, True, 0)
        cancel = Gtk.Button(label="Cancelar")
        cancel.connect("clicked", lambda *_: self.destroy())
        save = Gtk.Button(label="Guardar")
        save.connect("clicked", self._on_save, False)
        apply_btn = Gtk.Button(label="Guardar y aplicar")
        apply_btn.connect("clicked", self._on_save, True)
        for b in (cancel, save, apply_btn):
            bottom.pack_start(b, False, False, 0)
        root.pack_start(bottom, False, False, 0)

        self.add(root)
        self.connect("key-press-event",
                     lambda w, e: self.destroy() if e.keyval == Gdk.KEY_Escape else None)

    def _clear_box(self, box):
        for c in box.get_children():
            box.remove(c)

    def _swatch(self, hexv, size=34):
        pb = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, size, size)
        r, g, b = hex_rgb(hexv)
        pb.fill((r << 24) | (g << 16) | (b << 8) | 0xff)
        return Gtk.Image.new_from_pixbuf(pb)

    def _refresh_icon_preview(self):
        self._clear_box(self.icon_preview)
        name = self.icon_combo.get_active_text()
        if not name:
            return
        it = Gtk.IconTheme.new()
        it.set_custom_theme(name)
        for n in PREVIEW_ICONS:
            try:
                pb = it.load_icon(n, 40, Gtk.IconLookupFlags.FORCE_SIZE)
            except Exception:
                pb = None
            if pb is not None:
                self.icon_preview.pack_start(Gtk.Image.new_from_pixbuf(pb), False, False, 0)
        self.icon_preview.show_all()

    def _refresh_gtk_preview(self):
        self._clear_box(self.gtk_preview)
        name = self.gtk_combo.get_active_text()
        if not name:
            return
        thumb = gtk_preview_path(name)
        if thumb:
            try:
                pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(thumb, 200, 120, True)
                self.gtk_preview.pack_start(Gtk.Image.new_from_pixbuf(pb), False, False, 0)
                self.gtk_preview.show_all()
                return
            except Exception:
                pass
        colors = gtk_preview_colors(name)
        if colors:
            for hx in colors:
                self.gtk_preview.pack_start(self._swatch(hx), False, False, 0)
        else:
            self.gtk_preview.pack_start(Gtk.Label(label="(sin preview)"), False, False, 0)
        self.gtk_preview.show_all()

    def _build_preview(self):
        desk = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        desk.get_style_context().add_class("pv-desktop")

        bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        bar.get_style_context().add_class("pv-bar")
        l1 = Gtk.Label(label="  workspace 1")
        l1.get_style_context().add_class("pv-bar-acc")
        l2 = Gtk.Label(label="2  3  4")
        l2.get_style_context().add_class("pv-bar-txt")
        l3 = Gtk.Label(label="  100%   12:30")
        l3.get_style_context().add_class("pv-bar-txt")
        bar.pack_start(l1, False, False, 0)
        bar.pack_start(l2, False, False, 0)
        bar.pack_end(l3, False, False, 0)
        desk.pack_start(bar, False, False, 0)

        win = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        win.get_style_context().add_class("pv-win")
        t = Gtk.Label(label="Ventana activa")
        t.set_halign(Gtk.Align.START)
        t.get_style_context().add_class("pv-title")
        body = Gtk.Label(label="Texto secundario de ejemplo para ver contraste.")
        body.set_halign(Gtk.Align.START)
        body.get_style_context().add_class("pv-body")
        chips = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        for cls, txt in (("pv-chip-b", "● info"), ("pv-chip-g", "● ok"),
                         ("pv-chip-r", "● error")):
            c = Gtk.Label(label=txt)
            c.get_style_context().add_class(cls)
            chips.pack_start(c, False, False, 0)
        btn = Gtk.Label(label="  Acento  ")
        btn.get_style_context().add_class("pv-btn")
        btn.set_halign(Gtk.Align.START)
        win.pack_start(t, False, False, 0)
        win.pack_start(body, False, False, 0)
        win.pack_start(chips, False, False, 0)
        win.pack_start(btn, False, False, 0)
        desk.pack_start(win, True, True, 0)
        return desk

    def _combo(self, items, defaults):
        # defaults puede ser un string o una lista de candidatos en orden de
        # preferencia; se elige el primero que esté instalado.
        if isinstance(defaults, str):
            defaults = [defaults]
        c = Gtk.ComboBoxText()
        for it in items:
            c.append_text(it)
        # Ancho mínimo para que el nombre no se vea cortado/"vacío".
        c.set_size_request(190, -1)
        # Popup en una sola columna (lista vertical scrollable).
        c.set_wrap_width(1)
        chosen = next((d for d in defaults if d in items), None)
        if chosen is not None:
            c.set_active(items.index(chosen))
        elif items:
            c.set_active(0)
        return c

    # -- datos ----------------------------------------------------------------

    def _wallpapers(self):
        if not os.path.isdir(WALL_DIR):
            return []
        out = []
        for ext in ("*.png", "*.jpg", "*.jpeg"):
            out += glob.glob(os.path.join(WALL_DIR, ext))
        return sorted(out)

    def _wall_thumb(self, path):
        child = Gtk.FlowBoxChild()
        child.wall_path = path
        try:
            pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 120, 68, True)
            img = Gtk.Image.new_from_pixbuf(pb)
        except Exception:
            img = Gtk.Label(label=os.path.basename(path)[:14])
        child.add(img)
        child.show_all()
        return child

    def _on_wall(self, flow, child):
        self._load_wallpaper(child.wall_path)

    def _on_browse(self, _):
        dlg = Gtk.FileChooserDialog(title="Elegir wallpaper", parent=self,
                                    action=Gtk.FileChooserAction.OPEN)
        dlg.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                        Gtk.STOCK_OPEN, Gtk.ResponseType.OK)
        flt = Gtk.FileFilter()
        flt.set_name("Imágenes")
        for p in ("*.png", "*.jpg", "*.jpeg"):
            flt.add_pattern(p)
        dlg.add_filter(flt)
        if dlg.run() == Gtk.ResponseType.OK:
            self._load_wallpaper(dlg.get_filename())
        dlg.destroy()

    def _load_wallpaper(self, path):
        self.wallpaper = path
        try:
            self._set_palette(suggest_palette(path, self.scheme))
            self.status.set_text(f"Paleta sugerida desde {os.path.basename(path)}")
        except Exception as e:
            self.status.set_text(f"Error leyendo imagen: {e}")

    def _on_scheme(self, _):
        self.scheme = "dark" if self.rb_dark.get_active() else "light"
        if self.wallpaper:
            self._load_wallpaper(self.wallpaper)

    def _on_color(self, btn, key):
        self._refresh_preview()

    def _set_palette(self, pal):
        for k in PALETTE_KEYS:
            self.color_btns[k].set_rgba(gdk_of(pal.get(k, "#202030")))
        self._refresh_preview()

    def _get_palette(self):
        return {k: rgba_hex(self.color_btns[k].get_rgba()) for k in PALETTE_KEYS}

    def _refresh_preview(self):
        self.pv_provider.load_from_data(preview_css(self._get_palette()))

    # -- guardar --------------------------------------------------------------

    def _on_save(self, _btn, apply_now):
        name = self.name_entry.get_text().strip()
        if not name:
            self.status.set_text("⚠️ Falta el nombre del tema.")
            return
        slug = slugify(name)
        pal = self._get_palette()
        rounding = int(self.spin_round.get_value())
        waybar = "floating" if self.cb_float.get_active() else "normal"
        assets = {
            "icon": self.icon_combo.get_active_text() or "Papirus-Dark",
            "gtk": self.gtk_combo.get_active_text() or "Adwaita-dark",
            "cursor": self.cursor_combo.get_active_text() or "Adwaita",
        }

        gen_counter = self.cb_counter.get_active() and self.wallpaper
        scheme2 = "light" if self.scheme == "dark" else "dark"
        slug2 = f"{slug}-{scheme2}"
        counterpart = slug2 if gen_counter else (self.counter_combo.get_active_text() or "")

        try:
            write_theme(slug, name, self.scheme, pal, assets, rounding, waybar,
                        self.wallpaper, counterpart)
            if gen_counter:
                pal2 = suggest_palette(self.wallpaper, scheme2)
                name2 = f"{name} ({'Claro' if scheme2 == 'light' else 'Oscuro'})"
                write_theme(slug2, name2, scheme2, pal2, assets, rounding, waybar,
                            self.wallpaper, slug)
        except Exception as e:
            self.status.set_text(f"⚠️ Error guardando: {e}")
            return

        if apply_now:
            subprocess.Popen(["bash", APPLY_SCRIPT, slug],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.destroy()
        else:
            self.status.set_text(f"✓ Guardado en themes/{slug}/")


if __name__ == "__main__":
    win = Creator()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()
