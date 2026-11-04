hl.config({
  input = {
    kb_layout = "us,latam",
    kb_variant = "",
    kb_model = "",
    kb_options = "grp:alt_shift_toggle",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
    accel_profile = "flat",
    force_no_accel = true,
    touchpad = { natural_scroll = true },
  },
  cursor = { no_hardware_cursors = true },
})

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
