local colors = require("colors")

hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 16,
    border_size = 3,
    col = {
      active_border = colors.active_border,
      inactive_border = colors.inactive_border,
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 12,
    dim_around = 0.15,
    fullscreen_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      offset = "0 2",
      color = colors.shadow,
      color_inactive = colors.shadow_inactive,
    },
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      ignore_opacity = false,
      new_optimizations = true,
      xray = true,
      contrast = 1.1,
      brightness = 1.0,
      vibrancy = 0.2,
      vibrancy_darkness = 0.3,
    },
    dim_inactive = true,
    dim_strength = 0.05,
  },
  dwindle = { preserve_split = true },
})
