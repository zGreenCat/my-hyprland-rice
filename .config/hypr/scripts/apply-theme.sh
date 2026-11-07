#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
#  🎨 apply-theme.sh — Motor central de temas estáticos
#  Uso: apply-theme.sh <nombre-carpeta-en-~/.config/hypr/themes/>
# ════════════════════════════════════════════════════════════════════════

THEMES_DIR="$HOME/.config/hypr/themes"
THEME_DIR="$THEMES_DIR/$1"
SCRIPTS="$HOME/.config/hypr/scripts"

if [ -z "$1" ] || [ ! -f "$THEME_DIR/theme.conf" ]; then
    notify-send "⚠️ apply-theme" "Tema '$1' no encontrado en $THEMES_DIR" -t 4000
    exit 1
fi

source "$THEME_DIR/theme.conf"

# ─── Validación de variables críticas ────────────────────────────────────
for var in C_BG C_ACCENT C_FG; do
    val="${!var}"
    if [[ ! "$val" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        notify-send "⚠️ apply-theme" "Tema '$1': $var inválido ('$val'). Se esperaba #RRGGBB." -t 5000
        exit 1
    fi
done

# Convierte #RRGGBB a "R G B" decimal. Falla explícito si el hex no es válido.
hex2rgb() {
    local hex="${1#\#}"
    if [[ ! "$hex" =~ ^[0-9a-fA-F]{6}$ ]]; then
        notify-send "⚠️ apply-theme" "Hex inválido para conversión RGB: '$1'" -t 5000
        exit 1
    fi
    printf "%d %d %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# ─── 1. Hyprland colors.lua ──────────────────────────────────────────────
if ! COLORS_LUA=$("$SCRIPTS/hypr-do.sh" colors-lua "$HYPR_BORDER_ACTIVE" "$HYPR_BORDER_INACTIVE" "$HYPR_SHADOW" "$HYPR_SHADOW_INACTIVE" 2>&1); then
    notify-send "⚠️ apply-theme" "Tema '$1': colores de Hyprland inválidos. $COLORS_LUA" -t 5000
    exit 1
fi
printf '%s\n' "$COLORS_LUA" > "$HOME/.config/hypr/colors.lua"

# ─── 3. Waybar colors.css ────────────────────────────────────────────────
cat > "$HOME/.config/waybar/colors.css" <<EOF
/* Theme: $THEME_NAME */
@define-color background $C_BG;
@define-color surface $C_BG;
@define-color surface_dim $C_BG;
@define-color surface_bright $C_SURFACE0;
@define-color surface_container $C_SURFACE0;
@define-color surface_container_high $C_SURFACE1;
@define-color surface_container_highest $C_SURFACE2;
@define-color surface_container_low $C_MANTLE;
@define-color surface_container_lowest $C_CRUST;
@define-color surface_tint $C_ACCENT;
@define-color surface_variant $C_SURFACE0;
@define-color on_surface $C_FG;
@define-color on_background $C_FG;
@define-color on_surface_variant $C_FG2;
@define-color primary $C_ACCENT;
@define-color primary_fixed $C_ACCENT;
@define-color primary_fixed_dim $C_ACCENT;
@define-color source_color $C_ACCENT;
@define-color primary_container $C_SURFACE0;
@define-color on_primary $C_CRUST;
@define-color on_primary_fixed $C_CRUST;
@define-color on_primary_fixed_variant $C_CRUST;
@define-color on_primary_container $C_ACCENT;
@define-color secondary $C_BLUE;
@define-color secondary_fixed $C_BLUE;
@define-color secondary_fixed_dim $C_BLUE;
@define-color secondary_container $C_SURFACE0;
@define-color on_secondary $C_CRUST;
@define-color on_secondary_fixed $C_CRUST;
@define-color on_secondary_fixed_variant $C_CRUST;
@define-color on_secondary_container $C_BLUE;
@define-color tertiary $C_PINK;
@define-color tertiary_fixed $C_PINK;
@define-color tertiary_fixed_dim $C_PINK;
@define-color tertiary_container $C_SURFACE0;
@define-color on_tertiary $C_CRUST;
@define-color on_tertiary_fixed $C_CRUST;
@define-color on_tertiary_fixed_variant $C_CRUST;
@define-color on_tertiary_container $C_PINK;
@define-color error $C_RED;
@define-color error_container $C_SURFACE0;
@define-color on_error $C_CRUST;
@define-color on_error_container $C_RED;
@define-color outline $C_OVERLAY;
@define-color outline_variant $C_SURFACE0;
@define-color inverse_surface $C_FG;
@define-color inverse_on_surface $C_BG;
@define-color inverse_primary $C_SURFACE1;
@define-color scrim #000000;
@define-color shadow #000000;
EOF

# ─── 3b. Astal (ags) colors.scss ──────────────────────────────────────────
cat > "$HOME/.config/ags/colors.scss" <<EOF
// Theme: $THEME_NAME
\$background: $C_BG;
\$surface: $C_BG;
\$surface_dim: $C_BG;
\$surface_bright: $C_SURFACE0;
\$surface_container: $C_SURFACE0;
\$surface_container_high: $C_SURFACE1;
\$surface_container_highest: $C_SURFACE2;
\$surface_container_low: $C_MANTLE;
\$surface_container_lowest: $C_CRUST;
\$surface_tint: $C_ACCENT;
\$surface_variant: $C_SURFACE0;
\$on_surface: $C_FG;
\$on_background: $C_FG;
\$on_surface_variant: $C_FG2;
\$primary: $C_ACCENT;
\$primary_fixed: $C_ACCENT;
\$primary_fixed_dim: $C_ACCENT;
\$source_color: $C_ACCENT;
\$primary_container: $C_SURFACE0;
\$on_primary: $C_CRUST;
\$on_primary_fixed: $C_CRUST;
\$on_primary_fixed_variant: $C_CRUST;
\$on_primary_container: $C_ACCENT;
\$secondary: $C_BLUE;
\$secondary_fixed: $C_BLUE;
\$secondary_fixed_dim: $C_BLUE;
\$secondary_container: $C_SURFACE0;
\$on_secondary: $C_CRUST;
\$on_secondary_fixed: $C_CRUST;
\$on_secondary_fixed_variant: $C_CRUST;
\$on_secondary_container: $C_BLUE;
\$tertiary: $C_PINK;
\$tertiary_fixed: $C_PINK;
\$tertiary_fixed_dim: $C_PINK;
\$tertiary_container: $C_SURFACE0;
\$on_tertiary: $C_CRUST;
\$on_tertiary_fixed: $C_CRUST;
\$on_tertiary_fixed_variant: $C_CRUST;
\$on_tertiary_container: $C_PINK;
\$error: $C_RED;
\$error_container: $C_SURFACE0;
\$on_error: $C_CRUST;
\$on_error_container: $C_RED;
\$outline: $C_OVERLAY;
\$outline_variant: $C_SURFACE0;
\$inverse_surface: $C_FG;
\$inverse_on_surface: $C_BG;
\$inverse_primary: $C_SURFACE1;
\$scrim: #000000;
\$shadow: #000000;
\$rounding: ${HYPR_ROUNDING:-12}px;
EOF

# ─── 4. Kitty colors.conf ────────────────────────────────────────────────
cat > "$HOME/.config/kitty/colors.conf" <<EOF
# Theme: $THEME_NAME
background            $C_BG
foreground            $C_FG
selection_foreground  $C_ACCENT
selection_background  $C_SURFACE0
cursor                $C_ACCENT
cursor_text_color     $C_BG

color0  $C_CRUST
color1  $C_RED
color2  $C_GREEN
color3  $C_YELLOW
color4  $C_BLUE
color5  $C_ACCENT
color6  $C_CYAN
color7  $C_FG2
color8  $C_SURFACE2
color9  $C_RED
color10 $C_GREEN
color11 $C_YELLOW
color12 $C_BLUE
color13 $C_ACCENT
color14 $C_CYAN
color15 $C_FG
EOF

# ─── 5. Rofi colors.rasi ─────────────────────────────────────────────────
cat > "$HOME/.config/rofi/colors.rasi" <<EOF
/* Theme: $THEME_NAME */
* {
    primary:              $C_ACCENT;
    secondary:            $C_BLUE;
    background:           $C_CRUST;
    foreground:           $C_FG;
    surface:              $C_BG;

    primary-container:    $C_SURFACE0;
    on-primary-container: $C_FG;
    on-primary:           $C_SURFACE0;
    on-primary-fixed:     $C_CRUST;
    on-surface:           $C_FG;
    secondary-container:  $C_OVERLAY;
    on-secondary:         $C_FG2;
    error:                $C_RED;

    rofi-radius:          ${HYPR_ROUNDING:-12}px;
}
EOF

# ─── 6. GTK ──────────────────────────────────────────────────────────────
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null
gsettings set org.gnome.desktop.interface color-scheme "prefer-$COLOR_SCHEME" 2>/dev/null

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

for cfg in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    if grep -q "gtk-theme-name" "$cfg" 2>/dev/null; then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$cfg"
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$cfg"
    else
        printf '[Settings]\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\n' \
            "$GTK_THEME" "$ICON_THEME" > "$cfg"
    fi
done

if [ -d "/usr/share/themes/$GTK_THEME/gtk-4.0" ]; then
    printf '@import "/usr/share/themes/%s/gtk-4.0/gtk.css";\n' "$GTK_THEME" \
        > "$HOME/.config/gtk-4.0/gtk.css"
fi

XSETTINGS_CONF="$HOME/.config/xsettingsd/xsettingsd.conf"
if [ -f "$XSETTINGS_CONF" ]; then
    sed -i "s|^Net/ThemeName.*|Net/ThemeName \"$GTK_THEME\"|" "$XSETTINGS_CONF"
    sed -i "s|^Net/IconThemeName.*|Net/IconThemeName \"$ICON_THEME\"|" "$XSETTINGS_CONF"
    pkill -HUP xsettingsd 2>/dev/null
fi

# ─── 6b. Cursor ───────────────────────────────────────────────────────────
if [ -n "$CURSOR_THEME" ]; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null
    hyprctl setcursor "$CURSOR_THEME" 24 2>/dev/null
    for cfg in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        if grep -q "gtk-cursor-theme-name" "$cfg" 2>/dev/null; then
            sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$CURSOR_THEME/" "$cfg"
        else
            echo "gtk-cursor-theme-name=$CURSOR_THEME" >> "$cfg"
        fi
    done
fi

# ─── 6c. Wlogout style.css ───────────────────────────────────────────────
read -r BG_R BG_G BG_B <<< "$(hex2rgb "$C_BG")"
read -r SURF_R SURF_G SURF_B <<< "$(hex2rgb "$C_SURFACE0")"
read -r ACC_R ACC_G ACC_B <<< "$(hex2rgb "$C_ACCENT")"

cat > "$HOME/.config/wlogout/style.css" <<EOF
* {
    background-image: none;
    font-size: 16px;
    font-family: "JetBrains Mono NFM";
}

window {
    background-color: rgba(0, 0, 0, 0);
}

button {
    border-radius: ${HYPR_ROUNDING:-12}px;
    margin: 25px;
    padding: 60px 40px 30px 40px;
    color: $C_FG;
    border: 3px solid $C_ACCENT;
    background-color: rgba(${SURF_R}, ${SURF_G}, ${SURF_B}, 0.80);
    background-repeat: no-repeat;
    background-position: center 25%;
    background-size: 40%;
    min-width: 200px;
    min-height: 200px;
}

button:hover {
    background-color: rgba(${ACC_R}, ${ACC_G}, ${ACC_B}, 0.90);
    border-color: $C_LAVENDER;
    background-position: center 22%;
    background-size: 45%;
    color: $C_BG;
}

#lock {
    background-image: url("$HOME/.config/wlogout/icons/lock.png");
}

#logout {
    background-image: url("$HOME/.config/wlogout/icons/logout.png");
}

#suspend {
    background-image: url("$HOME/.config/wlogout/icons/sleep.png");
}

#hibernate {
    background-image: url("$HOME/.config/wlogout/icons/hibernate.png");
}

#shutdown {
    background-image: url("$HOME/.config/wlogout/icons/power.png");
}

#reboot {
    background-image: url("$HOME/.config/wlogout/icons/restart.png");
}
EOF

# ─── 7. Hyprland live update ─────────────────────────────────────────────
hyprctl reload 2>/dev/null
HEADLESS_OUTPUT=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' | head -n 1)
if [ -n "$HEADLESS_OUTPUT" ]; then
    sleep 0.2
    if ! err=$("$SCRIPTS/hypr-do.sh" monitor "$HEADLESS_OUTPUT" 1920x1080@60 auto 1 2>&1); then
        notify-send "⚠️ apply-theme" "$err" -t 5000
    fi
fi
if ! err=$("$SCRIPTS/hypr-do.sh" set-colors "$HYPR_BORDER_ACTIVE" "$HYPR_BORDER_INACTIVE" "$HYPR_SHADOW" "$HYPR_SHADOW_INACTIVE" "${HYPR_ROUNDING:-12}" 2>&1); then
    notify-send "⚠️ apply-theme" "$err" -t 5000
fi

# ─── 8. Wallpaper ────────────────────────────────────────────────────────
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    if ! pgrep -x awww-daemon > /dev/null; then
        awww-daemon &
        sleep 0.5
    fi
    awww img "$WALLPAPER" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-fps 60 \
        --transition-duration 1.2 \
        --transition-bezier 0.25,0.1,0.25,1.0 &
fi

# ─── 9. Hyprlock ─────────────────────────────────────────────────────────
ROUNDING_PX="${HYPR_ROUNDING:-12}"
ACCENT_HEX="${C_ACCENT#\#}"
BG_HEX="${C_BG#\#}"
FG_HEX="${C_FG#\#}"
SURFACE_HEX="${C_SURFACE0#\#}"

cat > "$HOME/.config/hypr/hyprlock-colors.conf" <<EOF
\$lock_accent     = rgba(${ACCENT_HEX}ff)
\$lock_accent_dim = rgba(${ACCENT_HEX}66)
\$lock_bg         = rgba(${BG_HEX}bb)
\$lock_fg         = rgba(${FG_HEX}ff)
\$lock_fg_dim     = rgba(${FG_HEX}aa)
\$lock_surface    = rgba(${SURFACE_HEX}99)
\$lock_rounding   = $ROUNDING_PX
EOF

[ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ] && \
    ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper" 2>/dev/null

# ─── 10. Recargar servicios ──────────────────────────────────────────────
ACTIVE_LAYOUT_FILE="$HOME/.config/hypr/.active-waybar-layout"
CURRENT_LAYOUT=$(cat "$ACTIVE_LAYOUT_FILE" 2>/dev/null || echo "")

if [ -n "$WAYBAR_LAYOUT" ] && [ "$WAYBAR_LAYOUT" != "$CURRENT_LAYOUT" ]; then
    case "$WAYBAR_LAYOUT" in
        floating)
            cp "$HOME/.config/waybar/configs/bintang default" "$HOME/.config/waybar/config"
            ln -sf "$HOME/.config/waybar/style/islands no transparent.css" "$HOME/.config/waybar/style.css"
            ;;
        fullwidth)
            cp "$HOME/.config/waybar/configs/fullwidth" "$HOME/.config/waybar/config"
            ln -sf "$HOME/.config/waybar/style/full bar.css" "$HOME/.config/waybar/style.css"
            ;;
        mpris)
            cp "$HOME/.config/waybar/configs/mpris middle" "$HOME/.config/waybar/config"
            ln -sf "$HOME/.config/waybar/style/islands no transparent.css" "$HOME/.config/waybar/style.css"
            ;;
        window)
            cp "$HOME/.config/waybar/configs/window middle" "$HOME/.config/waybar/config"
            ln -sf "$HOME/.config/waybar/style/islands no transparent.css" "$HOME/.config/waybar/style.css"
            ;;
    esac
    echo "$WAYBAR_LAYOUT" > "$ACTIVE_LAYOUT_FILE"
    pkill waybar 2>/dev/null
    sleep 0.4
    GDK_BACKEND=wayland waybar &
else
    pkill -SIGUSR2 waybar 2>/dev/null
fi
kill -SIGUSR1 $(pidof kitty) 2>/dev/null
ags quit 2>/dev/null; (ags run &>/dev/null &) 2>/dev/null; disown 2>/dev/null

# ─── 10b. Spicetify (Spotify) ─────────────────────────────────────────────
if command -v spicetify &>/dev/null; then
    mkdir -p "$HOME/.config/spicetify/Themes/text"
    cat > "$HOME/.config/spicetify/Themes/text/color.ini" <<EOF
[Spicetify]
main               = ${C_BG#\#}
accent             = ${C_ACCENT#\#}
accent-active      = ${C_ACCENT#\#}
accent-inactive    = ${C_SURFACE0#\#}
banner             = ${C_ACCENT#\#}
border-active      = ${C_ACCENT#\#}
border-inactive    = ${C_OVERLAY#\#}
header             = ${C_FG#\#}
highlight          = ${C_SURFACE0#\#}
notification       = ${C_ACCENT#\#}
notification-error = ${C_RED#\#}
subtext            = ${C_FG2#\#}
text               = ${C_FG#\#}
EOF
    if pgrep -x spotify &>/dev/null; then
        touch "$HOME/.config/spicetify/.pending-apply"
    else
        (spicetify apply &>/dev/null &) 2>/dev/null; disown 2>/dev/null
    fi
fi

# ─── 11. Estado y notificación ───────────────────────────────────────────
echo "$1" > "$HOME/.config/hypr/.active-theme"
notify-send "🎨 Tema aplicado" "$THEME_NAME" -t 2500

wait
