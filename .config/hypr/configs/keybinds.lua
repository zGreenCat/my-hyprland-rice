-- ###################
-- ### KEYBINDINGS ###
-- ###################
-- Traducción 1:1 de keybinds.conf. Los binds duplicados del original se conservan
-- (marcados con AUDITORÍA) para no cambiar comportamiento; se resuelven después.

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "nautilus"
local menu = "rofi -show drun"
local scripts = "~/.config/hypr/scripts/"

local function exec(keys, cmd, rules)
  hl.bind(keys, hl.dsp.exec_cmd(cmd, rules))
end

local M = mainMod .. " + "

exec(M .. "Return", terminal)
exec(M .. "SHIFT + RETURN", terminal, { float = true, size = { 800, 550 } })
hl.bind(M .. "Q", hl.dsp.window.close())
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
exec(M .. "E", fileManager)
hl.bind(M .. "Space", hl.dsp.window.float({ action = "toggle" }))
exec(M .. "C", menu)
exec(M .. "TAB", "ags toggle omenu")
hl.bind(M .. "P", hl.dsp.window.pseudo()) -- AUDITORÍA: SUPER+P también abre project-launcher (más abajo)
hl.bind(M .. "J", hl.dsp.layout("togglesplit"))
exec(M .. "R", scripts .. "wbrestart.sh")
exec(M .. "B", 'xdg-open "https://"')
exec(M .. "L", "hyprlock")
exec(M .. "X", "wlogout")
hl.bind(M .. "F", hl.dsp.window.fullscreen())
exec(M .. "T", "ags toggle wallpaper-picker")
exec(M .. "SHIFT + Q", scripts .. "KillActiveProcess.sh")
exec(M .. "SHIFT + C", "hyprpicker -a")
exec(M .. "CTRL + B", scripts .. "WaybarStyles.sh")
exec(M .. "ALT + B", scripts .. "WaybarLayout.sh")
exec(M .. "H", "pkill -SIGUSR1 waybar")
exec(M .. "SHIFT + E", "kitty yazi")
exec(M .. "SHIFT + M", "kitty yt") -- AUDITORÍA: SUPER+SHIFT+M también activa meeting-mode (al final)
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
  hl.bind(M .. dir, hl.dsp.focus({ direction = dir }))
end
for _, dir in ipairs(directions) do
  hl.bind(M .. "CTRL + " .. dir, hl.dsp.window.move({ direction = dir }))
end
local resize = { left = { -50, 0 }, right = { 50, 0 }, up = { 0, -50 }, down = { 0, 50 } }
for _, dir in ipairs(directions) do
  local d = resize[dir]
  hl.bind(M .. "SHIFT + " .. dir, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- Workspaces 1-10 (tecla 0 = workspace 10)
for ws = 1, 10 do
  hl.bind(M .. (ws % 10), hl.dsp.focus({ workspace = ws }))
end
for ws = 1, 10 do
  hl.bind(M .. "SHIFT + " .. (ws % 10), hl.dsp.window.move({ workspace = ws, follow = true }))
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
hl.bind(M .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mover/redimensionar con LMB/RMB
hl.bind(M .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(M .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ════════════════════════════════════════════════════════════════════════
--  🔊 AUDIO & BRILLO
-- ════════════════════════════════════════════════════════════════════════
local repeatLocked = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "volume.sh --inc"), repeatLocked)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "volume.sh --dec"), repeatLocked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "volume.sh --toggle"), repeatLocked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scripts .. "volume.sh --toggle-mic"), repeatLocked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "brightness.sh --inc"), repeatLocked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "brightness.sh --dec"), repeatLocked)

local locked = { locked = true }
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)

-- ════════════════════════════════════════════════════════════════════════
--  🖥️ MULTI-MONITOR
-- ════════════════════════════════════════════════════════════════════════
local function multiMonitor()
  hl.bind(M .. "SHIFT + H", hl.dsp.window.move({ monitor = "l" }))
  hl.bind(M .. "SHIFT + L", hl.dsp.window.move({ monitor = "r" }))
  hl.bind(M .. "CTRL + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))
  hl.bind(M .. "CTRL + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
  hl.bind(M .. "ALT + left", hl.dsp.focus({ monitor = "l" }))
  hl.bind(M .. "ALT + right", hl.dsp.focus({ monitor = "r" }))
end

multiMonitor()

-- Mover ventana Y cambiar al workspace en el otro monitor
for ws = 1, 5 do
  hl.bind(M .. "ALT + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws, follow = true }))
end

-- AUDITORÍA: bloque multi-monitor repetido en el original (cada bind queda registrado 2 veces)
multiMonitor()

-- ════════════════════════════════════════════════════════════════════════
--  📦 WORKSPACE - Mover ventana y seguirla (Super + Ctrl + N)
-- ════════════════════════════════════════════════════════════════════════
-- AUDITORÍA: el original registra movetoworkspace + workspace por tecla, y repite 1-5
-- en un segundo bloque (SUPER+CTRL+1..5 quedan con 4 binds). Se conserva tal cual.
local function moveAndFollow(ws)
  hl.bind(M .. "CTRL + " .. ws, hl.dsp.window.move({ workspace = ws, follow = true }))
  hl.bind(M .. "CTRL + " .. ws, hl.dsp.focus({ workspace = ws }))
end

for ws = 1, 9 do
  moveAndFollow(ws)
end
for ws = 1, 5 do
  moveAndFollow(ws)
end

-- Meeting mode: toggle workspace 8 en monitor headless para compartir pantalla
exec(M .. "SHIFT + M", scripts .. "meeting-mode.sh")
