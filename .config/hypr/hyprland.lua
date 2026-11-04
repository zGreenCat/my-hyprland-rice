-- ════════════════════════════════════════════════════════════════════════
--  🌌 SPACE HYPRLAND RICE - Main Configuration
--  Temática espacial con colores dinámicos
-- ════════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────────────
--  🖥️ MONITORS
-- ────────────────────────────────────────────────────────────────────────
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@74.97", position = "1920x0", scale = 1 })

-- ────────────────────────────────────────────────────────────────────────
--  🚀 AUTOSTART
-- ────────────────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("GDK_BACKEND=wayland waybar")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("blueman-applet")
  -- hl.exec_cmd("GDK_BACKEND=wayland swaync")  -- reemplazado por AGS/AstalNotifd (piloto)
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("ags run")
  -- hl.exec_cmd("swayosd-server")
  hl.exec_cmd("batsignal -w 30 -c 15 -d 8")
  -- Restaurar el wallpaper del tema activo (los colores ya persisten en disco)
  hl.exec_cmd("~/.config/hypr/scripts/restore-wallpaper.sh")
  hl.exec_cmd("xsettingsd")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- ────────────────────────────────────────────────────────────────────────
--  🌍 ENVIRONMENT VARIABLES
-- ────────────────────────────────────────────────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
-- ⚠️ Nvidia GPU detected - Variables críticas
hl.env("LIBVA_DRIVER_NAME", "iHD")
-- hl.env("GBM_BACKEND", "nvidia-drm")  -- compositor corre en Intel (eDP-1); forzar GBM nvidia rompe modifiers
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/by-path/pci-0000:00:02.0-card,/dev/dri/by-path/pci-0000:01:00.0-card")
-- hl.env("NVD_BACKEND", "direct")  -- solo aplica con LIBVA_DRIVER_NAME=nvidia
hl.env("AQ_FORCE_LINEAR_BLIT", "0")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("AQ_NO_HARDWARE_CURSORS", "1")
-- 🦊 Forzar Wayland en Firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- ────────────────────────────────────────────────────────────────────────
--  Módulos (mismo orden que los source de hyprland.conf)
-- ────────────────────────────────────────────────────────────────────────
require("configs.tags")
require("configs.looknfeel")
require("configs.animations")
require("configs.windowrules")
require("configs.input")
require("configs.keybinds")

-- ────────────────────────────────────────────────────────────────────────
--  📐 LAYOUTS / 🔧 MISC
-- ────────────────────────────────────────────────────────────────────────
hl.config({
  dwindle = { preserve_split = true },
  master = { new_status = "master", new_on_top = false },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    vrr = 0,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
  },
  render = { new_render_scheduling = true },
})
