-- ###################
-- ### KEYBINDINGS ###
-- ###################

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "nautilus"
local menu = "rofi -show drun"
local scripts = "~/.config/hypr/scripts/"

-- Descripciones que muestra keybindings-view.py (se asignan al primer bind de cada combinación).
local descriptions = {
  ["SUPER + RETURN"]          = "Terminal",
  ["SUPER + SHIFT + RETURN"]  = "Terminal",
  ["SUPER + Q"]               = "Cerrar ventana",
  ["CTRL + ALT + DELETE"]     = "exit Hyprland",
  ["SUPER + E"]               = "File manager",
  ["SUPER + SPACE"]           = "Toggle flotante",
  ["SUPER + C"]               = "Buscador de apps",
  ["SUPER + TAB"]             = "Menú con submenus (piloto AGS/Astal)",
  ["SUPER + P"]               = "Project launcher",
  ["SUPER + ALT + P"]         = "Pseudo tile",
  ["SUPER + J"]               = "Alternar división",
  ["SUPER + R"]               = "Reiniciar Waybar",
  ["SUPER + B"]               = "default browser",
  ["SUPER + L"]               = "Lock screen",
  ["SUPER + X"]               = "Power menu",
  ["SUPER + F"]               = "Fullscreen sin Shift",
  ["SUPER + T"]               = "Selector de wallpapers/temas (piloto AGS/Astal)",
  ["SUPER + SHIFT + Q"]       = "Kill active process",
  ["SUPER + SHIFT + C"]       = "Selector de color",
  ["SUPER + CTRL + B"]        = "Waybar Styles Menu",
  ["SUPER + ALT + B"]         = "Waybar Layout Menu",
  ["SUPER + H"]               = "Hide Waybar",
  ["SUPER + SHIFT + E"]       = "Yazi File Manager",
  ["SUPER + SHIFT + M"]       = "Meeting mode",
  ["SUPER + ALT + M"]         = "YouTube Music TUI",
  ["SUPER + M"]               = "Spotify TUI (estilo de la foto)",
  ["ALT + Z"]                 = "Asistente de voz (grabar/parar)",
  ["SUPER + SHIFT + V"]       = "Audio visualizer",
  ["SUPER + SHIFT + B"]       = "System monitor",
  ["SUPER + SHIFT + T"]       = "Big clock",
  ["PRINT"]                   = "Screenshot",
  ["SUPER + PRINT"]           = "Screenshot",
  ["SUPER + SHIFT + S"]       = "Screenshot + editar",
  ["SUPER + CTRL + PRINT"]    = "Screenshot + editar",
  ["SUPER + LEFT"]            = "Mover foco ←",
  ["SUPER + RIGHT"]           = "Mover foco →",
  ["SUPER + UP"]              = "Mover foco ↑",
  ["SUPER + DOWN"]            = "Mover foco ↓",
  ["SUPER + CTRL + LEFT"]     = "Mover ventana ←",
  ["SUPER + CTRL + RIGHT"]    = "Mover ventana →",
  ["SUPER + CTRL + UP"]       = "Mover ventana ↑",
  ["SUPER + CTRL + DOWN"]     = "Mover ventana ↓",
  ["SUPER + SHIFT + LEFT"]    = "Redimensionar ventana",
  ["SUPER + SHIFT + RIGHT"]   = "Redimensionar ventana",
  ["SUPER + SHIFT + UP"]      = "Redimensionar ventana",
  ["SUPER + SHIFT + DOWN"]    = "Redimensionar ventana",
  ["SUPER + GRAVE"]           = "scratchpad",
  ["SUPER + V"]               = "ags toggle clipboard",
  ["SUPER + S"]               = "ags toggle notification-center",
  ["SUPER + N"]               = "quick-note",
  ["SUPER + SHIFT + P"]       = "pentest-cheatsheet",
  ["SUPER + O"]               = "ags toggle obsidian",
  ["SUPER + SHIFT + H"]       = "Monitor izquierdo",
  ["SUPER + SHIFT + L"]       = "Monitor derecho",
}

local described = {}

local function bind(keys, action, flags)
  local combo = keys:upper()
  local description = descriptions[combo]
  if description and not described[combo] then
    described[combo] = true
    local withDescription = { description = description }
    for k, v in pairs(flags or {}) do
      withDescription[k] = v
    end
    flags = withDescription
  end
  hl.bind(keys, action, flags)
end

local function exec(keys, cmd, rules)
  bind(keys, hl.dsp.exec_cmd(cmd, rules))
end

local M = mainMod .. " + "

exec(M .. "Return", terminal)
exec(M .. "SHIFT + RETURN", terminal, { float = true, size = { 800, 550 } })
bind(M .. "Q", hl.dsp.window.close())
bind("CTRL + ALT + Delete", hl.dsp.exit())
exec(M .. "E", fileManager)
bind(M .. "Space", hl.dsp.window.float({ action = "toggle" }))
exec(M .. "C", menu)
exec(M .. "TAB", "ags toggle omenu")
bind(M .. "ALT + P", hl.dsp.window.pseudo())
bind(M .. "J", hl.dsp.layout("togglesplit"))
exec(M .. "R", scripts .. "wbrestart.sh")
exec(M .. "B", 'xdg-open "https://"')
exec(M .. "L", "hyprlock")
exec(M .. "X", "wlogout")
bind(M .. "F", hl.dsp.window.fullscreen())
exec(M .. "T", "ags toggle wallpaper-picker")
exec(M .. "SHIFT + Q", scripts .. "KillActiveProcess.sh")
exec(M .. "SHIFT + C", "hyprpicker -a")
exec(M .. "CTRL + B", scripts .. "WaybarStyles.sh")
exec(M .. "ALT + B", scripts .. "WaybarLayout.sh")
exec(M .. "H", "pkill -SIGUSR1 waybar")
exec(M .. "SHIFT + E", "kitty yazi")
exec(M .. "ALT + M", "kitty yt")
exec(M .. "M", "kitty spt")

-- Asistente de voz (Alt+Z x2: inicia/para grabación → Claude Code → TTS)
exec("ALT + Z", "python3 " .. scripts .. "voice-assistant.py")

-- Widgets - Visualizadores
exec(M .. "SHIFT + V", 'kitty --title "Cava Audio Visualizer" cava', { float = true, size = { 800, 400 } })
exec(M .. "SHIFT + B", 'kitty --title "Btop System Monitor" btop', { float = true, size = { 1200, 800 } })
exec(M .. "SHIFT + T", 'kitty --title "TTY Clock" tty-clock -c -C 5 -B', { float = true, size = { 600, 300 } })

-- Screenshots
exec("Print", 'grim -g "$(slurp)" - | wl-copy')
exec(M .. "Print", "grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png")
exec(M .. "SHIFT + S", 'grim -g "$(slurp)" - | swappy -f -')
exec(M .. "CTRL + Print", "sleep 3 && grim - | swappy -f -")

-- Mover foco / mover ventanas / redimensionar
local directions = { "left", "right", "up", "down" }
for _, dir in ipairs(directions) do
  bind(M .. dir, hl.dsp.focus({ direction = dir }))
end
for _, dir in ipairs(directions) do
  bind(M .. "CTRL + " .. dir, hl.dsp.window.move({ direction = dir }))
end
local resize = { left = { -50, 0 }, right = { 50, 0 }, up = { 0, -50 }, down = { 0, 50 } }
for _, dir in ipairs(directions) do
  local d = resize[dir]
  bind(M .. "SHIFT + " .. dir, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- Workspaces 1-10 (tecla 0 = workspace 10)
for ws = 1, 10 do
  bind(M .. (ws % 10), hl.dsp.focus({ workspace = ws }))
end
for ws = 1, 10 do
  bind(M .. "SHIFT + " .. (ws % 10), hl.dsp.window.move({ workspace = ws, follow = false }))
end

-- Scratchpad terminal (Super + grave)
exec(M .. "grave", scripts .. "scratchpad.sh")

-- Clipboard manager (Super + V)
exec(M .. "V", "ags toggle clipboard")

-- Notification center and quick settings (Super + S)
exec(M .. "S", "ags toggle notification-center")

-- Project launcher (Super + P)
exec(M .. "P", scripts .. "project-launcher.sh")

-- Quick note to Obsidian Inbox (Super + N)
exec(M .. "N", scripts .. "quick-note.sh")

-- Pentest cheat sheet (Super + Shift + P)
exec(M .. "SHIFT + P", scripts .. "pentest-cheatsheet.sh")

-- Obsidian hub (Super + O)
exec(M .. "O", "ags toggle obsidian")

-- Scroll por workspaces existentes
bind(M .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(M .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mover/redimensionar con LMB/RMB
bind(M .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(M .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ════════════════════════════════════════════════════════════════════════
--  🔊 AUDIO & BRILLO
-- ════════════════════════════════════════════════════════════════════════
local repeatLocked = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "volume.sh --inc"), repeatLocked)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "volume.sh --dec"), repeatLocked)
bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "volume.sh --toggle"), repeatLocked)
bind("XF86AudioMicMute", hl.dsp.exec_cmd(scripts .. "volume.sh --toggle-mic"), repeatLocked)
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "brightness.sh --inc"), repeatLocked)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "brightness.sh --dec"), repeatLocked)

local locked = { locked = true }
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)

-- ════════════════════════════════════════════════════════════════════════
--  🖥️ MULTI-MONITOR
-- ════════════════════════════════════════════════════════════════════════
local function multiMonitor()
  bind(M .. "SHIFT + H", hl.dsp.window.move({ monitor = "l" }))
  bind(M .. "SHIFT + L", hl.dsp.window.move({ monitor = "r" }))
  bind(M .. "CTRL + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))
  bind(M .. "CTRL + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
  bind(M .. "ALT + left", hl.dsp.focus({ monitor = "l" }))
  bind(M .. "ALT + right", hl.dsp.focus({ monitor = "r" }))
end

multiMonitor()

-- ════════════════════════════════════════════════════════════════════════
--  📦 WORKSPACE - Mover ventana y seguirla (Super + Ctrl + N)
-- ════════════════════════════════════════════════════════════════════════
for ws = 1, 9 do
  bind(M .. "CTRL + " .. ws, hl.dsp.window.move({ workspace = ws, follow = true }))
end

-- Meeting mode: toggle workspace 8 en monitor headless para compartir pantalla
exec(M .. "SHIFT + M", scripts .. "meeting-mode.sh")
