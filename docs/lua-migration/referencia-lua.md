# Referencia de traduccion hyprlang (.conf) a Lua para Hyprland 0.56.2 y 0.57.x

Leyenda de verificacion:
- [V56+V57] = validado con `Hyprland --verify-config -c <archivo>` en 0.56.2 (binario instalado) Y en 0.57.1 (binario del paquete en cache de pacman, ejecutado con libs aquamarine 0.16 / hyprgraphics 0.6 / hyprutils 0.14.3 extraidas en el scratchpad). OJO: verify-config solo valida sintaxis, nombres de claves/flags/efectos y tipos. NO valida semantica en runtime (por ejemplo que "70% 60%" se interprete como porcentaje).
- [V56+V57+DOC] = lo anterior mas confirmado en la wiki oficial.
- [DOC] = solo wiki oficial / notas de release / strings del binario. [NO VERIFICADO] = no se pudo confirmar.

Arbol de prueba completo y validado (ambas versiones, "config ok"):
`/tmp/claude-1000/-home-zgreencat/eca117a0-df17-42f2-9242-7549ae1494d4/scratchpad/luatest/full/` (hyprland.lua + colors.lua + configs/{monitors,looknfeel,input,animations,tags,windowrules,keybinds,base}.lua).
Script de validacion: `/tmp/claude-1000/-home-zgreencat/eca117a0-df17-42f2-9242-7549ae1494d4/scratchpad/v.sh <archivo.lua>` (corre ambas versiones). Stubs oficiales 0.56.2: `/usr/share/hypr/stubs/hl.meta.lua`; 0.57.1: `.../scratchpad/h057full/usr/share/hypr/stubs/hl.meta.lua`.

## 0. Construcciones que usa el usuario (inventario)

hyprland.conf: `source`, `monitor`, variables `$var`, `exec-once` (14, algunas con prefijo `VAR=valor cmd`), `env` (con coma), bloques `dwindle{}`, `master{}`, `misc{}`, `render{}`.
colors.conf: solo variables `$col_active_border` (gradiente de 3 colores + `45deg`), `$col_inactive_border`, `$shadow_color`, `$shadow_inactive`; lo REESCRIBE `scripts/apply-theme.sh` y la plantilla matugen (`~/.config/matugen/config.toml` con post_hook `hyprctl reload`).
input.conf: bloque `input{}` con subbloque `touchpad{}`, bloque `cursor{}`, `device{}` por dispositivo.
looknfeel.conf: `general{}`, `decoration{}` con subbloques `shadow{}` y `blur{}`, usando variables `$col_*`; `col.active_border` (gradiente), `offset = 0 2`.
UserAnimations.conf: `animations{}`, `bezier =`, `animation =` (con estilos `popin 90%`, `slide`, `slidevert`, `loop`).
tags.conf: `windowrule = tag +x, match:class ...` y `workspace = N, monitor:X`.
windowrules.conf: `windowrule = <efecto> <valor>, match:<prop> <regex>` (efectos: opacity con `override`, float, size (px y %), move (px y `100%-360`), center, pin, decorate, no_blur, no_anim, animation, workspace `special:x silent`, suppress_event, no_focus), multiples `match:` en una regla, `match:tag foo*`, `match:initial_title`, `match:xwayland/float/fullscreen/pin`; `layerrule = <efecto> <valor>, match:namespace X` (blur, ignore_alpha, animation, dim_around, xray).
keybinds.conf: `bind`, `binde`, `bindel`, `bindl`, `bindm`; modificadores multiples (`$mainMod CTRL SHIFT`); tecla vacia (`, Print`, `, XF86...`); `mouse:272`; `exec` con prefijo de reglas `[float; size 800 550]`; dispatchers exec, killactive, togglefloating, pseudo, layoutmsg, fullscreen, movefocus, movewindow (dir y `mon:l`), resizeactive, workspace (n, `e+1`), movetoworkspace, movecurrentworkspacetomonitor, focusmonitor.
NO usa: submaps, bindr, bindt, gestures, `permission`, `windowrulev2`, plugins, `source` de glob.

## 1. Tabla de traduccion

| hyprlang (ejemplo real del usuario) | Lua | Estado |
|---|---|---|
| `source = ~/.config/hypr/configs/keybinds.conf` | `require("configs.keybinds")` (ruta relativa al directorio de hyprland.lua; `.` o `/` como separador). Ver seccion 2 | [V56+V57] |
| `$terminal = kitty` / `$mainMod = SUPER` | `local terminal = "kitty"` / `local mainMod = "SUPER"` (variables locales Lua; para compartir entre archivos, `return` una tabla desde un modulo) | [V56+V57+DOC] |
| `monitor = eDP-1, 1920x1080@144, 0x0, 1` | `hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })` | [V56+V57+DOC] |
| `monitor = HDMI-A-1, 1920x1080@74.97, 1920x0, 1` | `hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@74.97", position = "1920x0", scale = 1 })` | [V56+V57+DOC] |
| `exec-once = nm-applet` (y todos los exec-once) | `hl.on("hyprland.start", function() hl.exec_cmd("nm-applet") ... end)` (un solo handler con todas las llamadas). Evento solo al inicio, no en reload, igual que exec-once | [V56+V57+DOC] |
| `exec-once = GDK_BACKEND=wayland waybar` | `hl.exec_cmd("GDK_BACKEND=wayland waybar")` (exec_cmd usa `sh -c`, el prefijo VAR=valor y `~` y `&&` funcionan) | [V56+V57] sintaxis; shell por [DOC] |
| `exec-once = wl-paste --type text --watch cliphist store` | `hl.exec_cmd("wl-paste --type text --watch cliphist store")` | [V56+V57] |
| `env = XCURSOR_SIZE,24` | `hl.env("XCURSOR_SIZE", "24")` (valor SIEMPRE string) | [V56+V57+DOC] |
| `env = AQ_FORCE_LINEAR_BLIT, 0` | `hl.env("AQ_FORCE_LINEAR_BLIT", "0")` (sin espacios sobrantes) | [V56+V57+DOC] |
| `misc { vrr = 0 ... }` | `hl.config({ misc = { vrr = 0, force_default_wallpaper = 0, disable_hyprland_logo = true, mouse_move_enables_dpms = true, key_press_enables_dpms = true } })` | [V56+V57] |
| `render { new_render_scheduling = true }` | `hl.config({ render = { new_render_scheduling = true } })` | [V56+V57] |
| `dwindle { preserve_split = true }` / `master { new_status = master }` | `hl.config({ dwindle = { preserve_split = true }, master = { new_status = "master", new_on_top = false } })` (strings entre comillas) | [V56+V57+DOC] |
| `general { gaps_in = 8 gaps_out = 16 border_size = 3 resize_on_border = true allow_tearing = false layout = dwindle }` | `hl.config({ general = { gaps_in = 8, gaps_out = 16, border_size = 3, resize_on_border = true, allow_tearing = false, layout = "dwindle" } })` | [V56+V57] |
| `col.active_border = $col_active_border` con `rgb(e8002a) rgb(8b0000) rgb(3f0010) 45deg` | `col = { active_border = { colors = {"rgb(e8002a)","rgb(8b0000)","rgb(3f0010)"}, angle = 45 }, inactive_border = "rgb(080204)" }` dentro de `general`. La forma string `"rgb(..) rgb(..) 45deg"` FALLA ("invalid color") en ambas versiones | [V56+V57+DOC] |
| `decoration { rounding = 12 dim_around = 0.15 fullscreen_opacity = 1.0 dim_inactive = true dim_strength = 0.05 }` | `hl.config({ decoration = { rounding = 12, dim_around = 0.15, fullscreen_opacity = 1.0, dim_inactive = true, dim_strength = 0.05 } })` | [V56+V57] |
| `shadow { offset = 0 2  color = $shadow_color  color_inactive = ... }` | `shadow = { enabled = true, range = 20, render_power = 3, offset = "0 2", color = "rgba(e8002a44)", color_inactive = "rgba(00000099)" }` (vec2 como string `"0 2"` valido; un string mal formado da error) | [V56+V57] |
| `blur { enabled = true size = 8 passes = 3 ignore_opacity = false new_optimizations = true xray = true contrast = 1.1 brightness = 1.0 vibrancy = 0.2 vibrancy_darkness = 0.3 }` | mismas claves dentro de `decoration = { blur = { ... } }` | [V56+V57] |
| `input { kb_layout = us,latam  kb_variant =  kb_options = grp:alt_shift_toggle  follow_mouse = 1  sensitivity = 0  accel_profile = flat  force_no_accel = 1 }` | `hl.config({ input = { kb_layout = "us,latam", kb_variant = "", kb_options = "grp:alt_shift_toggle", follow_mouse = 1, sensitivity = 0, accel_profile = "flat", force_no_accel = true, touchpad = { natural_scroll = true } } })` | [V56+V57] |
| `cursor { no_hardware_cursors = true }` | `hl.config({ cursor = { no_hardware_cursors = true } })` | [V56+V57] |
| `device { name = epic-mouse-v1  sensitivity = -0.5 }` | `hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })` | [V56+V57+DOC] |
| `bezier = space, 0.05, 0.9, 0.1, 1.02` | `hl.curve("space", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.02} } })` (puntos negativos/ >1 validos: `cosmic` -0.55/1.55) | [V56+V57+DOC] |
| `animations { enabled = true }` | `hl.config({ animations = { enabled = true } })` | [V56+V57] |
| `animation = windowsIn, 1, 6, spaceIn, popin 90%` | `hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "spaceIn", style = "popin 90%" })` | [V56+V57+DOC] |
| `animation = fadeIn, 1, 6, fade` | `hl.animation({ leaf = "fadeIn", enabled = true, speed = 6, bezier = "fade" })` | [V56+V57] |
| `animation = borderangle, 1, 100, linear, loop` | `hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })` | [V56+V57] |
| `animation = specialWorkspace, 1, 6, cosmic, slidevert` | `hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "cosmic", style = "slidevert" })` | [V56+V57] |
| `workspace = 1, monitor:eDP-1` | `hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })` (workspace como string) | [V56+V57+DOC] |
| `windowrule = tag +multimedia_video, match:class ^([Mm]pv\|vlc)$` | `hl.window_rule({ match = { class = "^([Mm]pv\|vlc)$" }, tag = "+multimedia_video" })` | [V56+V57+DOC] |
| `windowrule = no_blur on, match:tag multimedia_video*` | `hl.window_rule({ match = { tag = "multimedia_video*" }, no_blur = true })` (`on/off` pasan a `true/false`; un string `"on"` da error de tipo) | [V56+V57+DOC] |
| `windowrule = opacity 0.85 override 0.7 override 1 override, match:class ^(discord\|vesktop)$` | `opacity = "0.85 override 0.7 override 1 override"` (string) | [V56+V57+DOC] |
| `windowrule = float on, size 520 300, move 20 760, pin on, decorate off, animation slide` (misma `match:title`) | UNA sola regla: `hl.window_rule({ match = { title = "^(Asistente de Voz)$" }, float = true, size = "520 300", move = "20 760", pin = true, decorate = false, animation = "slide", opacity = "0.95 override" })` | [V56+V57+DOC] |
| `windowrule = center on, ...` / `center 1` | `center = true` (aceptar `1` no da error pero usar bool) | [V56+V57] |
| `windowrule = no_anim on, ...` | `no_anim = true` | [V56+V57] |
| `windowrule = size 50% 60%` | PORCENTAJES: el parser acepta `"50% 60%"` pero la wiki solo documenta numeros y expresiones (`monitor_w`, `monitor_h`, `window_w`, `window_h`, `cursor_x`, `cursor_y`, `window_x`, `window_y`). Usar `size = "monitor_w*0.5 monitor_h*0.6"` (sin espacios dentro de cada expresion) | sintaxis [V56+V57]; semantica de `%` [NO VERIFICADO]; expresiones [DOC] |
| `windowrule = move 100%-360 50` | `move = "monitor_w-360 50"` (equivalente por [DOC]). `"100%-360 50"` pasa verify pero NO esta documentado | [NO VERIFICADO] la forma `%`; expresion [DOC] |
| `windowrule = workspace special:scratchpad silent, ...` | `workspace = "special:scratchpad silent"` | [V56+V57+DOC] |
| `windowrule = match:class .*, suppress_event maximize` | `hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })` | [V56+V57+DOC] |
| `windowrule = match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus on` | `hl.window_rule({ match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, no_focus = true })` (identico al ejemplo oficial) | [V56+V57+DOC] |
| `windowrule = float on, match:initial_title (Open Files)` | `hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true })` | [V56+V57+DOC] |
| `layerrule = blur on, match:namespace omenu` + `ignore_alpha 0.15` + `animation popin` | `hl.layer_rule({ match = { namespace = "omenu" }, blur = true, ignore_alpha = 0.15, animation = "popin" })` | [V56+V57+DOC] |
| `layerrule = dim_around on, ...` / `xray 0` | `dim_around = true` / `xray = false` (`xray = 0` pasa verify pero usar bool) | [V56+V57] |
| `bind = $mainMod, Return, exec, $terminal` | `hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))` | [V56+V57+DOC] |
| `bind = $mainMod SHIFT, RETURN, exec, [float; size 800 550] $terminal` | `hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd(terminal, { float = true, size = { 800, 550 } }))` (reglas de ventana como 2do arg de exec_cmd; sigue el PID del proceso: si el programa hace fork y la ventana la abre el hijo, NO aplica) | [V56+V57] sintaxis; [DOC] semantica |
| `bind = , Print, exec, grim -g "$(slurp)" - \| wl-copy` | `hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - \| wl-copy'))` (tecla sin modificadores = solo el nombre) | [V56+V57] |
| `bind = CTRL ALT, Delete, exec, hyprctl dispatch exit 0` | `hl.bind("CTRL + ALT + Delete", hl.dsp.exit())` (NO usar el `hyprctl dispatch exit` viejo; ver seccion 5) | [V56+V57+DOC] |
| `bind = $mainMod, Q, killactive,` | `hl.bind(mainMod .. " + Q", hl.dsp.window.close())` | [V56+V57+DOC] |
| `bind = $mainMod, Space, togglefloating,` | `hl.bind(mainMod .. " + Space", hl.dsp.window.float({ action = "toggle" }))` | [V56+V57+DOC] |
| `bind = $mainMod, P, pseudo,` | `hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())` | [V56+V57+DOC] |
| `bind = $mainMod, J, layoutmsg, togglesplit` | `hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))` | [V56+V57+DOC] |
| `bind = $mainMod, F, fullscreen` | `hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())` (por defecto modo "fullscreen"; `{ mode = "maximized" }` para maximizar) | [V56+V57+DOC] |
| `bind = $mainMod, left, movefocus, l` | `hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))` (`left/right/up/down`; la wiki tambien acepta l/r/u/d) | [V56+V57+DOC] |
| `bind = $mainMod CTRL, left, movewindow, l` | `hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))` | [V56+V57+DOC] |
| `binde = $mainMod SHIFT, left, resizeactive,-50 0` | `hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })` | [V56+V57+DOC] |
| `bind = $mainMod, 1, workspace, 1` | `hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))` (bucle for i=1,10 con `key = i % 10`, como el ejemplo oficial) | [V56+V57+DOC] |
| `bind = $mainMod SHIFT, 1, movetoworkspace, 1` | `hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))` (`follow` por defecto true segun wiki, igual que el `movetoworkspace` legacy que sigue a la ventana; `follow = false` equivale a `movetoworkspacesilent`) | [V56+V57] sintaxis; default follow [DOC] |
| `bind = $mainMod, mouse_down, workspace, e+1` | `hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))` | [V56+V57+DOC] |
| `bindm = $mainMod, mouse:272, movewindow` | `hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })` | [V56+V57+DOC] |
| `bindm = $mainMod, mouse:273, resizewindow` | `hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })` | [V56+V57+DOC] |
| `bindel = , XF86AudioRaiseVolume, exec, ...volume.sh --inc` | `hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --inc"), { locked = true, repeating = true })` (e = repeating, l = locked) | [V56+V57+DOC] |
| `bindl = , XF86AudioNext, exec, playerctl next` | `hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })` | [V56+V57+DOC] |
| `bind = $mainMod SHIFT, H, movewindow, mon:l` | `hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ monitor = "l" }))` | [V56+V57] sintaxis; semantica monitor-direccion [DOC] (selector Direction) |
| `bind = $mainMod CTRL SHIFT, right, movecurrentworkspacetomonitor, r` | `hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))` | [V56+V57+DOC] |
| `bind = $mainMod ALT, left, focusmonitor, l` | `hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ monitor = "l" }))` | [V56+V57+DOC] |
| `bind = $mainMod CTRL, 1, movetoworkspace, 1` + la linea siguiente `workspace, 1` | una sola: `hl.bind(mainMod .. " + CTRL + 1", hl.dsp.window.move({ workspace = 1, follow = true }))` (o una funcion con dos `hl.dispatch(...)`) | [V56+V57] |
| flags: bind=sin flag, binde=`{repeating=true}`, bindl=`{locked=true}`, bindel=ambos, bindr=`{release=true}`, bindm=`{mouse=true}`, bindn=`{non_consuming=true}`, bindt=`{transparent=true}` | ver arriba. `repeat` es palabra reservada de Lua: el nombre del flag es `repeating` | [V56+V57+DOC] |
| submap (no lo usa hoy) `submap = resize ... submap = reset` | `hl.bind("ALT + R", hl.dsp.submap("resize")); hl.define_submap("resize", function() ... hl.bind("escape", hl.dsp.submap("reset")) end)` | [V56+V57+DOC] |
| `hyprctl dispatch exit` desde exec (en bind exec) | `hl.dsp.exit()` | [V56+V57+DOC] |

Mods: se unen con ` + ` (`"SUPER + CTRL + SHIFT + right"`). `"SUPER SHIFT + W"` y `"SUPER, E"` dan error ("did you forget a +?") en ambas versiones [V56+V57].

## 2. Dividir en varios archivos (require)

- `require("configs.keybinds")` o `require("configs/keybinds")` cargan `<dir de hyprland.lua>/configs/keybinds.lua` (probado con `-c` apuntando al archivo y cwd distinto: se resuelve relativo al directorio del archivo de config) [V56+V57]. Tambien funciona `require` con ruta absoluta sin extension [V56+V57]. En las pruebas el error de require fallido lista `./?.lua`, `./?/init.lua` y las rutas del sistema.
- Release notes: 0.56 "allow wildcards or absolute paths in require" (#15461); 0.57 "do not nuke package.path" (#15622). Los comodines `require("sub.*")`, `"sub/*"` NO funcionaron en mis pruebas con verify-config [NO VERIFICADO fuera de esa forma]. Usar requires explicitos.
- `require` cachea por estado Lua; al recargar la config el estado Lua se destruye y se recrea (evento `config.unload` en 0.57, wiki: "Lua state torn down"), por lo que un `colors.lua` reescrito se relee en `hyprctl reload` [DOC].
- Un error de Lua en un modulo aborta el resto del script (lo que ya se ejecuto queda aplicado). Si no se registra ningun bind hay "emergency mode" (solo SUPER+Q) [strings del binario]. Para modulos opcionales (p. ej. colores generados): `local ok, colors = pcall(require, "colors")` con valores por defecto. pcall es Lua estandar [NO VERIFICADO bajo Hyprland].
- Orden: igual que los `source` actuales: colors, monitors, base/env/autostart, tags ANTES de windowrules (el tag solo se aplica a ventanas nuevas; las reglas se evaluan arriba a abajo y la ultima coincidencia gana, todas las nombradas antes que las anonimas) [DOC].
- Si `~/.config/hypr/hyprland.lua` existe se carga en lugar de hyprland.conf; la comprobacion es al arrancar (news 26_lua) [DOC]. El archivo `hyprland.lua.autogen-0.57` NO se carga (nombre distinto). No incluir `hl.config({ autogenerated = true })` del ejemplo; solo sirve para suprimir el aviso.

Estructura recomendada (la usada en el arbol validado): `hyprland.lua` -> `require("configs.monitors")`, `looknfeel` (que hace `require("colors")`), `input`, `animations`, `tags`, `windowrules`, `keybinds`, `base` (env + autostart + misc/render/master).

## 3. Diferencias de API 0.56.2 vs 0.57.1 que importan

Comparado con diff de `hl.meta.lua`, diff del `hyprland.lua` de ejemplo, strings de ambos binarios y release notes v0.55/v0.56/v0.57:

1. `hl.curve(... type="spring" ...)`: 0.56.2 exige `dampening`, 0.57 usa `damping` (release 0.57: "fix misspelling of damping as dampening", #15993). En mis pruebas 0.56.2 RECHAZA `damping` ("dampening expects a number") y 0.57.1 acepto ambos nombres sin error. El usuario NO usa springs (solo bezier), asi que no le afecta. Si se agregan, compatibilidad: `local spring_key = hl.version():find("0%.56") and "dampening" or "damping"` [V56+V57 para la divergencia; el snippet no probado].
2. Nueva categoria `layers` (0.57): `layers.allow_new_top_layers_over_existing_fullscreen` y `layers.layers_hog_keyboard_focus`. En 0.56.2 ese bloque no existe (el ejemplo 0.57 lo trae). No afecta al usuario salvo que lo copie del ejemplo: en 0.56.2 daria "unknown config key" [DOC por stubs]. No incluirlo.
3. Nuevas opciones 0.57 (no existen en 0.56.2, no usar si se quiere compatibilidad): `cursor.warp_on_monitor_change`, `decoration.wobble.*`, `decoration.blur.{variant,proportional,glass,acrylic,aurora,...}`, `input.swallow_focus_click`, `input.tablet.enabled`, `misc.bell_sound`, `misc.float_force_onscreen`, `render.async_commit`, `binds.drag_center_window`, `debug.invalidate_buffers`. Removida en 0.57: `debug.fifo_pending_workaround`. Todas las opciones que usa el usuario existen en ambas (validado) [V56+V57].
4. Nuevo en 0.57: `hl.dsp.reload_config()` (dispatcher; la nota de prensa lo llama `hl.reload_config()`; el stub y el binario muestran `reload_config` bajo `hl.dsp`), `hl.get_devices()`, `hl.get_monitors({ all = true })`, eventos `config.unload`, `window.minimize`, `window.update_state`, `window.bell`, `workspace.created_early`; reglas `no_glow`, `no_wobble`, `no_xdg_drags`, `active_border`/`inactive_border` (efectos de window_rule). `hyprctl deprecated-config` y avisos de opciones deprecadas ("You are using N deprecated config options") [DOC/strings]. Si se quiere que corra en 0.56.2 NO usar estas funciones (o protegerlas con `hl.version()`).
5. 0.57 endurece validaciones: rechaza fabricas de dispatcher en bind/dispatch (p. ej. `hl.dsp.window.close` sin parentesis), argumentos sobrantes a dispatchers, claves duplicadas en un string de bind, y nombres de workspace que sean IDs numericos ("reject workspaces named as IDs") [release notes]. Mensajes de error de bind distintos pero ambas rechazan lo mismo en mis pruebas. Con las formas de este documento no hay efecto.
6. Campos de objetos (solo si se usa scripting): `HL.LayerSurface.interactivity` pasa a `keyboard_interactivity`, `Window.stable_id` de integer a string, `Workspace.config_name` pasa a `addressable_name`, `HL.Keybind.key` tipo any [stubs]. No aplica a la config actual.
7. `hl.permission` acepta forma posicional `("regex","tipo","allow")` y de tabla `{binary=,type=,mode=}` en ambas [V56+V57]. No usado.
8. Eliminacion de `.conf`: 0.57 ya no carga hyprland.conf ("config: remove legacy config support"). Si no hay hyprland.lua, 0.57 arranca con el ejemplo por defecto (strings: "use the default lua config") [DOC/strings].
9. Wiki: en la pagina de animations la sintaxis dice `curve = ` pero tanto 0.56.2 como 0.57.1 requieren `bezier =` o `spring =` (con `curve =` falla: "bezier or spring is required") [V56+V57]. En la pagina de binds el ejemplo de unbind usa `hl.focus.workspace` (typo); lo correcto es `hl.dsp.focus({ workspace = ... })`.
10. Los dos hyprctl (0.56.2 y 0.57.1) listan los mismos comandos incl. `eval`, `repl`, `keyword`.

## 4. hyprctl keyword / reload / eval en modo Lua

- `hyprctl reload`: sigue funcionando; en Lua recarga hyprland.lua (wiki using-hyprctl: "Issue a reload to force reload the config"). `hyprctl reload config-only` salta recarga de monitores. `hyprctl reload full-reset` recrea el contexto entero y permite cambiar entre Lua y hyprlang sin reiniciar (wiki; contradice parcialmente la nota 26_lua que dice "requires restart") [DOC]. Usado hoy por apply-theme.sh, wbrestart.sh, matugen (post_hook). [DOC; NO ejecutado en vivo porque la sesion actual corre .conf]
- `hyprctl keyword <opcion> <valor>`:
  - 0.56.2 (strings del binario instalado): en modo Lua responde `keyword can't work with non-legacy parsers. Use eval.` Es decir, FALLA en 0.56.2 con Lua.
  - 0.57.1: el binario del daemon ya no contiene el manejador ni ese mensaje (el cliente `hyprctl --help` aun lista `keyword`, pero la wiki oficial ya no lo documenta). Tratar como NO funcional [inferido de strings, NO ejecutado en vivo].
  - Por tanto TODO uso de `hyprctl keyword` debe migrarse a `hyprctl eval`.
- `hyprctl eval '<codigo Lua>'`: existe en ambas versiones (help de ambos hyprctl; wiki "Issue a Lua string to execute dynamically, returns ok or any error raised"). En un daemon .conf responde "eval is only supported with the lua config manager" [strings]. Equivalentes (la sintaxis de `hl.config` ya validada con verify-config):
  - `hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {"rgb(e8002a)","rgb(8b0000)"}, angle = 45 }, inactive_border = "rgb(080204)" } } })'` -> cambia bordes en runtime. Forma con clave punteada tambien valida: `hl.config({ ["general.col.active_border"] = {colors={...}, angle=45} })` [V56+V57]. Un string de gradiente `"rgb() rgb() 45deg"` NO es valido (usar tabla).
  - `hyprctl eval 'hl.config({ decoration = { shadow = { color = "rgba(e8002a44)", color_inactive = "rgba(00000099)" }, rounding = 12 } })'` [V56+V57 sintaxis; ejecucion en vivo NO VERIFICADO].
  - Monitor headless (apply-theme.sh, meeting-mode.sh, wbrestart.sh: `hyprctl keyword monitor "$OUT,1920x1080@60,auto,1"`): `hyprctl eval 'hl.monitor({ output = "HEADLESS-2", mode = "1920x1080@60", position = "auto", scale = 1 })'` [V56+V57 sintaxis; ejecucion en vivo NO VERIFICADO]. Crear la salida sigue siendo `hyprctl output create headless` (wiki).
  - `hyprctl getoption general.border_size` (formato `seccion.opcion` con puntos, no `:`) [DOC].
- `hyprctl dispatch` en modo Lua es atajo de `eval 'return hl.dispatch(<arg>)'` (wiki + strings `return hl.dispatch({})` y la nota "dispatch in lua is a shorthand for hl.dispatch(...), your syntax might need to be updated"). Los dispatchers legacy (`hyprctl dispatch workspace e+1`, `dispatch exit`, `dispatch dpms off`, `dispatch togglespecialworkspace scratchpad`, `dispatch focuswindow class:..`, `dispatch moveworkspacetomonitor 8 eDP-1`) dejaran de funcionar; hay que escribirlos como expresion Lua [DOC + strings]. Equivalentes (construccion validada, ejecucion NO VERIFICADA):
  - `hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'`
  - `hyprctl dispatch 'hl.dsp.exit()'`
  - `hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'` / `"on"`
  - `hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'` (sin prefijo `special:`)
  - `hyprctl dispatch 'hl.dsp.focus({ window = "class:^(code|Code)$" })'`
  - `hyprctl dispatch 'hl.dsp.workspace.move({ workspace = 8, monitor = "eDP-1" })'`
  - Salir de un submap atascado: `hyprctl dispatch 'hl.dsp.submap("reset")'`.
- `hyprctl --batch "cmd1 ; cmd2"` sigue (punto y coma dentro de codigo Lua debe escaparse con backslash) [DOC].

## 5. Construcciones del usuario sin equivalente claro o riesgosas

1. **Archivos generados que hoy son hyprlang**: `colors.conf` lo escriben `scripts/apply-theme.sh` (heredoc, lineas ~37-43) y la plantilla matugen `~/.config/matugen/templates/hyprland-colors.conf` -> `output_path ~/.config/hypr/colors.conf`. Hay que cambiarlos para emitir `colors.lua` (`return { active_border = {colors={...}, angle=45}, inactive_border=..., shadow=..., shadow_inactive=..., rounding=... }`). El gradiente de `HYPR_BORDER_ACTIVE` (string "rgb(..) rgb(..) 45deg") debe parsearse a tabla {colors, angle}; si es un solo color, pasar el string tal cual. Tambien `rounding` solo se aplica hoy con `hyprctl keyword` (no persiste en reload): conviene ponerlo en colors.lua. Ademas `~/AntigravityWorkspace/my-hyprland-rice` (sync/apply/install) y `theme-creator` generan/copian .conf.
2. **Todos los `hyprctl keyword`** (apply-theme.sh l.317-323, meeting-mode.sh l.16, wbrestart.sh l.14) -> `hyprctl eval` (seccion 4). Fallan con error visible en 0.56.2 y no existen en 0.57.
3. **Todos los `hyprctl dispatch <legacy>`** en scripts: `project-launcher.sh` (focuswindow), `meeting-mode.sh` (moveworkspacetomonitor), `scratchpad.sh` (togglespecialworkspace), waybar `ModulesWorkspaces` (`workspace e+1/e-1`, 8+ ocurrencias), `ModulesCustom` (`hyprctl dispatch exit`), `hypridle.conf` (`dpms on/off`), `voice-assistant.py` (le dice a Claude `hyprctl dispatch exec <app>`). Terceros que usan el socket IPC con `dispatch` legacy (waybar `hyprland/workspaces` al hacer clic, AGS/Astal, rofi/wlogout) podrian romperse: [NO VERIFICADO] como se comportan con el socket en modo Lua; revisar tras migrar.
4. **Prefijo `[float; size 800 550]` en exec**: ahora es `hl.dsp.exec_cmd(cmd, { float = true, size = {800,550} })`; las claves de la tabla son efectos de window_rule (move, size, float, center, workspace, etc.). Se asocia por PID; con `kitty --title ... cava` funciona porque kitty no hace fork de ventana, pero es distinto al comportamiento legacy [DOC]. Alternativa robusta: `hl.window_rule` por `title`.
5. **Porcentajes en size/move** (`50% 60%`, `70% 60%`, `80% 45%`, `100%-360`): reemplazar por expresiones `monitor_w*0.5 monitor_h*0.6` y `monitor_w-360`. El parser no valida el contenido de la expresion (acepta `"foo bar"`), asi que un error de tipeo no se detecta con verify-config [V56+V57].
6. **Banderas de bind con nombre erroneo no dan error**: `{ bogusflag = true }` paso verify en ambas; un typo (`repeat`/`repeating`, `lock`/`locked`) falla en silencio o es error de sintaxis Lua si es palabra reservada (`repeat`). Revisar cada bind con `hyprctl binds` tras migrar.
7. **Binds duplicados que se ejecutan ambos** (hyprlang y Lua ejecutan todos los binds de la misma tecla en orden): SUPER+P (pseudo l.17 y project-launcher l.101), SUPER+SHIFT+M (`kitty yt` l.31 y meeting-mode l.212), SUPER+CTRL+1..5 definidos dos veces (movetoworkspace + workspace x2, el segundo par es redundante), y las repeticiones de multimonitor (SUPER+SHIFT+H/L, CTRL+SHIFT+left/right, ALT+left/right, lineas 149-158 y 168-173). Decidir si se conserva el doble disparo (SUPER+P y SUPER+SHIFT+M hoy hacen DOS cosas) o se deduplica; en el arbol validado se deduplicaron las del multimonitor y las CTRL+N. Ademas SUPER+V esta como `exec ags toggle clipboard` y SUPER+SHIFT+V/B/T son widgets distintos (no chocan).
8. **`match:namespace tag:notif*`** (windowrules.conf, `layerrule = ignore_alpha 0.5`): es una regex literal "tag:notif*" que casi seguro no coincide con nada (no hay tags de capa). Traduccion literal `match = { namespace = "tag:notif*" }` o descartarla. Tambien hay pares contradictorios para swaync (`ignore_alpha 0` y luego `0.5`; gana el ultimo): colapsar en una regla con `ignore_alpha = 0.5`.
9. **Reglas con `windowrule = size 50% 60%` etc. en reglas separadas**: en Lua se agrupan todas las con el mismo `match` en una sola `hl.window_rule`. Cuidado con el orden: para el mismo efecto gana la ultima coincidencia (p. ej. Cat Theme Toggle tiene `animation slide` y Theme Toggle `no_anim`).
10. **`bind = ..., exec, hyprctl dispatch exit 0`** y el boton de poweroff de waybar usan `exit`: usar `hl.dsp.exit()` (o hyprshutdown). 
11. **Variables de entorno**: `AQ_DRM_DEVICES` (comentada) conserva el gotcha de ":" con rutas by-path; no cambia con Lua. `hl.env` solo antes de iniciar el servidor de pantalla: no se puede cambiar en reload [DOC].
12. **No-bloqueo**: las funciones Lua de bind corren en el event loop del compositor; no usar `io.popen`, sleeps ni `wl-paste` dentro de callbacks (la wiki avisa que cuelga todo el escritorio). Usar `hl.dsp.exec_cmd`. Los binds actuales son todos `exec`, sin problema.
13. **Cambio en caliente de modo**: arrancar 0.56.2 con hyprland.lua presente cambia a Lua en el siguiente inicio de sesion; `hyprctl reload` desde .conf NO cambia de modo (solo `reload full-reset` segun wiki) [DOC]. Antes de borrar/renombrar hyprland.conf mantener respaldo (incidente 2026-11-03 de la memoria del usuario: sin .conf ni .lua, 0.57 arranca con el ejemplo).
14. **Pre-vuelo recomendado**: `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` (0.56.2). Para 0.57: comando equivalente con el binario extraido y `LD_LIBRARY_PATH` a las libs de pacman cache (como en v.sh). Ya hay en el scratchpad una traduccion completa validada en ambas versiones; falta (a) los autostart/binds restantes sin transformar a mano linea por linea y (b) adaptar scripts.

## 6. URLs fuente

- https://wiki.hypr.land/configuring/ ; /configuring/core/binds/ ; /configuring/core/binds/flags/ ; /configuring/core/binds/submaps/ ; /configuring/core/binds/gestures/
- https://wiki.hypr.land/configuring/core/dispatchers/
- https://wiki.hypr.land/configuring/core/rules/ ; /rules/window-rules/ ; /rules/layer-rules/ ; /rules/workspace-rules/
- https://wiki.hypr.land/configuring/core/monitors/ ; /core/devices/ ; /core/animations/ ; /core/autostart/ ; /core/environment-variables/ ; /core/config-options/
- https://wiki.hypr.land/configuring/core/advanced-configuration/using-hyprctl/ ; /lua-utilities/ ; /events/ ; /permissions/
- https://wiki.hypr.land/configuring/naming-conventions/ ; /configuring/selectors/ ; /configuring/code-snippets/
- https://hypr.land/news/26_lua/ ; https://hypr.land/news/update57/
- https://github.com/hyprwm/Hyprland/releases/tag/v0.55.0 ; .../v0.56.0 ; .../v0.57.0 (via api.github.com/repos/hyprwm/Hyprland/releases/tags/vX; copias locales en .../scratchpad/wiki/rel_*.md)
- Locales: `/usr/share/hypr/hyprland.lua` y `/usr/share/hypr/stubs/hl.meta.lua` (0.56.2); `~/.config/hypr/hyprland.lua.autogen-0.57`; stubs/ejemplo 0.57.1 extraidos de `/var/cache/pacman/pkg/hyprland-0.57.1-1-x86_64.pkg.tar.zst` en `.../scratchpad/h057full/`.
