-- Traducción 1:1 de windowrules.conf. Solo se agrupan líneas CONSECUTIVAS con el
-- mismo match, para no alterar el orden de evaluación (gana la última coincidencia).

local function rule(match, effects)
  effects.match = match
  hl.window_rule(effects)
end

local function layer(namespace, effects)
  effects.match = { namespace = namespace }
  hl.layer_rule(effects)
end

-- APPLICATIONS BLUR
rule({ tag = "multimedia_video*" }, { no_blur = true, opacity = "1.0" })
rule({ tag = "settings*" }, { opacity = "0.8" })
rule({ class = "^(org\\.gnome\\.Nautilus)$" }, { opacity = "0.8" })
rule({ class = "^(gedit|org\\.gnome\\.TextEditor|mousepad)$" }, { opacity = "0.9" })
rule({ class = "^(org\\.pulseaudio\\.pavucontrol)$" }, { opacity = "0.9" })
rule({ class = "^(kitty)$" }, { opacity = "0.9" })
rule({ class = "^(discord|vesktop|org\\.telegram\\.desktop)$" }, { opacity = "0.85 override 0.7 override 1 override" })
rule({ class = "^(Spotify)$" }, { opacity = "0.8 override 0.6 override 1 override" })
rule({ class = "^(zen)$" }, { opacity = "0.9 override 0.7 override 1 override" })

-- Firefox
rule({ class = "^(firefox)$" }, { opacity = "0.95 override 0.90 override" })
rule({ class = "^(Navigator)$" }, { opacity = "0.95 override 0.90 override" })

-- Asistente de Voz
rule({ title = "^(Asistente de Voz)$" }, {
  float = true,
  size = "520 300",
  move = "20 760",
  opacity = "0.95 override",
  decorate = false,
  pin = true,
  animation = "slide",
})

-- 🐈 Cat Theme Toggle Widget
rule({ title = "^(Cat Theme Toggle)$" }, {
  float = true,
  size = "280 420",
  center = true,
  opacity = "0.98 override",
  decorate = false,
  animation = "slide",
})

-- Legacy: Theme card anterior
rule({ title = "^(Theme Toggle)$" }, {
  float = true,
  size = "140 180",
  center = true,
  opacity = "0.95 override",
  decorate = false,
  no_anim = true,
})

-- LAYER RULES
-- layer("rofi", { blur = true, ignore_alpha = 0.5, dim_around = true, animation = "popin" })

-- AGS/ASTAL MENUS (omenu, obsidian-hub)
layer("omenu", { blur = true, ignore_alpha = 0.15, animation = "popin" })
layer("obsidian-hub", { blur = true, ignore_alpha = 0.15, animation = "popin" })
layer("wallpaper-picker", { dim_around = true, animation = "popin" })
layer("calendar", { blur = true, ignore_alpha = 0.15, animation = "slide" })
layer("notification-center", { blur = true, ignore_alpha = 0.15, animation = "slide" })
layer("notification-popup", { animation = "slide" })
layer("audiomixer", { blur = true, ignore_alpha = 0.15, animation = "slide" })

layer("waybar", { blur = true, ignore_alpha = 0.5 })
-- AUDITORÍA: regex literal "tag:notif*", probablemente no coincide con ningún namespace
layer("tag:notif*", { ignore_alpha = 0.5 })
layer("logout_dialog", { blur = true })

-- SWAYNC BLUR & XRAY (el original intercalaba ambos namespaces; se mantiene el orden)
layer("swaync-control-center", { blur = true })
layer("swaync-notification-window", { blur = true })
layer("swaync-control-center", { ignore_alpha = 0 })
layer("swaync-notification-window", { ignore_alpha = 0 })
layer("swaync-control-center", { ignore_alpha = 0.5 })
layer("swaync-notification-window", { ignore_alpha = 0.5 })
layer("swaync-control-center", { xray = false })
layer("swaync-notification-window", { xray = false })

-- FLOAT POR TAG / APPS
rule({ tag = "settings*" }, { float = true })
rule({ tag = "viewer*" }, { float = true })
rule({ tag = "multimedia_video*" }, { float = true, size = "900 506" })
rule({ class = "^(org\\.pulseaudio\\.pavucontrol)$" }, { float = true, size = "monitor_w*0.5 monitor_h*0.6" })

-- Scratchpad terminal
rule({ class = "^(scratchpad)$" }, {
  workspace = "special:scratchpad silent",
  float = true,
  size = "monitor_w*0.8 monitor_h*0.45",
  center = true,
})

-- Quick Settings popup
rule({ title = "^(Quick Settings)$" }, { float = true, size = "340 420", move = "monitor_w-360 50" })

-- Ignorar peticiones de maximizar de las apps
rule({ class = ".*" }, { suppress_event = "maximize" })

-- Fix dragging issues XWayland (regla por defecto de Hyprland nueva)
rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

-- POP UPS AND DIALOGUES
rule({ title = "^(Save As|Save a File|Pick Files)$" }, {
  float = true,
  size = "monitor_w*0.5 monitor_h*0.6",
  center = true,
})

rule({ initial_title = "(Open Files)" }, { float = true, size = "monitor_w*0.7 monitor_h*0.6" })
