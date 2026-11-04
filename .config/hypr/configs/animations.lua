-- ════════════════════════════════════════════════════════════════════════
--  ✨ Animations - Space Theme (Suaves y flotantes como en el espacio)
-- ════════════════════════════════════════════════════════════════════════

hl.config({ animations = { enabled = true } })

local function bezier(name, x1, y1, x2, y2)
  hl.curve(name, { type = "bezier", points = { { x1, y1 }, { x2, y2 } } })
end

bezier("space", 0.05, 0.9, 0.1, 1.02)
bezier("spaceIn", 0.16, 1, 0.3, 1)
bezier("spaceOut", 0.7, 0, 0.84, 0)
bezier("fade", 0.25, 0.1, 0.25, 1)
bezier("linear", 0, 0, 1, 1)
bezier("float", 0.4, 0, 0.2, 1)
bezier("cosmic", 0.68, -0.55, 0.265, 1.55)

local function anim(leaf, speed, curve, style)
  hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = curve, style = style })
end

anim("windowsIn", 6, "spaceIn", "popin 90%")
anim("windowsOut", 5, "spaceOut", "popin 90%")
anim("windowsMove", 5, "space", "slide")

anim("fadeIn", 6, "fade")
anim("fadeOut", 5, "fade")
anim("fade", 6, "fade")
anim("fadeDim", 6, "fade")
anim("fadeSwitch", 5, "fade")
anim("fadeShadow", 5, "fade")
anim("fadeLayersIn", 5, "fade")
anim("fadeLayersOut", 5, "fade")

anim("border", 4, "linear")
anim("borderangle", 100, "linear", "loop")

anim("workspaces", 7, "space", "slide")
anim("specialWorkspace", 6, "cosmic", "slidevert")
