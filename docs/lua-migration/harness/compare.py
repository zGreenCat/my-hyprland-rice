import json, re, sys
H = '/home/zgreencat/.config/hypr/'
calls = [l.rstrip('\n').split('\t') for l in open(sys.argv[1])]

def strip(l): return re.sub(r'\s+#.*$', '', l).strip()

# ---------- reglas (window + layer), efecto por efecto, en orden ----------
BOOL = {'on': True, 'off': False}
def norm_val(eff, v):
    if v in BOOL: return BOOL[v]
    if eff == 'center' and v == '1': return True
    if eff == 'xray' and v == '0': return False
    if eff == 'ignore_alpha': return float(v)
    m = re.fullmatch(r'(\d+)% (\d+)%', v)
    if m: return f"monitor_w*{int(m[1])/100:g} monitor_h*{int(m[2])/100:g}"
    m = re.fullmatch(r'100%-(\d+) (\d+)', v)
    if m: return f"monitor_w-{m[1]} {m[2]}"
    return v
def mval(k, v):
    return {'true': True, 'false': False}.get(v, v)

conf_rules = []
for f in ['configs/tags.conf', 'configs/windowrules.conf']:
    for l in open(H + f):
        l = strip(l)
        m = re.match(r'(windowrule|layerrule)\s*=\s*(.*)', l)
        if not m: continue
        kind = 'window_rule' if m[1] == 'windowrule' else 'layer_rule'
        parts = [p.strip() for p in m[2].split(', ')]
        match, effects = {}, []
        for p in parts:
            if p.startswith('match:'):
                k, v = p[6:].split(' ', 1); match[k] = mval(k, v)
            else:
                k, v = (p.split(' ', 1) + [''])[:2]; effects.append((k, norm_val(k, v.strip())))
        for k, v in effects: conf_rules.append((kind, json.dumps(match, sort_keys=True), k, v))

lua_rules = []
for c in calls:
    if c[0] in ('window_rule', 'layer_rule'):
        t = json.loads(c[1]); match = t.pop('match')
        for k in sorted(t, key=lambda x: 0):  # preserva orden de inserción no disponible: ordenar abajo
            pass
        lua_rules.append((c[0], json.dumps(match, sort_keys=True), t))

# expandir lua en el orden de efectos del conf para cada grupo consecutivo
expanded = []
i = 0
for kind, match, t in lua_rules:
    n = len(t)
    group = conf_rules[i:i + n]
    keys_conf = [g[2] for g in group]
    if sorted(keys_conf) == sorted(t) and all(g[0] == kind and g[1] == match for g in group):
        expanded += [(kind, match, k, t[k]) for k in keys_conf]
    else:
        expanded += [(kind, match, k, t[k]) for k in sorted(t)]
    i += n

bad = 0
for a, b in zip(conf_rules, expanded):
    va, vb = a[3], b[3]
    if isinstance(va, float) or isinstance(vb, float): eq = float(va) == float(vb)
    else: eq = a == b
    if not eq: bad += 1; print('REGLA ≠', a, '|', b)
print(f'reglas: conf={len(conf_rules)} lua={len(expanded)} diferencias={bad + abs(len(conf_rules)-len(expanded))}')

# ---------- binds ----------
LEGACY = {
 'exec': lambda a, r: ('dsp.exec_cmd', a),
 'killactive': lambda a, r: ('dsp.window.close', None),
 'togglefloating': lambda a, r: ('dsp.window.float', {'action': 'toggle'}),
 'pseudo': lambda a, r: ('dsp.window.pseudo', None),
 'layoutmsg': lambda a, r: ('dsp.layout', a),
 'fullscreen': lambda a, r: ('dsp.window.fullscreen', None),
 'movefocus': lambda a, r: ('dsp.focus', {'direction': {'l':'left','r':'right','u':'up','d':'down'}[a]}),
 'movewindow': lambda a, r: ('dsp.window.drag', None) if r == 'm' else (('dsp.window.move', {'monitor': a[4:]}) if a.startswith('mon:') else ('dsp.window.move', {'direction': {'l':'left','r':'right','u':'up','d':'down'}[a]})),
 'resizewindow': lambda a, r: ('dsp.window.resize', None),
 'resizeactive': lambda a, r: ('dsp.window.resize', dict(zip(['x','y'], map(int, a.split())), relative=True)),
 'workspace': lambda a, r: ('dsp.focus', {'workspace': int(a) if a.isdigit() else a}),
 'movetoworkspace': lambda a, r: ('dsp.window.move', {'workspace': int(a), 'follow': True}),
 'movecurrentworkspacetomonitor': lambda a, r: ('dsp.workspace.move', {'monitor': a}),
 'focusmonitor': lambda a, r: ('dsp.focus', {'monitor': a}),
}
VARS = {'$mainMod': 'SUPER', '$terminal': 'kitty', '$fileManager': 'nautilus', '$menu': 'rofi -show drun'}
FLAGS = {'': {}, 'e': {'repeating': True}, 'l': {'locked': True}, 'el': {'locked': True, 'repeating': True}, 'm': {'mouse': True}}
conf_binds = []
for l in open(H + 'configs/keybinds.conf'):
    l = strip(l)
    m = re.match(r'bind([a-z]*)\s*=\s*(.*)', l)
    if not m: continue
    fl, rest = m[1], m[2]
    for k, v in VARS.items(): rest = rest.replace(k, v)
    mods, key, disp, *arg = [x.strip() for x in rest.split(',', 3)]
    arg = arg[0] if arg else ''
    keys = ' + '.join(mods.split() + [key])
    if disp == 'exec' and arg == 'hyprctl dispatch exit 0': act = ('dsp.exit', None); rules = None
    else:
        rules = None
        mm = re.match(r'\[float; size (\d+) (\d+)\]\s*(.*)', arg)
        if disp == 'exec' and mm: rules = {'float': True, 'size': [int(mm[1]), int(mm[2])]}; arg = mm[3]
        if disp == 'exec': arg = arg.replace('~/.config/hypr/scripts/', '~/.config/hypr/scripts/')
        act = LEGACY[disp](arg, fl)
    conf_binds.append((keys.lower(), act[0], json.dumps(act[1], sort_keys=True), json.dumps(rules, sort_keys=True), json.dumps(FLAGS[fl], sort_keys=True)))

lua_binds = []
for c in calls:
    if c[0] != 'bind': continue
    keys = json.loads(c[1]); action = json.loads(c[2])
    flags = json.loads(c[3]) if len(c) > 3 and c[3] != 'null' else {}
    flags.pop('description', None)
    args = action.get('args', [])
    a1 = args[0] if len(args) > 0 else None
    a2 = args[1] if len(args) > 1 else None
    lua_binds.append((keys.lower(), action['dsp'], json.dumps(a1, sort_keys=True), json.dumps(a2, sort_keys=True), json.dumps(flags, sort_keys=True)))

bad = 0
for a, b in zip(conf_binds, lua_binds):
    if a != b: bad += 1; print('BIND ≠ conf', a); print('       lua ', b)
print(f'binds: conf={len(conf_binds)} lua={len(lua_binds)} diferencias={bad + abs(len(conf_binds)-len(lua_binds))}')

# ---------- orden por tecla (duplicados) ----------
from collections import defaultdict
def bykey(lst):
    d = defaultdict(list)
    for b in lst: d[b[0]].append(b[1:])
    return d
dc, dl = bykey(conf_binds), bykey(lua_binds)
print('orden por tecla idéntico:', dc == dl, '| teclas con >1 bind:', sum(1 for v in dc.values() if len(v) > 1))

# ---------- vista de atajos en modo Lua (simula hyprctl binds -j) ----------
import importlib.util, subprocess
MOD_BITS = {'SHIFT': 1, 'CTRL': 4, 'ALT': 8, 'SUPER': 64}
fake = []
for c in calls:
    if c[0] != 'bind': continue
    parts = json.loads(c[1]).split(' + ')
    flags = json.loads(c[3]) if len(c) > 3 and c[3] != 'null' else {}
    fake.append({'key': parts[-1], 'modmask': sum(MOD_BITS[m] for m in parts[:-1]),
                 'description': flags.get('description', ''), 'has_description': 'description' in flags})
spec = importlib.util.spec_from_file_location('kv', '/home/zgreencat/.config/hypr/scripts/keybindings-view.py')
src = open(spec.origin).read().split("results = lua_results(")[0]
ns = {}; exec(compile(src, spec.origin, 'exec'), ns)
lua_view = ns['lua_results'](fake)
legacy_view = ns['legacy_results']()
print('vista atajos: legacy', len(legacy_view), '| lua simulada', len(lua_view), '| idénticas:', lua_view == legacy_view)
for a, b in zip(legacy_view, lua_view):
    if a != b: print('  VISTA ≠', a, '|', b)
